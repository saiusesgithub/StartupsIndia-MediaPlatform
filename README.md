<div align="center">

<br />

```text
 ____  _             _                     ___           _ _       
/ ___|| |_ __ _ _ __| |_ _   _ _ __  ___  |_ _|_ __   __| (_) __ _ 
\___ \| __/ _` | '__| __| | | | '_ \/ __|  | || '_ \ / _` | |/ _` |
 ___) | || (_| | |  | |_| |_| | |_) \__ \  | || | | | (_| | | (_| |
|____/ \__\__,_|_|   \__|\__,_| .__/|___/ |___|_| |_|\__,_|_|\__,_|
                              |_|                                  
```

**StartupsIndia — The startup ecosystem app for founders, students, mentors, and investors.**  
*Communities. News. Opportunities. All in one place.*

<br/>

[![Android Build](https://github.com/saiusesgithub/StartupsIndia-MediaPlatform/actions/workflows/android_build.yml/badge.svg)](https://github.com/saiusesgithub/StartupsIndia-MediaPlatform/actions/workflows/android_build.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

---

## What is StartupsIndia?

**StartupsIndia** is a full-stack Flutter app for India's startup ecosystem. It features role-based onboarding (Founder, Student, Mentor, Investor, College, Startup Enthusiast), Google & email authentication, a personalized home feed, trending articles, video reels, startup communities, bookmarks, and a full user profile — all backed by Firebase.

---

## Screenshots

> *Coming soon — CI pipeline generates APK artifacts on every push.*

---

## Features

### Authentication
- Email & password sign-in with validation (uppercase, digit, special char, 8+ chars)
- **Google Sign-In** (via `google_sign_in` v7 + Firebase Auth)
- Persistent session + dark mode preference via `SharedPreferences`
- Forgot password / Change password flows
- Delete account with re-authentication

### Role-Based Onboarding
- Splash → Welcome → Role selection → Interest picker → Fill profile
- Roles: Founder, Student, Mentor, Investor, College, Startup Enthusiast
- Role-specific profile fields (locked after sign-up)

### Home Feed
- Personalized news feed with category filter (sticky header)
- **Trending** card carousel
- Article detail with share and bookmark
- Search across articles and sources

### Explore
- Video/image reel feed (TikTok-style)
- Guest mode with blur gate (3-item preview → sign-up CTA)

### Communities
- Join and browse startup communities
- Announcements, events, Q&A posts
- Community detail feed

### Profile & Settings
- Full profile with Overview, Activity, Groups, Bookmarks tabs
- Role-specific info display (college, startup details, mentor bio, etc.)
- Edit profile with role-specific fields
- Dark mode (persisted), notification preferences (persisted)
- Help & Support, Privacy Policy, Terms of Service
- About screen with social links and Made with Flutter badge

### CI / CD
- GitHub Actions workflow on every push
- Builds a signed **release APK** automatically
- `google-services.json` injected via **GitHub Secrets**

---

## Architecture

```
lib/
├── core/                          # Shared utilities, providers, widgets
│   ├── models/                    # UserModel, NewsArticleModel, etc.
│   ├── presentation/widgets/      # AppTextField, GuestBlur, etc.
│   ├── providers/                 # ThemeServiceNotifier, NotificationPrefsNotifier
│   └── repository/                # FirestoreRepository (Firestore + Cloudinary)
│
├── features/
│   ├── auth/                      # Authentication feature
│   │   ├── data/repositories/     # FirebaseAuthRepositoryImpl
│   │   ├── domain/                # AuthRepository interface, UserModel
│   │   └── presentation/          # Login, Signup, Splash, Welcome, Onboarding …
│   │
│   ├── onboarding/                # Role selection, Interest picker
│   ├── home/                      # HomeScreen, TrendingCard, NewsTile, ArticleDetail
│   ├── explore/                   # MediaFeedScreen (reels), SearchScreen
│   ├── community/                 # CommunityScreen, CommunityDetail
│   └── profile/                   # ProfileScreen, EditProfile, Settings and sub-screens
│
├── theme/
│   ├── app_theme.dart             # MaterialTheme (light + dark)
│   └── style_guide.dart           # AppColors + AppTypography (Poppins)
│
└── main.dart                      # App entry, Firebase init, FCM setup, named routes
```

**State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod ^3.3.1`)  
**Pattern:** Repository pattern — UI never touches Firebase directly.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter 3.x (Dart 3.9.2) |
| **State Management** | flutter_riverpod ^3.3.1 |
| **Authentication** | Firebase Auth + Google Sign-In v7 |
| **Database** | Cloud Firestore |
| **Media Storage** | Cloudinary (images, max 1080px / 82% quality) |
| **Push Notifications** | Firebase Cloud Messaging + flutter_local_notifications |
| **Fonts** | Google Fonts — Poppins |
| **Icons** | Material Icons + Font Awesome Flutter |
| **Images** | cached_network_image + shimmer |
| **CI / CD** | GitHub Actions → release APK artifact |

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.x` — [install guide](https://flutter.dev/docs/get-started/install)
- Java 17 (for Android build)
- A Firebase project with **Android app** registered

### 1. Clone the repo

```bash
git clone https://github.com/saiusesgithub/StartupsIndia-MediaPlatform.git
cd StartupsIndia-MediaPlatform
```

### 2. Add Firebase config

> `google-services.json` is gitignored for security.

Download it from [Firebase Console](https://console.firebase.google.com/) → Project Settings → Your Apps → Android, then place it at:

```
android/app/google-services.json
```

> **SHA-1 fingerprint required for Google Sign-In.** Add your debug SHA-1 in Firebase Console → Project Settings → Your Apps → Add fingerprint.
>
> Get your debug SHA-1:
> ```cmd
> keytool -list -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android
> ```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run

```bash
flutter run
```

---

## CI / CD — GitHub Actions

Every push to any branch triggers an automated build:

```yaml
# .github/workflows/android_build.yml
- Decode google-services.json from GitHub Secret (base64)
- flutter pub get
- flutter build apk --release
- Upload APK as artifact
```

### Setting up `GOOGLE_SERVICES_JSON` secret

1. Encode your `google-services.json`:
   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android\\app\\google-services.json"))
   ```
2. Go to **GitHub → Settings → Secrets and variables → Actions → New repository secret**
3. Name: `GOOGLE_SERVICES_JSON` · Value: paste the base64 string

---

## Key Dependencies

```yaml
firebase_core: ^4.6.0
firebase_auth: ^6.3.0
cloud_firestore: ^6.2.0
firebase_messaging: ^16.1.3
google_sign_in: ^7.2.0
flutter_riverpod: ^3.3.1
google_fonts: ^8.0.2
cached_network_image: ^3.4.1
image_picker: ^1.2.1
cloudinary_public: ^0.23.1
shimmer: ^3.0.0
shared_preferences: ^2.5.5
url_launcher: ^6.3.1
font_awesome_flutter: ^11.0.0
flutter_local_notifications: ^17.0.0
```

---

## Roadmap

- [x] Role-based onboarding (role, interests, profile)
- [x] Email/password + Google Sign-In
- [x] Firestore user persistence
- [x] Home feed — Trending + Latest + Category filter
- [x] Article detail + share + bookmark
- [x] Explore — video/image reel feed
- [x] Guest mode with blur gate
- [x] Communities (join, browse, announcements)
- [x] Full profile — Overview, Activity, Groups, Bookmarks
- [x] Edit profile (role-specific fields)
- [x] Settings — dark mode, notifications, help, legal
- [x] Push notifications — FCM + local notifications
- [x] GitHub Actions CI — release APK artifact
- [ ] Startup directory / search
- [ ] Funding tracker
- [ ] Direct messaging
- [ ] StartupsIndia Pro subscription

---

## Contributing

Pull requests are welcome! For major changes, please open an issue first.

1. Fork the repo
2. Create your feature branch: `git checkout -b feat/amazing-feature`
3. Commit your changes: `git commit -m 'feat: add amazing feature'`
4. Push: `git push origin feat/amazing-feature`
5. Open a Pull Request

---

## License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">

**Made with Flutter**

*Built by [@saiusesgithub](https://github.com/saiusesgithub) · [startupsindia.in](https://www.startupsindia.in/)*

</div>
