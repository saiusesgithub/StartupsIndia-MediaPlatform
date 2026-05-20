# Architecture

Last updated: 2026-05-20.

## Stack

- Flutter with Dart SDK `^3.9.2`.
- Riverpod for state management.
- Firebase Core, Auth, Firestore, Messaging, Storage.
- Google Sign-In v7.
- Cloudinary for image uploads.
- URL Launcher for external links.
- Local notifications for foreground FCM display.
- Cached network images, image picker, video player, share plus, timeago, shimmer.

## Directory Layout

Top-level app code lives in `lib/`.

- `main.dart`: Firebase initialization, FCM setup, Google Sign-In initialization, app routes.
- `firebase_options.dart`: generated FlutterFire config.
- `theme/`: app colors, typography, light/dark Material themes.
- `core/`: shared models, repositories, providers, widgets, utilities.
- `features/`: product features split by domain.

Feature folders generally follow:

- `data/repositories`: Firestore or mock data access.
- `domain/models`: feature models.
- `domain/repositories`: repository interfaces when present.
- `presentation/providers`: Riverpod providers.
- `presentation/screens`: screens.
- `presentation/widgets`: feature widgets.

## Bootstrap

`main()` does the following:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. `Firebase.initializeApp`.
3. Enables Firestore offline persistence.
4. Initializes local notifications.
5. Registers Firebase Messaging background handler.
6. Requests notification permission.
7. Logs current FCM token if available.
8. Initializes Google Sign-In on non-web.
9. Runs `ProviderScope(child: MyApp())`.

`MyApp` is a `ConsumerStatefulWidget` so it can watch theme mode and register
FCM foreground/tap listeners.

## Routing

The app uses named routes in `MaterialApp.routes`.

Important routes:

- `/splash`
- `/welcome`
- `/role-selection`
- `/interest-selection`
- `/login`
- `/signup`
- `/fill-profile`
- `/home`
- `/explore`
- `/profile`
- `/search`
- `/article-detail`
- `/comments`
- `/community-detail`
- `/community-collection`
- `/trending`
- `/notifications`
- `/settings`
- profile/settings/legal/pro routes

`/home`, `/explore`, and `/profile` all instantiate `MainAppScaffold` with
different initial indexes.

## State Management

Riverpod is used for providers:

- Firebase singleton providers in `core/providers/firebase_providers.dart`.
- Auth providers in `features/auth/presentation/providers/auth_providers.dart`.
- News providers in `features/home/presentation/providers/news_provider.dart`.
- Community providers in `features/community/presentation/providers/community_providers.dart`.
- Post providers in `features/explore/presentation/providers/post_providers.dart`.
- Notification providers in `features/notifications/presentation/providers/notification_providers.dart`.

Current provider style mixes:

- `Provider` for repository instances.
- `StreamProvider` for Firestore realtime data.
- `FutureProvider` for debounced search.
- `NotifierProvider` for local search query state.

## Repository Pattern

Core repository:

- `FirestoreRepository` handles users, articles, article likes/bookmarks, topics, image uploads.

Feature repositories:

- `CommunityRepositoryImpl` handles communities, membership, announcements, comments, reports on comments.
- `PostRepository` handles media posts, post likes/bookmarks/shares, post comments, article comments.
- `FirebaseNotificationRepositoryImpl` handles per-user notifications and FCM token persistence.
- `LeaderboardRepository` and `ReportRepository` support home/profile-related surfaces.

The codebase is not strict-clean architecture. Some UI code directly imports
Firebase or feature repositories where pragmatic.

## UI System

Shared visual primitives are in:

- `theme/style_guide.dart`
- `theme/app_theme.dart`
- `core/presentation/widgets`

Design is custom Flutter widget composition rather than a third-party component
system. The app relies on:

- Material icons.
- AppColors and AppTypography tokens.
- Dark/light theme mode through `themeServiceProvider`.

## Navigation Shell

`MainAppScaffold` owns:

- bottom navigation
- current tab index
- Build menu overlay
- FCM token sync provider watch

Build menu launches external URLs with `LaunchMode.externalApplication`.

## Firebase And Security Boundary

The mobile app is not trusted for admin-only writes. Admin rights are currently
enforced in Firestore rules using a hardcoded admin UID.

Production/admin tooling should create:

- normal article documents
- media posts
- community documents
- normal community announcements
- moderated deletes/status changes
- notifications

The app primarily allows signed-in user interactions:

- profile edits
- topic follows
- article/post likes/bookmarks
- comments
- community membership
- comment reports
