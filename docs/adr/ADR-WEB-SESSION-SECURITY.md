# ADR: Web Session and OAuth Security Architecture

## Status
Accepted & Hardened

## Date
2026-08-20

## Context & Threat Model
In Flutter Web applications using Backend-as-a-Service (Appwrite), OAuth authentication redirects back to the web origin with temporary tokens in query parameters (such as userId, key, and secret). 

Key security risks:
1. **URL Credential Leakage:** Sensitive session tokens appearing in browser URL bars can leak via HTTP Referrer headers, browser history, screenshots, Sentry breadcrumbs, or network proxy logs.
2. **Open Redirect Attacks:** Malicious actors manipulating redirect parameters can bounce users to attacker-controlled origins.
3. **Session Hijacking / XSS Storage Risks:** Storing long-lived unmasked session secrets in browser storage exposes tokens to arbitrary scripts executing in the same origin.
4. **Offline Logout Trapping:** Users offline attempting to sign out must not be trapped in a logged-in UI state if the backend network is unreachable.

## Architecture & Security Invariants

### 1. Zero-Leak URL Scrubbing
- Upon receiving OAuth redirect parameters in the Flutter Web app, OAuthSanitizer.sanitizeUrlHistory() immediately executes HTML5 window.history.replaceState() to scrub userId, secret, and token from the browser address bar before any secondary network requests, analytics events, or asset fetches take place.

### 2. Strict Origin and Redirect Validation
- All redirects are validated against canonical path allowlists (/, /welcome, /onboarding, /categories, /profile, /admin).
- Any ambiguous, protocol-relative, backslash-escaped, or external URL is unconditionally rejected and defaulted to /.

### 3. Fail-Closed Session Validation
- Web sessions are verified with strict 24-hour expiration envelopes. If session metadata is missing, corrupt, or expired, SessionPersistence.restoreWebSession() fails closed, clears all local state, and sets an empty session on the client.

### 4. Local-First Offline Logout
- When a user logs out while offline, AppwriteAuthService.signOut() clears all local SharedPreferences and Hive storage immediately, allowing the UI to transition cleanly to the unauthenticated state without trapping the user due to network errors.

### 5. Content Security Policy (CSP) and Edge Headers
- HSTS enforced (Strict-Transport-Security: max-age=63072000; includeSubDomains; preload).
- Obsolete X-XSS-Protection removed; modern CSP restricts scripts, connect-src, and frame ancestors.
