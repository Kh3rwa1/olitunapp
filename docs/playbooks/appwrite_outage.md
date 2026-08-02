# Operational Playbook: Appwrite Service Outage Recovery

## Trigger Conditions
- High API error rate (>5% failed HTTP calls to Appwrite endpoint).
- Client app throwing connection timeouts or 5xx server errors on authentication/database fetch.

## Incident Response Steps
1. **Assess Severity & Status**:
   - Check Appwrite Cloud Status page or self-hosted server health (`/v1/health`).
   - Check error monitoring telemetry for spike in network exceptions.
2. **Enable Degradation Mode**:
   - Verify client app falls back to local cache (`StaleWhileRevalidateRepository` & Hive cache).
   - Read-only learning features continue using cached lessons and local progress outbox.
3. **Notify Users**:
   - Display non-intrusive offline banner: *"Experiencing temporary connection issues. Your learning progress is saved locally."*
4. **Post-Recovery Verification**:
   - Once Appwrite connectivity is restored, verify `MutationOutboxService` automatically flushes queued progress.
   - Run verification query on Appwrite console to confirm database document writes resume normally.
