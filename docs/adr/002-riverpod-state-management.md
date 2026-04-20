# ADR-002: Riverpod for State Management

**Status:** Accepted
**Date:** 2025-02-15

## Context

Flutter offers multiple state management options: Provider, Riverpod, Bloc, GetX, MobX. The app needs to manage user progress, lesson content, quiz state, authentication, and theme preferences across many screens.

## Decision

Use **Riverpod** (`flutter_riverpod ^2.6.1`) with the `StateNotifier` pattern.

**Reasons:**
- **Compile-safe** — providers are resolved at compile time, no runtime errors
- **Testable** — providers can be overridden in tests without widget tree
- **Modular** — each provider is independent, no single god-state object
- **No BuildContext** — providers accessible anywhere, including services
- **Family support** — parameterized providers for category-specific data

## Consequences

- ✅ Each feature has its own provider file (`progress_provider.dart`, `lessons_provider.dart`, etc.)
- ✅ Easy to test — `UserProgressData` is a plain Dart class with `copyWith`
- ✅ Hot reload works reliably with `ConsumerWidget` / `ConsumerStatefulWidget`
- ⚠️ Learning curve for contributors unfamiliar with Riverpod
- ⚠️ v2 → v3 migration will be needed eventually (non-breaking, additive)
