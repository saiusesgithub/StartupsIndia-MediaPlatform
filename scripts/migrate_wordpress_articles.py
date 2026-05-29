#!/usr/bin/env python3
"""Migrate WordPress posts into the existing Firestore articles collection.

Phase 1 migration only:
- keeps existing WordPress image URLs
- converts WordPress HTML content to Markdown for the Flutter app
- writes into the existing NewsArticleModel-compatible article shape

Dry-run mode does not require Firebase credentials.
Write mode requires either --service-account or GOOGLE_APPLICATION_CREDENTIALS.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import sys
from dataclasses import dataclass, field
from datetime import timezone
from typing import Any

import requests
from bs4 import BeautifulSoup
from dateutil import parser as date_parser
from markdownify import markdownify as html_to_markdown


WP_API_URL = "https://media.startupsindia.in/wp-json/wp/v2/posts"
ARTICLES_COLLECTION = "articles"
DEFAULT_SOURCE_NAME = "StartupsIndia"
DEFAULT_SOURCE_ID = "startupsindia"
DEFAULT_SOURCE_LOGO = "assets/startupsindia/Icon.png"
DEFAULT_CATEGORY = "startup"
INTERACTION_FIELDS = {
    "likesCount",
    "commentsCount",
    "viewCount",
    "likedBy",
    "bookmarkedBy",
}


@dataclass
class MigrationStats:
    pages_read: int = 0
    posts_fetched: int = 0
    posts_transformed: int = 0
    posts_written: int = 0
    failed_post_ids: list[str] = field(default_factory=list)
    category_warnings: list[str] = field(default_factory=list)
    missing_featured_image_warnings: list[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Migrate WordPress articles into Firestore.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Transform only; do not write to Firestore.")
    parser.add_argument("--limit", type=int, default=None, help="Maximum number of posts to transform/write.")
    parser.add_argument("--per-page", type=int, default=100, help="WordPress posts per page.")
    parser.add_argument("--start-page", type=int, default=1, help="WordPress page to start from.")
    parser.add_argument("--sample", action="store_true", help="Print one transformed sample article.")
    parser.add_argument(
        "--include-gallery",
        action="store_true",
        help=(
            "Store inline image URLs in imageGallery. Default is false because "
            "inline images are already preserved in the Markdown body."
        ),
    )
    parser.add_argument(
        "--service-account",
        default=None,
        help="Path to Firebase service account JSON. Defaults to GOOGLE_APPLICATION_CREDENTIALS.",
    )
    parser.add_argument(
        "--project-id",
        default=None,
        help="Optional Firebase project id override.",
    )
    parser.add_argument(
        "--no-overwrite",
        action="store_true",
        help="Skip docs that already exist. Default behavior updates same wpId doc.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=30,
        help="HTTP timeout in seconds.",
    )
    return parser.parse_args()


def decode_text(value: str | None) -> str:
    if not value:
        return ""
    decoded = html.unescape(value)
    return BeautifulSoup(decoded, "html.parser").get_text(" ", strip=True)


def parse_wp_datetime(value: str | None):
    if not value:
        return None
    dt = date_parser.parse(value)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def unique_preserve_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        cleaned = value.strip()
        if not cleaned or cleaned in seen:
            continue
        seen.add(cleaned)
        result.append(cleaned)
    return result


def preferred_image_url(img_tag) -> str:
    for attr in ("data-src", "data-lazy-src", "src"):
        value = img_tag.get(attr)
        if value:
            return str(value).strip()
    return ""


def cleanup_html_and_extract_images(rendered_html: str) -> tuple[str, list[str]]:
    soup = BeautifulSoup(html.unescape(rendered_html or ""), "html.parser")

    for tag in soup(["script", "style", "noscript"]):
        tag.decompose()

    inline_images: list[str] = []
    for img in soup.find_all("img"):
        actual_url = preferred_image_url(img)
        if not actual_url:
            continue
        img["src"] = actual_url
        inline_images.append(actual_url)

    markdown = html_to_markdown(
        str(soup),
        heading_style="ATX",
        bullets="-",
        strip=["script", "style"],
    )
    markdown = html.unescape(markdown).strip()
    markdown = re.sub(r"\n{3,}", "\n\n", markdown)

    return markdown, unique_preserve_order(inline_images)


def get_embedded_terms(post: dict[str, Any]) -> list[dict[str, Any]]:
    embedded = post.get("_embedded") or {}
    term_groups = embedded.get("wp:term") or []
    terms: list[dict[str, Any]] = []
    for group in term_groups:
        if isinstance(group, list):
            terms.extend(term for term in group if isinstance(term, dict))
    return terms


def get_wp_category_names(post: dict[str, Any]) -> list[str]:
    categories = [
        str(term.get("name", "")).strip()
        for term in get_embedded_terms(post)
        if term.get("taxonomy") == "category" and str(term.get("name", "")).strip()
    ]
    return unique_preserve_order(categories)


def normalize_for_matching(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.lower()).strip()


def infer_category_from_text(headline: str, body: str) -> str | None:
    text = normalize_for_matching(f"{headline} {body}")
    keyword_mapping: list[tuple[str, list[str]]] = [
        (
            "funding",
            [
                "funding",
                "raised",
                "investment",
                "investor",
                "seed round",
                "series a",
                "venture capital",
            ],
        ),
        (
            "women",
            ["women", "woman", "female founder", "women entrepreneur"],
        ),
        (
            "podcast",
            ["podcast", "episode", "interview", "conversation"],
        ),
        (
            "learning",
            [
                "workshop",
                "training",
                "faculty development",
                "fdp",
                "program",
                "education",
                "students",
                "university",
                "college",
                "course",
                "bootcamp",
            ],
        ),
        (
            "entrepreneur",
            ["entrepreneur", "founder", "co founder", "business owner"],
        ),
        (
            "startup",
            ["startup", "launch", "incubator", "innovation", "company"],
        ),
    ]

    for category, keywords in keyword_mapping:
        if any(re.search(rf"\b{re.escape(keyword)}\b", text) for keyword in keywords):
            return category
    return None


def normalize_category(
    category_names: list[str],
    headline: str,
    body: str,
    stats: MigrationStats,
    wp_id: str,
) -> str:
    joined = " ".join(category_names).lower()
    normalized = normalize_for_matching(joined)
    generic_categories = {
        "latest",
        "news",
        "top news",
        "trending",
        "latest news",
    }
    category_tokens = {normalize_for_matching(name) for name in category_names}

    mapping: list[tuple[str, str]] = [
        (r"\b(startup|startups|startup stories)\b", "startup"),
        (r"\b(entrepreneur|entrepreneurship|founder|founders)\b", "entrepreneur"),
        (r"\b(podcast|podcasts)\b", "podcast"),
        (r"\b(funding|investment|investments|investor|investors)\b", "funding"),
        (r"\b(women|women entrepreneurs|women in business)\b", "women"),
        (r"\b(learning|education|resources|resource|guides|guide)\b", "learning"),
    ]

    if not category_tokens or category_tokens.issubset(generic_categories):
        inferred = infer_category_from_text(headline, body)
        if inferred is not None:
            return inferred
    else:
        for pattern, value in mapping:
            if re.search(pattern, normalized):
                return value

        inferred = infer_category_from_text(headline, body)
        if inferred is not None:
            return inferred

    stats.category_warnings.append(
        f"post {wp_id}: no category match for {category_names}; using {DEFAULT_CATEGORY}"
    )
    return DEFAULT_CATEGORY


def get_featured_image_url(post: dict[str, Any]) -> str:
    embedded = post.get("_embedded") or {}
    featured = embedded.get("wp:featuredmedia") or []
    if featured and isinstance(featured[0], dict):
        source_url = featured[0].get("source_url")
        if source_url:
            return str(source_url).strip()

    yoast = post.get("yoast_head_json") or {}
    og_images = yoast.get("og_image") or []
    if og_images and isinstance(og_images[0], dict):
        url = og_images[0].get("url")
        if url:
            return str(url).strip()

    return ""


def transform_post(
    post: dict[str, Any],
    stats: MigrationStats,
    include_gallery: bool,
) -> tuple[str, dict[str, Any]]:
    wp_id = str(post.get("id", "")).strip()
    if not wp_id:
        raise ValueError("WordPress post missing id")

    title = post.get("title") or {}
    content = post.get("content") or {}
    headline = decode_text(title.get("rendered"))
    body, extracted_images = cleanup_html_and_extract_images(content.get("rendered") or "")
    image_gallery = extracted_images if include_gallery else []
    wp_categories = get_wp_category_names(post)
    category = normalize_category(wp_categories, headline, body, stats, wp_id)
    featured_image_url = get_featured_image_url(post)
    if not featured_image_url:
        stats.missing_featured_image_warnings.append(f"post {wp_id}: missing featured image")
    created_at = parse_wp_datetime(post.get("date_gmt") or post.get("date"))
    updated_at = parse_wp_datetime(post.get("modified_gmt") or post.get("modified"))
    if updated_at is None:
        updated_at = created_at

    article = {
        "wpId": int(wp_id) if wp_id.isdigit() else wp_id,
        "wpSlug": str(post.get("slug", "") or ""),
        "wpLink": str(post.get("link", "") or ""),
        "sourceUrl": str(post.get("link", "") or ""),
        "wpCategories": wp_categories,
        "authorId": "",
        "category": category,
        "headline": headline,
        "sourceName": DEFAULT_SOURCE_NAME,
        "sourceId": DEFAULT_SOURCE_ID,
        "sourceLogoAsset": DEFAULT_SOURCE_LOGO,
        "thumbnailAsset": "",
        "featuredImageUrl": featured_image_url,
        "body": body,
        "timeAgo": "",
        "createdAt": created_at,
        "updatedAt": updated_at,
        "likesCount": 0,
        "commentsCount": 0,
        "likedBy": [],
        "bookmarkedBy": [],
        "isTrending": bool(post.get("sticky", False)),
        "isSourceFollowing": False,
        "imageGallery": image_gallery,
        "viewCount": 0,
        "migratedFrom": "wordpress",
    }

    return wp_id, article


def fetch_posts_page(page: int, per_page: int, timeout: int) -> list[dict[str, Any]]:
    response = requests.get(
        WP_API_URL,
        params={"per_page": per_page, "page": page, "_embed": "1"},
        timeout=timeout,
    )

    if response.status_code == 400:
        try:
            payload = response.json()
        except ValueError:
            payload = {}
        if payload.get("code") == "rest_post_invalid_page_number":
            return []

    response.raise_for_status()
    payload = response.json()
    if not isinstance(payload, list):
        raise ValueError(f"Expected list response for page {page}, got {type(payload).__name__}")
    return payload


def init_firestore(service_account_path: str | None, project_id: str | None):
    import firebase_admin
    from firebase_admin import credentials, firestore

    credential_path = service_account_path or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not credential_path:
        raise RuntimeError(
            "Firebase credentials required for write mode. Pass --service-account "
            "or set GOOGLE_APPLICATION_CREDENTIALS."
        )

    cred = credentials.Certificate(credential_path)
    options = {"projectId": project_id} if project_id else None
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred, options)
    return firestore.client(), firestore


def write_article(db, firestore_module, doc_id: str, article: dict[str, Any], no_overwrite: bool) -> bool:
    doc_ref = db.collection(ARTICLES_COLLECTION).document(doc_id)
    existing_doc = doc_ref.get()
    exists = existing_doc.exists
    if no_overwrite and exists:
        return False

    data = dict(article)
    if exists:
        for field_name in INTERACTION_FIELDS:
            data.pop(field_name, None)
    data["migratedAt"] = firestore_module.SERVER_TIMESTAMP
    doc_ref.set(data, merge=True)
    return True


def print_sample(doc_id: str, article: dict[str, Any]) -> None:
    printable = dict(article)
    for key in ("createdAt", "updatedAt"):
        value = printable.get(key)
        if value is not None:
            printable[key] = value.isoformat()
    body = printable.get("body", "")
    if isinstance(body, str) and len(body) > 1200:
        printable["body"] = body[:1200] + "\n\n... [truncated]"
    print("\nSample transformed article:")
    print(f"Firestore doc id: {doc_id}")
    print(json.dumps(printable, indent=2, ensure_ascii=False))


def run() -> int:
    args = parse_args()
    stats = MigrationStats()
    db = None
    firestore_module = None

    if not args.dry_run:
        db, firestore_module = init_firestore(args.service_account, args.project_id)

    remaining = args.limit
    sample_printed = False
    page = args.start_page

    while True:
        if remaining is not None and remaining <= 0:
            break

        posts = fetch_posts_page(page, args.per_page, args.timeout)
        stats.pages_read += 1
        print(f"Page {page}: fetched {len(posts)} posts")

        if not posts:
            break

        stats.posts_fetched += len(posts)
        if remaining is not None:
            posts = posts[:remaining]

        for post in posts:
            wp_id = str(post.get("id", "unknown"))
            try:
                doc_id, article = transform_post(
                    post,
                    stats,
                    include_gallery=args.include_gallery,
                )
                stats.posts_transformed += 1
                if args.sample and not sample_printed:
                    print_sample(doc_id, article)
                    sample_printed = True
                if not args.dry_run:
                    assert db is not None and firestore_module is not None
                    did_write = write_article(
                        db,
                        firestore_module,
                        doc_id,
                        article,
                        no_overwrite=args.no_overwrite,
                    )
                    if did_write:
                        stats.posts_written += 1
            except Exception as exc:  # noqa: BLE001 - migration should continue.
                stats.failed_post_ids.append(wp_id)
                print(f"Failed post {wp_id}: {exc}", file=sys.stderr)

        if remaining is not None:
            remaining -= len(posts)

        page += 1

    print("\nMigration summary")
    print(f"Pages read: {stats.pages_read}")
    print(f"Posts fetched: {stats.posts_fetched}")
    print(f"Posts transformed: {stats.posts_transformed}")
    print(f"Posts written: {stats.posts_written}")
    print(f"Failed post IDs: {stats.failed_post_ids or 'none'}")
    print(f"Category mapping warnings: {len(stats.category_warnings)}")
    for warning in stats.category_warnings[:25]:
        print(f"  - {warning}")
    if len(stats.category_warnings) > 25:
        print(f"  ... {len(stats.category_warnings) - 25} more")
    print(f"Missing featured image warnings: {len(stats.missing_featured_image_warnings)}")
    for warning in stats.missing_featured_image_warnings[:25]:
        print(f"  - {warning}")
    if len(stats.missing_featured_image_warnings) > 25:
        print(f"  ... {len(stats.missing_featured_image_warnings) - 25} more")

    if args.dry_run:
        print("\nDry-run complete. No Firestore writes were made.")

    return 0 if not stats.failed_post_ids else 1


if __name__ == "__main__":
    raise SystemExit(run())
