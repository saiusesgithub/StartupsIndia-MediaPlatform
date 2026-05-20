# Future Chat Handoff

Last updated: 2026-05-20.

## Current Branch State

- Active branch: `main`.
- `origin/main` includes the community work and the role-based signup/profile change.
- Recent pushed commit on `main`: `ce9c8b7 Rework signup around role-based profiles`.
- Known local uncommitted files at the time these docs were created:
  - `ROLE_DETAILS.md` is private and explicitly says not to push it.
  - Generated platform registrants under `macos/Flutter` and `windows/flutter` were modified before this docs task.

## App Summary

This is a Flutter mobile app for the Startups India ecosystem. It uses Firebase
Auth, Cloud Firestore, Firebase Messaging, Cloudinary image upload, Riverpod,
Google Sign-In, URL launching, and media/video packages.

The main tabs are:

- Home: article/news feed, trending, comments, reports, notifications entry.
- Explore: media posts, source profiles, search.
- Build: bottom-nav center action that opens external Startup India resource links.
- Community: Firestore-driven communities, announcements, bottom-sheet comments, activity.
- Profile: user profile, saved/liked/articles/videos/community membership, settings.

## Most Important Current Flows

Authentication and onboarding:

1. `/splash` checks Firebase auth and `users/{uid}.onboardingCompleted`.
2. Logged-out users go to `/welcome`.
3. Welcome offers Login, Create Account, and Continue as Guest.
4. Create Account goes to `/role-selection`.
5. Role selection stores one of `student`, `founder`, `mentor`, `investor`, `college`, `startup_enthusiast` in route args.
6. Signup supports email/password and Google. Successful signup continues to interest selection.
7. Interest selection continues to `/fill-profile`.
8. Fill profile saves `users/{uid}` with identity, contact, role, interests, `roleDetails`, and `onboardingCompleted: true`.

Community:

- Communities are Firestore-driven. The app seeds four defaults only when `communities` is empty.
- My Groups, Discover, and My Activity are real routes via `/community-collection`.
- Announcement comments are not inline; tapping the comments row opens a bottom sheet.
- My Activity is built from community comments authored by the user plus comments whose `mentionedUserIds` contains the user id.
- Admin replies should store the mentioned user id in `mentionedUserIds`; plain `@name` text is only a weak display/search fallback.

## Do Not Forget

- Firestore rules must be deployed after rules changes:
  `firebase deploy --only firestore:rules`
- The admin UID is hardcoded in `firestore.rules`.
- `flutter analyze` currently reports warnings/infos in existing code. Treat new errors as blockers, but the repo is not clean-lint yet.
- Some source comments/text have mojibake encoding artifacts from earlier edits. Avoid spreading that into new docs or code.

## First Files To Open For New Work

- App bootstrap/routing: `lib/main.dart`
- Theme tokens: `lib/theme/style_guide.dart`, `lib/theme/app_theme.dart`
- Core user model/repo: `lib/core/models/user_model.dart`, `lib/core/repository/firestore_repository.dart`
- Auth flow: `lib/features/auth/presentation/screens/*`, `lib/features/onboarding/presentation/screens/*`
- Community: `lib/features/community/**`
- Explore/media: `lib/features/explore/**`
- Firestore rules: `firestore.rules`
