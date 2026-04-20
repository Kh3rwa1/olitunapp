# Olitun — Learn Ol Chiki (Santali Script) ᱚᱞᱤᱛᱩᱱ

A premium, gamified language learning app for **Ol Chiki** — the writing system used by ~7.6 million Santal people of South Asia. Think Duolingo, but for a culturally significant and underserved script.

> Built with Flutter • Appwrite BaaS • Riverpod • Material 3

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Lessons** | Progressive alphabet, numbers, words, and sentence lessons with dual-script display (Ol Chiki + Latin transliteration) |
| **Quizzes** | Multiple-choice quizzes with animated feedback, scoring, and mastery levels |
| **Practice** | Letter tracing and pronunciation practice |
| **Rhymes** | Curated Santali rhymes and cultural content with audio playback |
| **AI Translator** | Translate between English and Santali via custom proxy |
| **Progress Tracking** | Streaks, stars, learning time, mastery levels, and cloud sync |
| **Admin CMS** | Full content management dashboard for educators |
| **Responsive** | Adapts to mobile, tablet, and desktop with sidebars |

---

## 🏗️ Architecture

```
lib/
├── core/              → Theme, auth, API services, config, layout
│   ├── api/           → Appwrite DB service (generic CRUD)
│   ├── auth/          → Appwrite auth (OTP + Google OAuth)
│   ├── config/        → Centralized environment config
│   ├── theme/         → Design system (colors, typography)
│   └── presentation/  → Shared layout, animations
├── shared/            → Providers, models, widgets
│   ├── providers/     → Riverpod state management (modular)
│   ├── models/        → Data models (Category, Lesson, Quiz, etc.)
│   └── widgets/       → Reusable UI components
├── features/          → Feature-first modules
│   ├── admin/         → CMS dashboard
│   ├── auth/          → Email OTP + Google OAuth
│   ├── home/          → Main feed, AI translator
│   ├── lessons/       → Categories, detail, practice, quiz
│   ├── main/          → Shell (bottom nav, desktop sidebar)
│   ├── onboarding/    → Splash, onboarding video
│   ├── profile/       → Progress, settings
│   ├── quiz/          → Quiz list
│   └── rhymes/        → Cultural content
└── main.dart          → App entry, routing
```

### Tech Stack

- **Frontend:** Flutter (Dart) with Material 3
- **Backend:** Appwrite (Auth, Database, Storage)
- **State:** Riverpod (StateNotifier pattern)
- **Routing:** GoRouter with route guards
- **AI:** Google Translate proxy via PHP on Hostinger
- **Fonts:** Poppins + OlChiki custom font

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.9.0`
- Dart SDK `^3.9.0`
- An [Appwrite](https://appwrite.io/) project with database `olitun_db`

### Setup

```bash
# Clone
git clone https://github.com/<your-username>/olitunapp.git
cd olitunapp

# Install dependencies
flutter pub get
```

### Environment Variables

All credentials are injected at **build time** via `--dart-define`. No secrets are hardcoded.

| Variable | Required | Description |
|----------|----------|-------------|
| `APPWRITE_ENDPOINT` | ✅ | Appwrite API endpoint (e.g. `https://sgp.cloud.appwrite.io/v1`) |
| `APPWRITE_PROJECT_ID` | ✅ | Your Appwrite project ID |
| `ADMIN_SECRET_KEY` | ✅ | Secret key for admin panel login |

### Run (Debug)

```bash
flutter run \
  --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<your-project-id> \
  --dart-define=ADMIN_SECRET_KEY=<your-admin-key>
```

### Build (Release APK)

```bash
flutter build apk --release \
  --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<your-project-id> \
  --dart-define=ADMIN_SECRET_KEY=<your-admin-key>
```

### Build (Web)

```bash
flutter build web \
  --dart-define=APPWRITE_ENDPOINT=https://sgp.cloud.appwrite.io/v1 \
  --dart-define=APPWRITE_PROJECT_ID=<your-project-id> \
  --dart-define=ADMIN_SECRET_KEY=<your-admin-key>
```

---

## 📱 Appwrite Collections

The app expects these collections in database `olitun_db`:

| Collection | Purpose |
|------------|---------|
| `categories` | Lesson categories (Alphabet, Numbers, etc.) |
| `letters` | Ol Chiki letter definitions |
| `numbers` | Number definitions |
| `words` | Vocabulary words |
| `sentences` | Sentence examples |
| `lessons` | Lesson content with blocks (JSON) |
| `banners` | Featured banners for home screen |
| `rhymes` | Santali rhymes and songs |
| `rhyme_categories` | Rhyme category groupings |
| `rhyme_subcategories` | Rhyme subcategory groupings |
| `app_settings` | Key-value app settings |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -m 'Add your feature'`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Cultural Note

Ol Chiki (ᱚᱞ ᱪᱤᱠᱤ) was created by **Pandit Raghunath Murmu** in 1925 to write the Santali language. It is used by the Santal people — one of the largest indigenous communities in South Asia. This app aims to make learning Ol Chiki accessible, engaging, and fun for a new generation.

**Johar! ᱡᱚᱦᱟᱨ!** 🙏
