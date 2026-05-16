# Startups India Media Platform - Product & Engineering TODO

## Project Status

The app is a Flutter + Firebase prototype for a startup-focused media platform. The strongest parts so far are the visual foundation, Firebase setup, authentication flow, onboarding, article creation, Firestore-backed article feeds, profile editing, theme switching, and FCM token plumbing.

The main gap is that several screens look complete but are still mock, local-only, or partially wired. The next phase should focus on turning the prototype into a consistent product: one article model, real persisted interactions, complete route wiring, reliable tests, and clearer startup/community features.

## Priority 0 - Fix Build, Navigation, and Data Consistency

- [ ] Fix the stale widget test in `test/widget_test.dart`.
  - Current test calls `MyApp(isFirstRun: true)`, but `MyApp` has no `isFirstRun` parameter.
  - Replace with a Firebase-safe smoke test or remove the generated counter test.

- [ ] Register missing routes in `lib/main.dart`.
  - `/search` is used by Home and Media Feed but is not registered.
  - Consider adding `/bookmark`, `/article-detail`, `/comments`, and source profile navigation patterns.

- [ ] Remove duplicate article model usage.
  - Current app has `core/models/news_article_model.dart` and `features/home/domain/models/news_article.dart`.
  - Pick `NewsArticleModel` as the source of truth and update widgets to accept it directly.
  - Remove repeated conversion code in Home, Trending, Search, and Explore.

- [ ] Run and fix `flutter analyze`.
  - Analyzer timed out during codebase review, so first run it locally with a longer timeout.
  - Expect issues around stale tests, ignored provider state writes, unnecessary null coalescing, and direct Firebase access.

- [ ] Fix text encoding/mojibake in README and comments.
  - Many comments and README lines contain corrupted characters like `â”€`, `ðŸ`, and `â€”`.
  - This does not break the app, but it makes maintenance painful.

## Priority 1 - Complete Core User Flows

- [ ] Finish bookmarks end to end.
  - Persist bookmark toggles from every article surface.
  - Add a Firestore-backed bookmark provider.
  - Make `BookmarkScreen` fetch saved articles for the current user instead of receiving a local list.
  - Add Bookmarks to navigation if it remains a first-class feature.

- [ ] Finish like/unlike persistence everywhere.
  - `FirestoreRepository.toggleLike` exists.
  - Wire it into `MediaFeedScreen`, `ArticleDetailScreen`, `NewsTile`, and any trending cards.
  - Compute `isLiked` per current user from `likedBy`.

- [ ] Build comments properly.
  - Add Firestore subcollection: `articles/{articleId}/comments`.
  - Support create, list, delete-own-comment, and count updates.
  - Replace placeholder comment screens/actions with real data.

- [x] Improve article detail screen.
  - Uses `NewsArticleModel` directly and can load by article ID.
  - Shows source, author/source identifier, category, created time, body, image, likes, comments, bookmark, and share action.
  - Includes loading/error states when opened by article ID.

- [x] Complete profile content tabs.
  - Posts: current user's articles.
  - Saved: bookmarked articles.
  - Liked: liked articles.
  - Courses and Events: removed from the profile tabs until real course/event data exists.

- [ ] Complete create post.
  - Add category selector instead of hardcoded `Trending`.
  - Add draft validation: title, body, image, category.
  - Upload avatar/profile images correctly instead of storing local paths.
  - Decide whether posts are published immediately or require moderation.

## Priority 2 - Product Features to Add

- [ ] Real personalization.
  - Use onboarding interests and followed topics to rank the `For You` feed.
  - Normalize topic/category slugs so `AI`, `ai`, `startup_news`, and display labels are consistent.
  - Add a preferences/settings screen for editing role and interests.

- [ ] Follow authors/sources.
  - Add `followedSources` or a `follows` collection.
  - Replace local-only follow state in Search and Media Feed.
  - Use follows in profile stats and feed ranking.

- [ ] Notifications product layer.
  - FCM plumbing exists, but notification entities need a clear trigger system.
  - Add notification types: new follower, comment, like, article from followed source, admin update.
  - Add mark read/delete interactions to the notifications screen.

- [ ] Search improvements.
  - Current Firestore search fetches latest 100 articles and filters client-side.
  - Add indexed search fields such as `searchKeywords`.
  - For scale, use Algolia/Typesense/Meilisearch or Firestore-compatible keyword arrays.

- [ ] Startup-specific modules.
  - Funding opportunities with filters by stage, sector, location, deadline.
  - Startup events with RSVP/save calendar support.
  - Founder courses/playbooks with progress tracking.
  - Startup leaderboard with real criteria instead of static cards.
  - Communities with join, posts, member list, and moderation.

- [ ] Media feed enhancements.
  - Add video support if the vertical feed is intended to be Reels/TikTok-style.
  - Add share sheet, comment modal, save persistence, and author profile navigation.
  - Add empty/error states instead of only showing a spinner when the feed has no posts.

## Priority 3 - Data Model and Backend Hardening

- [ ] Define Firestore collections clearly.
  - `users/{uid}`
  - `articles/{articleId}`
  - `articles/{articleId}/comments/{commentId}`
  - `user_topics/{uid}`
  - `users/{uid}/notifications/{notificationId}`
  - Optional: `sources`, `communities`, `events`, `funding_opportunities`, `courses`

- [ ] Add Firestore security rules.
  - Users can edit only their own profile.
  - Users can create articles only as themselves.
  - Users can update only allowed interaction fields on others' articles.
  - Comments can be deleted by owner or moderator/admin.

- [ ] Add repository boundaries.
  - Split `FirestoreRepository` into smaller repositories:
    - `UserRepository`
    - `ArticleRepository`
    - `InteractionRepository`
    - `TopicRepository`
    - `UploadRepository`
  - Keep Firebase-specific code out of widgets.

- [ ] Stop direct Firebase access in UI where practical.
  - `SplashScreen`, `HomeScreen`, `MediaFeedScreen`, `PersonalProfileScreen`, and `user_topics_provider.dart` use direct Firebase calls.
  - Prefer providers/repositories so testing and auth-state changes are cleaner.

- [ ] Add server timestamps and derived count strategy.
  - Likes/bookmarks/comments counts should be transactionally maintained or computed from subcollections.
  - Avoid trusting client-provided counts for important product surfaces.

## Priority 4 - UX and Visual Polish

- [x] Make dark mode complete.
  - Audited Create Post, Edit Profile, Search, Bookmark, Auth screens, source profile, article detail, comments, and common empty/search states.

- [x] Clean navigation UX.
  - Standardized article, comments, search tab, and source profile navigation through named routes.
  - Removed inline `MaterialPageRoute` usage from app code.

- [ ] Improve loading, empty, and error states.
  - Home, Explore, Search, Notifications, Profile, Bookmarks should all have specific empty/error UI.
  - Avoid indefinite spinners when Firestore returns empty lists.

- [ ] Replace placeholder actions.
  - Home quick actions show "coming soon".
  - Settings Notification/Security/Help do nothing.
  - Create Post toolbar buttons do nothing.
  - Article share/menu actions are placeholders.

- [ ] Improve image handling.
  - Support both local assets and remote URLs consistently.
  - Add placeholders, error states, caching, and upload progress.
  - Avoid using local file paths as persisted avatar URLs.

## Priority 5 - Testing and Release Readiness

- [ ] Add unit tests for models.
  - `UserModel.fromFirestore/toFirestore`
  - `NewsArticleModel.fromFirestore/toFirestore`
  - time formatting helpers

- [ ] Add repository tests with Firebase emulator or fakes.
  - Auth repository behavior.
  - Article create/search/toggle like/bookmark.
  - User onboarding save.

- [ ] Add widget tests for key screens.
  - Splash routing decision.
  - Login/signup validation.
  - Create post validation.
  - Search empty/loading/results states.

- [ ] Add CI checks.
  - `flutter analyze`
  - `flutter test`
  - Android release build
  - Optional formatting check with `dart format --set-exit-if-changed .`

- [ ] Add Firebase emulator workflow.
  - Local dev should not require writing test data to production Firestore.
  - Move "Seed Sample Articles" behind debug mode or a dev-only build flag.

## Suggested Build Order

1. Fix compile/test/navigation issues.
2. Consolidate `NewsArticleModel` and remove article model duplication.
3. Wire likes, bookmarks, comments, and article detail to Firestore.
4. Finish profile tabs using real user-specific article queries.
5. Complete search route and improve search indexing.
6. Add author/source following and use it in feed personalization.
7. Convert mock Home sections into real modules one by one: funding, events, courses, communities.
8. Add Firestore rules, emulator tests, and CI test gates.
9. Polish dark mode, empty states, settings, and image handling.
10. Prepare beta release with seeded real content and production Firebase rules.

## Good First Tasks

- [ ] Add `/search` route to `MaterialApp.routes`.
- [ ] Fix `test/widget_test.dart`.
- [ ] Add a `bookmarkedArticlesProvider`.
- [ ] Replace `BookmarkScreen` local list with Firestore data.
- [ ] Wire `MediaFeedScreen._toggleLike` to `FirestoreRepository.toggleLike`.
- [ ] Add category selection to `CreatePostScreen`.
- [ ] Remove the dev seed button from production settings.
- [ ] Clean README encoding.

## Bigger Product Bets

- [ ] Founder dashboard: saved funding, upcoming events, courses in progress, followed sectors.
- [ ] Startup/source profiles: articles, followers, verification badge, website, social links.
- [ ] Community groups: topic-based discussion spaces.
- [ ] Funding database: deadlines, eligibility, apply links, saved opportunities.
- [ ] Startup learning: short lessons/playbooks connected to user roles.
- [ ] Admin/moderation panel: approve posts, feature trending stories, send notifications.
