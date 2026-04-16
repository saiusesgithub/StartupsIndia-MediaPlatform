<div align="center">

<br />

```text
 ____  _             _                     ___           _ _       
/ ___|| |_ __ _ _ __| |_ _   _ _ __  ___  |_ _|_ __   __| (_) __ _ 
\\___ \\| __/ _` | '__| __| | | | '_ \\/ __|  | || '_ \\ / _` | |/ _` |
 ___) | || (_| | |  | |_| |_| | |_) \\__ \\  | || | | | (_| | | (_| |
|____/ \\__\\__,_|_|   \\__|\\__,_| .__/|___/ |___|_| |_|\\__,_|_|\\__,_|
                              |_|                                  
```

**A modern, beautifully designed Flutter news application.**  
*Personalized. Real-time. Always Trending.*

<br/>

[![Android Build](https://github.com/saiusesgithub/StartupsIndia-MediaPlatform/actions/workflows/android_build.yml/badge.svg)](https://github.com/saiusesgithub/StartupsIndia-MediaPlatform/actions/workflows/android_build.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

---

## ✨ What is Startups India?

**Startups India** is a full-stack Flutter news application built for the modern reader. It features a curated onboarding experience, Google & email authentication, a personalized home feed, trending articles, topic filtering, bookmarks, and a full user profile — all backed by Firebase and designed pixel-for-pixel from a Figma UI kit.

---

## 📱 Screenshots

> *Coming soon — CI pipeline generates APK artifacts on every push.*

---

## 🚀 Features

### 🔐 Authentication
- Email & password sign-in with robust validation (uppercase, digit, special char)
- **Google Sign-In** (via `google_sign_in` v7 + Firebase Auth)
- Persistent session with `SharedPreferences`
- Forgot password flow

### 🎨 Onboarding
- Splash / Welcome screens
- **Country selector** (flag + search)
- **Topic chooser** — pick your news interests
- **News source selector** — follow your favourite outlets
- **Fill your Profile** — avatar picker (camera/gallery via `image_picker`), bio, username

### 🏠 Home Feed
- Custom `CustomScrollView` AppBar with logo + notification bell
- Search & filter bar
- **Trending** large-card carousel (horizontal scroll)
- **Category selector** (pinned sticky header)
- **Latest** news list with thumbnail `NewsArticle` tiles
- Pull-to-refresh ready architecture

### 🔖 Explore · Bookmarks · Profile
- Modular feature folders — ready for full implementation
- Profile screen backed by Firestore `users` collection
- Cloudinary integration for avatar upload

### ⚙️ CI / CD
- GitHub Actions workflow on every push to any branch
- Builds a signed **release APK** automatically
- Uploads APK as a downloadable **artifact**
- `google-services.json` injected securely via **GitHub Secrets** (base64-encoded)

---

## 🏗️ Architecture

```
lib/
├── core/                          # Shared utilities, providers, widgets
│   ├── presentation/widgets/      # AppTextField, etc.
│   └── providers/                 # Firebase singleton providers (Riverpod)
│
├── features/
│   ├── auth/                      # Authentication feature
│   │   ├── data/repositories/     # FirebaseAuthRepositoryImpl
│   │   ├── domain/                # AuthRepository interface, UserModel
│   │   └── presentation/          # LoginScreen, SignupScreen, FillProfileScreen …
│   │
│   ├── onboarding/                # Country, Topics, News Sources screens
│   ├── home/                      # HomeScreen, TrendingCard, NewsTile, NewsArticle
│   ├── explore/                   # (in progress)
│   ├── bookmark/                  # (in progress)
│   └── profile/                   # (in progress)
│
├── theme/
│   ├── app_theme.dart             # MaterialTheme configuration
│   └── style_guide.dart           # AppColors + AppTypography (Poppins)
│
└── main.dart                      # App entry, Firebase init, named routes
```

**State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod ^3.3.1`)  
**Pattern:** Repository pattern — UI never touches Firebase directly. Swap the impl tomorrow with any backend.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter 3.x (Dart 3.9.2) |
| **State Management** | flutter_riverpod ^3.3.1 |
| **Authentication** | Firebase Auth + Google Sign-In v7 |
| **Database** | Cloud Firestore |
| **Storage** | Firebase Storage + Cloudinary |
| **Fonts** | Google Fonts — Poppins |
| **Icons** | Material Icons + Font Awesome Flutter |
| **Images** | cached_network_image + shimmer |
| **Notifications** | Firebase Messaging + flutter_local_notifications |
| **CI / CD** | GitHub Actions → APK artifact |

---

## ⚡ Getting Started

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
> keytool -list -keystore %USERPROFILE%\\.android\\debug.keystore -alias androiddebugkey -storepass android
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

## 🔄 CI / CD — GitHub Actions

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
   # PowerShell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android\\app\\google-services.json"))
   ```
2. Go to **GitHub → Settings → Secrets and variables → Actions → New repository secret**
3. Name: `GOOGLE_SERVICES_JSON` · Value: paste the base64 string

---

## 📦 Key Dependencies

```yaml
firebase_core: ^4.6.0
firebase_auth: ^6.3.0
cloud_firestore: ^6.2.0
firebase_storage: ^13.0.0
firebase_messaging: ^16.1.3
google_sign_in: ^7.2.0
flutter_riverpod: ^3.3.1
google_fonts: ^8.0.2
cached_network_image: ^3.4.1
image_picker: ^1.2.1
cloudinary_public: ^0.23.1
shimmer: ^3.0.0
timeago: ^3.7.1
font_awesome_flutter: ^11.0.0
flutter_local_notifications: ^17.0.0
```

---

## 🗺️ Roadmap

- [x] Onboarding flow (country, topics, sources, profile)
- [x] Email/password authentication
- [x] Google Sign-In
- [x] Firestore user persistence
- [x] Home feed with Trending + Latest
- [x] Category filter (sticky header)
- [x] Bottom navigation bar
- [x] GitHub Actions CI — release APK artifact
- [ ] Trending full-view screen (`/trending`)
- [ ] Explore screen
- [ ] Bookmarks (Firestore-backed)
- [ ] Full profile screen with edit
- [ ] Push notifications (FCM)
- [ ] Article detail screen
- [ ] Dark mode

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create your feature branch: `git checkout -b feat/amazing-feature`
3. Commit your changes: `git commit -m 'feat: add amazing feature'`
4. Push to the branch: `git push origin feat/amazing-feature`
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">

**Made with ❤️ and Flutter**

*Designed from [News App UI Kit](https://www.figma.com/community/file/) · Built by [@saiusesgithub](https://github.com/saiusesgithub)*

</div>
