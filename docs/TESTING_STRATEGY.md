# Testing Strategy & Quality Standards

Documents the testing pyramid, automated CI workflows, and verification layers across Olitun.

---

## 1. Testing Pyramid & Verification Layers

| Layer | Target Area | Tooling | Guarantees |
|---|---|---|---|
| **Unit Tests** | Domain entities, pure helpers, redaction, security | Flutter Test & Node Test | Deterministic correctness, edge cases, zero side-effects |
| **Widget Tests** | Screen rendering, state transitions, user interactions | Flutter Test WidgetTester | Responsive UI, error handling, accessibility semantics |
| **Golden Tests** | Visual regression, typography, dark/light themes | `matchesGoldenFile` with real bundled fonts + tolerant comparator | Pixel-perfect visual stability across releases |
| **Contract Tests** | Appwrite schemas, JSON serializers, error mapping | Schema validators & Mocks | Zero client/server contract drift |
| **Integration / Flow** | Guest flow, onboarding, offline-to-online sync | Flutter Test & Riverpod Overrides | End-to-end user journeys without backend dependencies |
| **Backend Integration** | Payment idempotency, rate limiting, deletion queue | Node `--test` Suites | Fail-closed transactions, race condition immunity |
| **Secret Scanning** | Credentials, session tokens, API keys | Gitleaks Action & Custom Rules | Zero secret leaks in commit history |
| **Accessibility Audits** | WCAG 2.2 AA contrast, 200% text scale, motion | `WcagAudit` & Semantics tests | Fully accessible learning experience |

---

## 2. CI Quality Gates

Every pull request and push to `main` must pass:
1. `flutter analyze --fatal-infos` (Zero warnings/infos).
2. `dart format --output=none --set-exit-if-changed .` (Strict formatting).
3. `dart run tool/verify_version_consistency.dart` (Version parity).
4. `flutter test --coverage` (Passing unit/widget/golden tests).
5. `npm test` (Passing serverless function integration tests + Gitleaks scan).
