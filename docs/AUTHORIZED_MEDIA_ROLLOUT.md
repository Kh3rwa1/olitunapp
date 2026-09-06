# Authorized private media delivery — protocol v2

## Deployment requirements

- Deploy a token-capable Appwrite server and the pinned `getAuthorizedLesson` SDK dependency. Run the installed-SDK contract test; a root development dependency is not proof that the deployed function supports Tokens.
- Apply the declared `tokens.write` scope to this function only. Keep `paid_media` private with its existing file-security policy. Do not make files/buckets public to fix playback.
- Set `MEDIA_PUBLIC_ENDPOINT` to the same public HTTPS `/v1` endpoint used by the Flutter client's `APPWRITE_ENDPOINT`. Do not use the function's internal Docker endpoint. Configure the same project ID and paid-media bucket on both sides.
- Coordinate client/backend protocol rollout. Old media requests receive 426; the v2 client rejects old base64 responses. Do not deploy half the protocol to production without an upgrade/maintenance plan.

## Security and behavior

The function rechecks lesson entitlement and file association for every grant. It returns only metadata and a bearer Storage URL, with no-store headers; it never downloads/encodes the media bytes. Appwrite Storage handles byte/range delivery. Grants expire within five minutes. Refund/revocation stops new grants; an already-issued grant can remain usable until expiry. This is bounded authorization, not DRM or instant revocation.

Persistent lesson data contains only the lesson, bucket, and file identities. Do not log, cache to disk, put into analytics IDs, or share token URLs. Playback errors must stay sanitized. Private audio, video, raster/SVG images, and self-contained Lottie JSON use native/client renderers; private HTML execution is not enabled by this renderer.

Audio refresh preserves position and reauthorizes on seek/resume. Video refresh preserves position, speed, volume and play state. Failed refresh must not fall back to an old grant. Account changes invalidate media services and players. The server and client must agree on the public endpoint and have reasonably accurate clocks.

## Release acceptance

- Pass retained lesson authorization regressions, v2 grant tests, installed-SDK tests, Flutter media tests, full CI, and Chrome/Android journeys.
- On staging, verify non-buyers, refunded/disputed/revoked users, wrong lessons, wrong buckets, and unrelated file IDs cannot obtain grants.
- Exercise a large video with seek/range requests. Inspect that the function response stays small and contains no base64. Verify actual Storage Range/CORS behavior rather than inferring it from unit tests.
- Let a grant expire while playing and while paused; resume/seek and verify renewal. Revoke access before renewal and verify playback stops without stale fallback.
- Switch accounts and close/reopen screens during resolution/initialization. Verify no old player resumes and no refresh timers survive disposal.
- Exercise representative images, SVG and self-contained Lottie files; malformed/unsupported media must show retry/fallback, not raw credential-bearing errors.
- Inspect browser/native logs, telemetry and local storage for token leakage. Do not include real grant URLs in screenshots or issue comments.

No live deployment, bucket permission change, or production data mutation is performed by this PR.
