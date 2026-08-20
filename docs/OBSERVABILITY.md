# Observability, Logging & Error Taxonomy

Olitun implements a comprehensive telemetry and error-tracking system designed for privacy, resilience, and actionable debugging across mobile, web, and serverless environments.

---

## 1. Zero-PII Log Redaction Architecture

All text logs, diagnostic breadcrumbs, and Sentry crash reports are pre-filtered through \`RedactionHelper\` before emission.

### Redaction Rules

| Sensitive Category | Detection Pattern | Redaction Output |
|---|---|---|
| **Email Addresses** | User and domain emails | \`u***@domain.com\` |
| **Passwords / Secrets** | \`password=...\`, \`apiKey=...\`, JSON keys | \`password=[REDACTED]\` |
| **Session Secrets** | \`a_session_*\`, \`key_secret=*\` | \`[REDACTED_SESSION_SECRET]\` |
| **JWT Tokens** | \`eyJ...\` standard JWT envelopes | \`[REDACTED_JWT]\` |
| **Payment Secrets** | \`rzp_live_*\`, \`rzp_test_*\` | \`[REDACTED_PAYMENT_KEY]\` |
| **IPv4 Addresses** | Direct client or server IPv4 addresses | \`[REDACTED_IP]\` |
| **Translation Text** | Raw user translation inputs/outputs | Privacy-hashed SHA-256 cache keys |

---

## 2. Sentry Error Taxonomy & Offline De-escalation

To prevent alert fatigue and distinguish routine offline transitions from software defects:

```
                     App Error / Exception
                              │
               ┌──────────────┴──────────────┐
               ▼                             ▼
       Expected Transition           Actionable Defect
    (Network/Offline/Timeout)    (Logic/Auth/Parsing/500s)
               │                             │
       ┌───────┴───────┐                     ▼
       ▼               ▼            High Priority Alert
Logged as Debug  Cached Content      Recorded to Sentry
  Breadcrumb     Displayed (SWR)     with Stack Trace
```

1. **Network / Offline Transitions:**
   - `SocketException`, offline HTTP failures, and background revalidation timeouts are recorded as low-severity debug breadcrumbs and do not trigger alert pages.
2. **Permission / Authentication Failures:**
   - Explicit `401 Unauthorized` or `403 Forbidden` responses are logged as warning breadcrumbs and route user to graceful login or re-authentication flows.
3. **Unexpected Server & Client Crashes:**
   - Unhandled exceptions within Flutter error zones or serverless 500 errors are dispatched immediately with breadcrumbs, device state metadata, and sanitized stack traces.
