# Olitun System Architecture

High-level architecture, module boundaries, state management, offline storage, and security invariants for the Olitun learning platform.

---

## 1. System Overview

Olitun is an offline-first learning platform for Santali and Ol Chiki, supporting Android, Desktop, and Flutter Web with Appwrite Backend-as-a-Service and serverless functions.

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│        Flutter Widgets • Riverpod Notifiers • GoRouter      │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                           │
│        Entities • Use Cases • Repository Interfaces         │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                            │
│  Repository Implementations • SWR Caching • Local & Remote  │
├──────────────────────────────┬──────────────────────────────┤
│      Remote DataSources      │       Local DataSources      │
│   • Appwrite SDK Client      │   • Hive Content Cache       │
│   • Serverless Functions     │   • Durable Mutation Outbox  │
│   • Razorpay Web Checkout    │   • SharedPreferences        │
└──────────────────────────────┴──────────────────────────────┘
```

---

## 2. Architectural Invariants & Non-Negotiables

1. **Fail-Closed Security:** Authorization checks, payment webhooks, rate limiting, and account deletion flows must unconditionally fail closed.
2. **True Stale-While-Revalidate (SWR):** Downloaded learning content is never deleted due to TTL expiration. Expired TTL triggers non-blocking background revalidation while serving cached lessons immediately.
3. **Zero Secrets in Client:** No privileged Appwrite API keys, admin secrets, or payment credentials exist in the client application. Admin access is verified server-side against immutable team IDs.
4. **Privacy-Preserving Telemetry:** All log messages, diagnostic breadcrumbs, and Sentry reports pass through `RedactionHelper` to sanitize emails, JWTs, secrets, and raw IP addresses.
