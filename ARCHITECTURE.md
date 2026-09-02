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
│   ├── admin/                   # CMS dashboard (presentation-heavy)
│   ├── affirmations/            # Daily affirmation flows
│   ├── auth/                    # data/domain/presentation layers
│   ├── categories/              # data/domain/presentation layers
│   ├── content/                 # Content detail surfaces (data/domain/presentation)
│   ├── home/                    # Home screen incl. AI translator (presentation)
│   ├── learn/                   # Browseable content grids (presentation)
│   ├── lessons/                 # data/domain/presentation layers
│   ├── legal/                   # Privacy / terms screens
│   ├── main/                    # Shell + bottom nav
│   ├── onboarding/              # First-run flow
│   ├── practice/                # Typing practice (data/domain/presentation)
│   ├── profile/                 # data/domain/presentation layers
│   ├── quiz/                    # Quiz gameplay (presentation)
│   └── rhymes/                  # Rhyme viewer (presentation)
└── shared/
    ├── models/                  # Content models (shared DTOs)
    ├── offline/                 # Offline mutation replay service
    ├── providers/               # Cross-feature providers (language, gamification,
    │                            #   waitlist, purchases, rhymes...) — the app's
    │                            #   parallel data-access layer for features shared
    │                            #   by multiple features; consumers must go through
    │                            #   these providers, never construct SDK objects
    ├── repositories/            # Content repository (bundled seeds + cache + network)
    └── widgets/                 # Reusable UI components
```

## SDK Isolation Rule

`package:appwrite` must never be imported outside `lib/core/` and
`lib/features/*/data/`. Presentation and domain layers consume SDK
capabilities exclusively through these anti-corruption seams:

| Seam | Location | Purpose |
| --- | --- | --- |
| `AppwriteDbService` | `core/api/appwrite_db_service.dart` | All TablesDB reads/writes (retry, paging, breadcrumbs) |
| `AppwriteFunctionsService` | `core/api/appwrite_functions_service.dart` | Serverless function RPCs; returns neutral `FunctionExecutionResult` |
| `DbQuery` / `DbId` | `core/api/appwrite_query_builders.dart` | Query-string builders + unique ID generation |
| `AppwriteErrorClassifier` | `core/error/appwrite_error_classifier.dart` | Exception → neutral error-info mapping |
| `data/di/*.dart` | `features/*/data/di/` | Datasource/repository provider wiring beside the impls it constructs |

Providers for cross-feature data live in `shared/providers/` (documented in
the directory table above); the content repository and mutation outbox are
documented in the Data Flow section below.

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
4. On failure → falls back to cached/bundled data, or surfaces a `CacheFailure` /
   `NetworkFailure` to the UI when nothing is available (no fabricated content)

**Offline writes** are durable: a content edit made while offline is cached
locally and queued in the `MutationOutboxService` (dedicated Hive box with
bounded exponential backoff and dead-lettering). The
`ContentMutationReplay` service drains the queue at startup and whenever
connectivity is regained.

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

## Appwrite Functions

Serverless Node-22 functions live under `functions/`. Key scheduled jobs:

| Function | Schedule | Purpose |
| --- | --- | --- |
| `aggregateLearningAnalytics` | `30 0 * * *` | Rolls up raw analytics events into daily summaries |
| `cleanupAnalyticsEvents` | `0 3 * * *` | Prunes detailed analytics events older than 90 days, expired rate-limit records, and translation-cache entries (90-day retention) |
| `backupCollections` | `0 4 * * 0` | Weekly JSON backup of core content to `admin_backups` bucket (12-file rolling retention) |

Event-driven functions handle gamification (`getUserGamificationSummary`, `recordMistake`, `markMistakeMastered`, `completeMistakeReview`), account lifecycle (`delete-account`), admin operations (`admin-maintenance`, `manageAdminAccess`), translation (`translate`, `translator`), Bakhed progress (`recordBakhedProgress`), and public Binti Guru waitlist signups (`bintiWaitlist` — validated, rate-limited per caller and phone, deduplicated; the collection has no public write access).

### Version Pinning & Governance Exceptions

- **`functions/translator/`**: Intentionally version-frozen on `node-appwrite: 25.1.0` due to upstream removal of `account.createJWT` in `node-appwrite` 28.0.0. Excluded from automated Dependabot updates and governed by `scripts/verify_node_dependency_alignment.mjs`. See [functions/translator/README.md](functions/translator/README.md) for full context and revisit criteria.
