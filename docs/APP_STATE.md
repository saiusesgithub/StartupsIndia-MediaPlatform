# App State

Last updated: 2026-05-20.

## Product Shape

The app is a startup ecosystem media and community platform. It combines a news
feed, media/explore feed, community announcements and discussions, role-based
onboarding, and a personal profile area.

The current UI is primarily dark-mode friendly. Light theme exists and is wired
through the shared theme provider.

## Entry And Auth

Current startup route is `/splash`.

Splash behavior:

- If no Firebase user exists, route to `/welcome`.
- If a Firebase user exists, read `users/{uid}.onboardingCompleted`.
- If onboarding is incomplete, route to `/role-selection`.
- If onboarding is complete or Firestore read fails, route to `/home`.

Welcome behavior:

- Login routes to `/login`.
- Create Account routes to `/role-selection`.
- Continue as Guest routes directly to `/home`.

Guest users can see app surfaces, but protected actions should use `GuestGate`
or explicit auth checks.

## Signup And Onboarding

The create-account flow is role-first:

1. Select role.
2. Create account by email/password or Google.
3. Select interests.
4. Fill profile.

Supported roles:

- `student`
- `founder`
- `mentor`
- `investor`
- `college`
- `startup_enthusiast`

Fill Profile collects shared fields:

- full name
- unique username
- email address, read-only
- phone number
- avatar image
- bio
- website

It also collects role-specific fields and stores them as
`users/{uid}.roleDetails`. The field sets were implemented from a private client
requirements file and should be treated as client-approved behavior, not copied
verbatim from the private file.

Username uniqueness is checked by querying `users.usernameLower`.

Profile photo storage:

- Google sign-in can provide `FirebaseAuth.currentUser.photoURL`.
- User-selected profile images upload to Cloudinary through
  `FirestoreRepository.uploadImage`.
- The final URL is stored in `users/{uid}.avatarUrl`.

## Main App Tabs

`MainAppScaffold` owns the bottom nav with an `IndexedStack`.

- Home tab: news/articles and home content.
- Explore tab: media feed.
- Build action: opens a bottom bubble of external Startup India links.
- Community tab: communities overview.
- Profile tab: personal profile.

The center Build button is not a full page. It toggles an overlay menu.

## Home

Home uses Firestore articles via `FirestoreRepository`.

Main data flows:

- Latest articles: `articles` ordered by `createdAt desc`.
- Trending articles: latest articles filtered by `isTrending`.
- Article search: loads latest 100 articles and filters locally by headline, source, or category.
- Likes and bookmarks update arrays on `articles/{articleId}`.
- Article comments are stored in `articles/{articleId}/comments`.
- Reports are written to `reports`.

## Explore

Explore has Firestore-backed media posts in `posts`.

`PostModel` supports:

- author identity
- headline/excerpt/category
- media type
- video URL
- thumbnail URL
- liked/bookmarked user arrays
- counts for likes, comments, shares
- trending flag

Post comments are stored under `posts/{postId}/comments`.

## Community

Community is now Firestore-backed.

Overview screen:

- Quick cards route to full pages for My Groups, Discover, and My Activity.
- Preview sections show a small sample and a View All route.
- Activity preview means the user's community comments and mentions.

Collection screens:

- My Groups shows joined communities.
- Discover shows all available communities in a grid.
- My Activity shows comments the user wrote and comments mentioning the user.

Community detail:

- Shows community info and membership state.
- Joined users can read announcements.
- Only admins can create normal announcements from the app/admin side.
- Users can join/leave.
- Users can comment on announcements.
- Comments are opened in a bottom sheet from the comments icon/row.
- Comments can be replied to or reported.
- Link previews in announcements open in an external browser.

Communities are not hardcoded as permanent app state. The repo seeds four
defaults only if Firestore has no community documents. New production
communities should be created in Firestore/admin tooling.

## Profile

Personal profile shows:

- identity, avatar, role, interests, bio, website
- community membership tab
- saved articles
- saved videos
- liked articles
- achievements/pro banner UI

Edit profile uses existing user data and keeps email read-only.

## Notifications

Firebase Messaging is initialized in `main.dart`.

- Foreground messages show a snackbar and local notification.
- Tapping a notification with `data.page == "notifications"` routes to `/notifications`.
- FCM tokens are saved to `users/{uid}.fcmTokens` through the notifications repository.
- App notifications are stored under `users/{uid}/notifications`.
