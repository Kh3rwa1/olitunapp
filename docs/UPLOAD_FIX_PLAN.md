# Orchestration Plan: Fixing Admin Panel File Uploads

File uploads are currently failing because of hardcoded `localhost` endpoints in the service layer and simulated logic in some admin screens. This plan standardizes media handling across the entire admin panel.

## User Review Required

> [!IMPORTANT]
> **Endpoint Clarification**: The current service (`HostingerUploadService`) is hardcoded to `http://localhost:8080`. We need the actual production URL for your PHP backend to make this work on web/Vercel.
> 
> **Supabase vs Hostinger**: The code uses "Supabase" names but connects to a PHP API. We will stick with the PHP API but move the URL to a configurable constant.

## Proposed Changes

### 1. Service Layer Hardening (backend-specialist)
- **lib/core/storage/supabase_service.dart**: 
  - Update `AppConfig.apiBaseUrl` to be configurable.
  - Improve error reporting in `uploadMedia` to show toast/snackbars with specific HTTP error codes.

### 2. Real Integration in Media Library (frontend-specialist)
- **lib/features/admin/presentation/admin_media_screen.dart**:
  - Replace simulation logic with real calls to `uploadServiceProvider`.
  - Ensure `MediaItem` reflects the actual returned URL from the server.

### 3. Audio/Image Upload Sync (debugger)
- **AdminNumbersScreen** & **AdminWordsScreen**: 
  - Verify that `pickAudio` and `pickImage` both use the same robust service logic.
  - Implement a global `UploadProgressOverlay` or similar to show actual progress.

## Verification Plan

### Automated Tests
- `flutter analyze`: Ensure no regression in lints.
- Run a script to check if the `apiBaseUrl` is reachable (if possible).

### Manual Verification
- Test image upload in **Categories**.
- Test audio/image upload in **Numbers**.
- Verify that uploaded items appear in the **Media Library**.
