# Production Hardening & Caching Plan

## Goal
Implement SSL Pinning for production, automate asset compression, and enforce robust Hive schema versioning.

## Tasks
- [x] Task 1: Create `lib/core/network/secure_http_overrides.dart` and initialize it in `lib/main.dart` to enforce production SSL/TLS and load ISRG Root CA. → Verify: Running `flutter analyze` returns no warnings.
- [x] Task 2: Create a Python automation script `scripts/compress_assets.py` using Pillow and ffmpeg to optimize PNG and MP4 assets in-place. → Verify: Running the script reports successful compression stats.
- [x] Task 3: Execute the `scripts/compress_assets.py` script. → Verify: File size of `assets/videos/onboarding.mp4` is reduced significantly.
- [x] Task 4: Verify the Hive schema versioning configuration in `lib/core/storage/cache_service.dart`. → Verify: `CacheService.evictStale()` is verified to protect user data (which resides in `SharedPreferences`) while safely invalidating stale Hive boxes.
- [x] Task 5: Run final comprehensive static analysis and test suite. → Verify: `flutter test` executes all 111+ tests successfully with 0 failures.

## Done When
- [x] Production SSL/TLS handshake override is active in the boot sequence.
- [x] Onboarding video and images are compressed and optimized in-place.
- [x] Complete codebase is fully validated with 0 compile errors and 0 test failures.
