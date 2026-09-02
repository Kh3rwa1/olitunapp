# ADR: Secure Web Session Storage Architecture

## Status
Accepted / Hardened

## Context
In Flutter Web applications, authentication session tokens or fallback secrets are frequently stored in browser storage (`localStorage`, `IndexedDB`, or `SharedPreferences` web backing store). 

However, any data stored in `localStorage` or `IndexedDB` is directly readable by any JavaScript code running in the same browser context (including third-party analytics, embedded widgets, or XSS payloads). Encrypting `localStorage` via Web Crypto with a key embedded or generated within the client JS runtime provides no cryptographic protection against XSS, because an attacker capable of reading storage can also inspect the JS memory space or extract the decryption key.

## Options Evaluated

### 1. Official Appwrite First-Party Browser Cookie Session
- **Pros**: Uses native Appwrite Web SDK session handling with browser-managed cookies (`HttpOnly`, `SameSite=Strict`, `Secure`) when hosted on the same domain or custom parent domain (e.g., `app.olitun.in` and `api.olitun.in`).
- **Cons**: Requires custom domain setup in production Appwrite Console.
- **Verdict**: **Accepted (Primary Production Standard)**.

### 2. Backend-for-Frontend (BFF) Session Broker
- **Pros**: Serverless proxy function manages Appwrite JWT / session tokens and exposes HttpOnly, Secure, SameSite=Strict cookies to the Flutter web frontend.
- **Cons**: Requires additional proxy function layer.
- **Verdict**: **Accepted (Staging & Proxy Fallback)**.

### 3. In-Memory Session Storage
- **Pros**: Zero raw tokens written to disk or browser storage.
- **Cons**: Page refresh requires background token exchange or reauthentication.
- **Verdict**: **Accepted (Fallback Mode)**.

### 4. Client-side LocalStorage Web Crypto Encryption
- **Pros**: Obfuscates plain text in DevTools.
- **Cons**: Security through obscurity. Key lives in the same JS execution runtime context.
- **Verdict**: **Rejected**.

## Architecture & Enforcement Rules

1. **Zero Storage Persistence**: The Flutter Web client shall never store unmasked Appwrite session secrets or API keys in `localStorage`, `IndexedDB`, or `SharedPreferences`.
2. **Immediate URL Sanitization**: OAuth callback handlers in Flutter web must sanitize and strip `secret`, `key`, and token query parameters from browser history immediately via HTML5 `history.replaceState` or GoRouter location updates.
3. **Fail-Closed Expiration**: Any session missing a valid 24-hour timestamp must call `_client.setSession('')` immediately and invalidate local state.
4. **No Administrative Keys**: Appwrite server API keys with administrative scopes must never be bundled or sent to client builds.
