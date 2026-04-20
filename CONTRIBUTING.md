# Contributing to Olitun

Thank you for your interest in helping preserve and promote the Ol Chiki script! 🙏

## Prerequisites

- **Flutter SDK** `^3.9.0` ([install](https://docs.flutter.dev/get-started/install))
- **Git**
- An **Appwrite Cloud** account (free tier works)

## Local Setup

```bash
# 1. Fork & clone
git clone https://github.com/<your-username>/olitunapp.git
cd olitunapp

# 2. Install dependencies
flutter pub get

# 3. Create your local run script (never committed)
cp run.sh.example run.sh
chmod +x run.sh

# 4. Edit run.sh with your Appwrite credentials
#    APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, ADMIN_SECRET_KEY

# 5. Set up the Appwrite database
APPWRITE_API_KEY=<your-server-key> node scripts/appwrite_setup.mjs
APPWRITE_API_KEY=<your-server-key> node scripts/appwrite_seed.mjs

# 6. Run
./run.sh          # Chrome (web)
./run.sh android  # Android device
```

## Project Structure

```
lib/
├── core/        → Theme, auth, API, config, layout
├── shared/      → Providers, models, reusable widgets
├── features/    → Feature modules (home, lessons, quiz, etc.)
└── main.dart    → Entry point, routing

scripts/         → DB setup, seeding, data migration (see scripts/README.md)
functions/       → Appwrite Cloud Functions (Dart)
test/            → Unit + integration tests
```

## Development Workflow

### Branch Naming

```
feature/short-description   → New features
fix/short-description       → Bug fixes
docs/short-description      → Documentation
refactor/short-description  → Code cleanup
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add letter tracing animation
fix: resolve bento grid overflow on mobile
docs: update scripts README
refactor: extract quiz scoring logic
test: add progress roundtrip tests
chore: bump flutter_riverpod to 2.6.1
```

### Before Submitting a PR

```bash
# 1. Analyze (must pass with zero issues)
flutter analyze

# 2. Run all tests
flutter test

# 3. Verify the app builds
flutter build web --dart-define=APPWRITE_ENDPOINT=https://example.com/v1 \
  --dart-define=APPWRITE_PROJECT_ID=test \
  --dart-define=ADMIN_SECRET_KEY=test
```

## Code Guidelines

- **State management:** Riverpod `StateNotifier` pattern
- **Routing:** GoRouter with route guards
- **Models:** Immutable with `fromJson` / `toJson` / `copyWith`
- **Theme:** Use `AppColors` and `AppTextStyles` — no hardcoded colors
- **Dual script:** Always provide both `titleOlChiki` and `titleLatin`
- **No hardcoded secrets:** All credentials via `--dart-define`

## Adding Content

Lesson and quiz content lives in Appwrite collections. To add content:

1. Use the **Admin CMS** (in-app, requires `ADMIN_SECRET_KEY`)
2. Or use the seed scripts in `scripts/`

## Reporting Issues

- Search existing issues first
- Include: device/browser, Flutter version (`flutter doctor -v`), steps to reproduce
- Screenshots or screen recordings are very helpful

## Cultural Sensitivity

Ol Chiki is a living script with deep cultural significance to the Santal people. When contributing content:

- Verify transliterations with native speakers when possible
- Respect the original letterforms and naming conventions
- Credit cultural sources appropriately

---

**Johar! ᱡᱚᱦᱟᱨ!** — Every contribution helps preserve Ol Chiki for future generations.
