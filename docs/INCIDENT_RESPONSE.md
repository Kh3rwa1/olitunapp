# Incident Response & Escalation Plan

This document defines the emergency procedures for security incidents, payment anomalies, and data integrity issues.

---

## 1. Incident Severity Levels

- **SEV-1 (Critical)**: Active breach, unauthorized data exposure, payment double-charging, or total system outage.
- **SEV-2 (High)**: Staging environment failure, degraded payment processing, or partial data synchronization failure.
- **SEV-3 (Medium)**: Non-blocking UI defect, localized translation anomaly, or minor performance degradation.

---

## 2. Response Procedures

### Payment Anomaly Protocol
1. Disable client purchase UI via remote configuration flags if unauthorized charges are detected.
2. Inspect `functions/razorpayWebhook` execution logs and Appwrite `payment_claims` / `refund_claims` collections.
3. Verify signature logs and run manual reconciliation via `node --test functions/test/payment_functions.test.js`.

### Security / Access Breach Protocol
1. Revoke affected Appwrite API Keys in Appwrite Console immediately.
2. Rotate `RAZORPAY_KEY_SECRET` and `RAZORPAY_WEBHOOK_SECRET` in Appwrite Function settings.
3. Invalidate compromised user sessions using `users.deleteSessions(userId)`.
