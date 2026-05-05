# Architecture

Olitun follows **Clean Architecture** with feature-first module organization.

## Layer Diagram

```
┌─────────────────────────────────────────────────────┐
│                    Presentation                      │
│  ConsumerWidget → AsyncValue.when → Widget tree      │
├─────────────────────────────────────────────────────┤
│                    Providers (Riverpod)               │
│  StateNotifier / FutureProvider / StateProvider       │
├─────────────────────────────────────────────────────┤
│                    Domain                            │
│  Entities  │  Repository contracts  │  Failures      │
├─────────────────────────────────────────────────────┤
│                    Data                              │
│  Repository impls  │  Models  │  DataSources         │
├─────────────────────────────────────────────────────┤
│                    Core / Infrastructure             │
│  Appwrite SDK  │  Hive  │  SharedPreferences         │
└─────────────────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── app/
│   └── router/                  # GoRouter config + route guards
├── core/
│   ├── api/                     # AppwriteDbService, AiService
│   ├── auth/                    # AppwriteAuthService (singleton)
│   ├── config/                  # AppwriteConfig (build-time validation)
│   ├── error/                   # Sealed Failure + Exception classes
│   ├── motion/                  # PressableScale, AnimatedCounter, ConfettiBurst
│   ├── network/                 # NetworkInfo (connectivity check)
│   ├── observability/           # CrashReporting (Sentry wrapper)
│   ├── presentation/layout/     # ResponsiveLayout, PageContainer
│   ├── storage/                 # CacheService (Hive), HiveService (init)
│   └── theme/                   # AppTheme, AppColors, AdminTokens
├── features/
│   ├── admin/                   # CMS dashboard (presentation-only)
│   ├── auth/                    # data/domain/presentation layers
│   ├── categories/              # data/domain/presentation layers
│   ├── home/                    # Home screen (presentation)
│   ├── lessons/                 # data/domain/presentation layers
│   ├── main/                    # Shell + bottom nav
│   ├── onboarding/              # First-run flow
│   ├── profile/                 # data/domain/presentation layers
│   ├── quiz/                    # Quiz gameplay (presentation)
│   ├── rhymes/                  # Rhyme viewer (presentation)
│   └── translate/               # AI translator (presentation)
└── shared/
    ├── models/                  # Content models (shared DTOs)
    ├── providers/               # Cross-feature providers
    └── widgets/                 # Reusable UI components
```

## Data Flow

```
UI (watch provider) → Riverpod provider → Repository
    │                                        │
    └── AsyncValue.when(data/loading/error) ← ┘
                                              │
                    ┌─────────────────────────┤
                    ▼                         ▼
              Remote DataSource         Local DataSource
              (Appwrite SDK)              (Hive cache)
```

**Offline-first pattern:**
1. Repository checks cache (Hive) → returns cached data immediately
2. Fetches remote (Appwrite) in parallel
3. On success → updates cache + emits fresh data
4. On failure → falls back to cached data or returns `NetworkFailure`

## Error Architecture

```
Exception (thrown in DataSource)
    → caught in Repository
    → mapped to sealed Failure
    → returned as Either<Failure, T>
    → consumed by UI via .when() or .fold()
```

Failure types: `ServerFailure`, `CacheFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure`.

## State Management

All state flows through **Riverpod**:
- `SharedPreferences` → injected via `sharedPreferencesProvider` override at root `ProviderScope`
- `AsyncValue<T>` → used for all async data (categories, lessons, quizzes, user stats)
- `StateNotifier` → used for mutable domain state (quiz progress, user stats)
- `StateProvider` → used for simple UI state (theme mode, tab index)

## Security Model

- **No hardcoded secrets** — all config via `--dart-define`
- **Admin access** — Appwrite Team membership (server-side), not client-side tokens
- **Two-layer admin guard** — GoRouter redirect + AdminShell widget re-check
- **CSP headers** configured in `vercel.json`
- See `SECURITY.md` for full threat model

## Configuration

Required build flags:
```
--dart-define=APPWRITE_ENDPOINT=...
--dart-define=APPWRITE_PROJECT_ID=...
--dart-define=TRANSLATE_URL=...
```

Optional:
```
--dart-define=SENTRY_DSN=...
--dart-define=ADMIN_TEAM_ID=...
--dart-define=ALLOW_SELF_SIGNED=true
```

The app **fails fast** at boot if mandatory flags are missing (`AppwriteConfig.validate()`).
