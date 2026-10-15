# Architecture

Olitun follows **Clean Architecture** with feature-first module organization.

## Layer Diagram

```
┌─────────────────────────────────────────────────────┐
│                    Presentation                      │
│  ConsumerWidget → AsyncValue.when → Widget tree      │
├─────────────────────────────────────────────────────┤
│                    Providers (Riverpod)               │
│  AsyncNotifier / Notifier / FutureProvider           │
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
├── main.dart
├── app/
│   ├── router/                  # GoRouter config, route guards, deferred admin loader
│   └── sync/                    # ContentRealtimeSync (realtime → cache/provider invalidation)
├── core/                        # App-agnostic infrastructure + design system
│   ├── api/                     # AppwriteDbService, AppwriteFunctionsService,
│   │                            #   RealtimeChangeFeed, DbQuery, ContentRemoteDataSource
│   ├── auth/                    # AppwriteAuthService (singleton), session helpers,
│   │                            #   AuthRepository + auth/current-user providers
│   ├── config/                  # AppwriteConfig (build-time validation), remote app settings
│   ├── error/                   # Sealed Failure + Exception classes, error classifier
│   ├── logging/ observability/  # AppLogger (Sentry forwarding), CrashReporting
│   ├── offline/                 # MutationOutboxService (generic durable write queue)
│   ├── storage/                 # CacheService (Hive), HiveService (init)
│   ├── network/ payments/ ads/ analytics/ audio/ media/ notifications/ …
│   ├── motion/                  # Motion primitives (PressableScale, AnimatedCounter…)
│   ├── presentation/            # Layout + animation primitives (ResponsiveLayout…)
│   └── theme/                   # AppTheme, AppColors, AdminTokens
├── features/
│   ├── admin/                   # CMS (deferred load unit, see "Admin CMS" below)
│   │   ├── admin_screens.dart   #   the only library the router imports (deferred)
│   │   ├── data/                #   AdminAuthService, BakhedRepository (Appwrite)
│   │   ├── domain/ presentation/ providers/
│   ├── ai_studio/ auth/ categories/ content/ home/ learn/ legal/ lessons/
│   ├── main/ onboarding/ practice/ profile/ quiz/ review/ rhymes/ voice/
│   │                            # each: data/ (SDK impls + di/), domain/, presentation/
└── shared/                      # Cross-feature, content-aware code
    ├── media/                   # MediaUploader (content-aware upload pipeline)
    ├── models/                  # Content DTOs (ContentItem, *Model); catalog/ holds
    │                            #   Category/Lesson/Rhyme entities + models
    ├── providers/               # Cross-feature providers (content lists, banners,
    │                            #   waitlist, language/local settings…)
    ├── quiz_engine/             # Dynamic quiz compilation
    ├── repositories/            # ContentRepository (seed + Hive + remote) and
    │                            #   ContentMutationReplay (drains the outbox)
    ├── security/ utils/
    └── widgets/                 # Reusable UI components (shimmer, buttons, media…)
```

### Layering rule: core vs shared vs features

- **`core/`** is app-agnostic infrastructure and design-system primitives. It
  must not import `shared/` or `features/`. Generic mechanisms live here (e.g.
  the mutation outbox, auth session providers, reduce-motion state, the
  playback controller). When core needs feature behaviour, invert it with a
  small provider the app root overrides (e.g. `rewardStarsGranterProvider`).
- **`shared/`** is code reused by several features that *knows about Olitun
  content* (models, content repository, cross-feature providers, widgets).
  It may import `core/` but never `features/`. Content-specific offline logic
  (outbox replay) lives beside the repository it drives in
  `shared/repositories/`. The `shared/providers/providers.dart` barrel only
  re-exports core/shared providers; import feature providers directly.
- **`features/<name>/`** own their screens and data. A feature may import
  `core/`, `shared/`, and another feature's `domain/`/`data/`. A feature's
  `data/`/`domain/` code must never import another feature's `presentation/`
  (presentation → presentation is tolerated but should be rare).
- **`app/`** is the composition root (router, app-wide sync orchestration) and
  may import anything; `main.dart` wires root provider overrides.
- Reusable widgets go in `shared/widgets/`; `core/motion/` and
  `core/presentation/` hold only low-level motion/layout primitives.

## SDK Isolation Rule

`package:appwrite` may only be imported from `lib/core/**` and
`lib/features/*/data/**`. Everything else — presentation, domain,
`lib/shared/**`, `lib/app/**`, feature `providers/` — consumes SDK
capabilities exclusively through these anti-corruption seams:

| Seam | Location | Purpose |
| --- | --- | --- |
| `AppwriteFunctionsService` | `core/api/appwrite_functions_service.dart` | Legacy function ids mapped to Cloudflare Worker routes; returns neutral `FunctionExecutionResult` |
| `ContentRemoteDataSource` | `core/api/content_remote_datasource.dart` | Remote content reads + admin CRUD, served by the Cloudflare Worker (D1) |
| `AppwriteErrorClassifier` | `core/error/appwrite_error_classifier.dart` | Exception → neutral error-info mapping (e.g. 404 detection) |
| `data/di/*.dart` | `features/*/data/di/` | Datasource/repository provider wiring beside the impls it constructs |

Appwrite is used **only for authentication** (Account, sessions, JWT,
OAuth, Teams for the admin check). Content, storage, functions and change
feeds all go to the Cloudflare Worker; `scripts/check_appwrite_auth_only.mjs`
fails CI on any Appwrite TablesDB/Databases/Storage/Realtime/Functions usage
in `lib/`.

### Boundary Enforcement

Architecture boundaries are validated in CI (`.github/workflows/flutter-ci.yml`) via:
```bash
node scripts/check_architecture_boundaries.mjs
```
It scans **every** Dart file under `lib/` and fails on any `package:appwrite`
import/export outside `lib/core/**` and `lib/features/*/data/**`, on any
`lib/core/**` import of `lib/shared/**` or `lib/features/**`, on any
`lib/shared/**` import of `lib/features/**`, and on feature `data/`/`domain/`
code importing another feature's `presentation/` (URIs are resolved, so
relative, `package:` and conditional imports are all covered). The allow-list
in the script is empty; `scripts/check_architecture_boundaries.test.mjs`
covers the checker itself.

## Quality Gates

CI (`.github/workflows/flutter-ci.yml`) enforces repository standards on every PR:

| Gate | Command | Enforces |
| --- | --- | --- |
| File length | `node scripts/check_file_length.mjs` | Hand-written Dart files ≤ 600 lines (no grandfathered files) |
| Localization parity | `node scripts/check_l10n_parity.mjs` | All ARB locales share the same keys and placeholder signatures |
| Hardcoded strings | `node scripts/check_hardcoded_strings.mjs` | No user-facing `Text`/`Toast` literals outside `lib/features/admin/**` (grandfathered baseline in `scripts/hardcoded_strings_baseline.json`) |
| Architecture boundaries | `node scripts/check_architecture_boundaries.mjs` | `package:appwrite` only in `lib/core/**` and `lib/features/*/data/**`; core ↛ shared/features; shared ↛ features; feature data/domain ↛ other features' presentation |
| Appwrite deployability | `node scripts/check_appwrite_deployable.mjs` | Sites use `scripts/build_web.sh` and do not ignore `scripts/` |
| Appwrite manifest parity | `node scripts/verify_function_deployment.mjs` | `appwrite.json` and `appwrite.config.json` agree on functions, buckets, sites, and projectId; least-privilege scope checks |
| Function packaging smoke | `node scripts/smoke_package_functions.mjs` | Each function has `package.json`, lockfile, entrypoint, and a syntax-valid entry |
| Format + analyze | `dart format`, `flutter analyze --fatal-infos` | Style and static analysis clean |
| riverpod_lint | `dart run custom_lint` | Configured with the 14 rules riverpod_lint 2.6 ships; currently inert because riverpod_lint 2.x (analyzer ^7) cannot parse the SDK's dot-shorthand syntax — see `analysis_options.yaml` |

Regenerate the hardcoded-string baseline only after intentional localized changes:

```bash
node scripts/check_hardcoded_strings.mjs --json > scripts/hardcoded_strings_baseline.json
```

### Localization

- Source of truth: `lib/l10n/arb/app_en.arb` (template) with `sat` (Ol Chiki), `hi`, `bn`, `or`.
- Generated bindings: `lib/l10n/generated/` via `flutter gen-l10n` (`l10n.yaml`).
- UI always resolves strings with `AppLocalizations.of(context)!`; tests must provide
  `AppLocalizations.localizationsDelegates` in their `MaterialApp`.
- Where a screen needs uppercase UI chrome but ARB keeps title/sentence case for other
  call sites, apply `.toUpperCase()` at the call site (non-Latin scripts are unaffected).

### AI Studio presentation layout

`lib/features/ai_studio/presentation/ai_studio_screen.dart` is the library entry and holds
the state class, core session logic, and `build`. UI sections live in same-library part
files exposed as extensions on `_AiStudioScreenState` so private state stays shared while
each file stays under the 600-line cap:

- `ai_studio_status.dart` — live status, pulse, waveform, auto pill
- `ai_studio_layout.dart` — atmosphere, app bar, tool switcher, viewport bodies, notice
- `ai_studio_input.dart` / `ai_studio_input_tools.dart` — input panel and tool forms
- `ai_studio_result.dart` — result panel and editor

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
locally and queued in the `MutationOutboxService` (`core/offline/`, dedicated
Hive box with bounded exponential backoff and dead-lettering). The
`ContentMutationReplay` service (`shared/repositories/`) drains the queue at
startup and whenever connectivity is regained.

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

All state flows through **Riverpod 2** (hand-written providers, no codegen):
- `SharedPreferences` → injected via `sharedPreferencesProvider` override at root `ProviderScope`
- Async data → `AsyncNotifier` / `FutureProvider`. `build()` performs the IO
  directly (`await` inside `build`), so loading/error/data come from
  Riverpod. Cache-first notifiers may set `state = AsyncData(cached)` after
  an `await` while the network request is in flight, guarded by a per-build
  flag registered with `ref.onDispose`. Mutations write remotely, then
  `ref.invalidateSelf(); await future;`.
- Do **not** model async data as `Notifier<AsyncValue<T>>` that starts IO via
  `Future.microtask` in `build()` with manual `_disposed` flags.
- Non-`AsyncValue` controller state (e.g. admin purchases/settings/access)
  uses `Notifier<T>`: `build()` returns a loading state and starts a fetch
  that does not touch `state` before its first `await`; stale responses are
  dropped with a request-generation counter that `ref.onDispose` bumps.
- `StateProvider` → simple UI state (theme mode, tab index)

## Admin CMS (deferred)

`lib/features/admin` is ~40% of the presentation code but only used by
admins. The router imports it exclusively through
`features/admin/admin_screens.dart` as a `deferred as admin` library;
every admin route builder wraps its screen in `DeferredRoute`
(`app/router/deferred_route.dart`), which calls `loadLibrary()` once and
shows a progress indicator meanwhile. On web this keeps the CMS out of the
learner's initial `main.dart.js`. Do not import admin presentation code from
any eagerly-loaded library; admin auth (`features/admin/providers`,
`features/admin/data`) is small and stays eager for the route guard.

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
| `cleanupAnalyticsEvents` | `0 3 * * *` | Prunes detailed analytics events (90d), expired rate-limits, translation-cache (90d), AI Studio inputs (24h), AI Studio jobs (30d), audio TTS cache (90d + storage cleanup), and voice claims (7d) |
| `backupCollections` | `0 4 * * 0` | Weekly JSON backup of core content to `admin_backups` bucket (12-file rolling retention) |

Event-driven functions handle gamification (`getUserGamificationSummary`, `recordMistake`, `markMistakeMastered`, `completeMistakeReview`), account lifecycle (`delete-account`), admin operations (`admin-maintenance`, `manageAdminAccess`), translation (`translate`, `translator`), voice synthesis (`santaliVoice`), Bakhed progress (`recordBakhedProgress`), and public Binti Guru waitlist signups (`bintiWaitlist` — validated, rate-limited per caller and phone, deduplicated; the collection has no public write access).

### Version Pinning & Governance Exceptions

- **`functions/translator/`**: Intentionally version-frozen on `node-appwrite: 25.1.0` due to upstream removal of `account.createJWT` in `node-appwrite` 28.0.0. Excluded from automated Dependabot updates and governed by `scripts/verify_node_dependency_alignment.mjs`. See [functions/translator/README.md](functions/translator/README.md) for full context and revisit criteria.

## Learner-State Authority (forensic hardening)

Single documented source of truth per state — see
[docs/architecture/learner_state_authority.md](docs/architecture/learner_state_authority.md):

- **Review/SRS mastery**: `ReviewStore` locally (one `ReviewStateLocalRepository`
  persistence boundary, account-scoped keys, pure in-memory transitions +
  explicit durability), `review_states` snapshot rows + `review_operations`
  idempotency ledger remotely. One stable recall operation per answered
  question; snapshot merge is the backward-compatible read path only (never
  last-writer-wins for evidence).
- **Mistake history**: append-only per-account audit. The live recovery queue
  is DERIVED from SRS via the explicit recovery criterion (new successes
  after record time). Review state is never "mastered".
- **Quiz identity**: exactly-one verified corpus attribution or explicit
  non-memory, enforced at domain, admin, repository, CI, and runtime layers.
- **Guest/legacy migration**: receipted state machine (`prepared/applied/
  sourceCleared/completed/failed`), claim-once legacy ownership, quarantined
  ambiguity.
- **Rewards/analytics**: server-authoritative totals with idempotent origin
  keys; analytics events are never product authority.

Sync, persistence, quota, and rollback details:
[docs/architecture/review_persistence_and_sync.md](docs/architecture/review_persistence_and_sync.md).
