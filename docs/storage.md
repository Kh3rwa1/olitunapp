# 📦 Appwrite Storage & Playback Architecture

This document defines the storage configuration, playback mechanics, and canonical media upload pipelines in Olitun.

---

## ⚙️ Audio Bucket Configuration

To support audio playback and previewing across web and mobile:
- **Bucket ID:** `audio`
- **Encryption:** `false` (Disabled)
- **File Security:** `false` (Disabled)
- **Permissions:** `read("any")` (Public read access)
- **Max File Size:** `50MB`
- **Allowed Extensions:** `.mp3`, `.wav`, `.ogg`, `.m4a`, `.aac`

---

## 🔒 Why Storage Encryption is Disabled

Disabling encryption for the `audio` bucket is **not** a security oversight — it is a deliberate and technically required configuration:

1. **Chunked Streaming & Range Requests:** Browsers and native HTML5 audio players rely heavily on HTTP Range requests (`Range: bytes=X-Y`) to enable track seeking, fast-forwarding, and metadata parsing (such as probing the track duration).
2. **Disk-to-Offset Mapping:** When Appwrite storage encryption is enabled (`encryption: true`), Appwrite decrypts the stored file chunks on-the-fly. This causes the physical encrypted size on disk (`sizeActual`) to differ from the original decrypted size (`sizeOriginal`).
3. **Range Failure:** Because of this mismatch, HTTP Range requests cannot be mapped 1:1 directly to byte offsets on the physical storage device. This causes Range requests to fail or return corrupted streams, which in turn causes web and mobile players (like `just_audio` on web) to display `00:00 / 00:00` and locks up seeking.
4. **The Fix:** With encryption disabled, Range requests map 1:1 directly to disk byte offsets. This completely restores flawless duration probing and seek functionality.

> [!WARNING]
> **Do NOT re-enable encryption** on the `audio` bucket without verifying HTML5 audio Range requests and duration probing across Chrome, Safari, and mobile devices.

---

## 🚀 Canonical Upload Flow

All media files must flow through the canonical, in-flight guarded pipeline shown below:

```
User clicks upload in admin
  → MediaPickerField.pickAndUpload()
    → MediaUploader.pickAndUpload()
      → File picked from native/web file picker
      → If audio MIME/extension: _probeAudioDurationMs() runs synchronously
      → File uploaded to Appwrite storage bucket with public read permissions
      → Returns ContentMedia { url, fileId, durationMs }
    → MediaPickerField.onChanged(media) fires
    → Editor controller: updateAudio(url, fileId, durationMs)
    → State has durationMs BEFORE the user can click Save!
```

---

## 🚫 What NOT to Do

- **Do NOT create parallel upload utilities:** If you need to add support for a new feature or bucket, extend `MediaUploader` instead of writing custom upload calls.
- **Do NOT bypass `MediaPickerField` in admin UI:** `MediaPickerField` handles the lifecycle of the in-flight upload, safely reporting upload states to the controller so that saving is blocked while an upload is in progress.
- **Do NOT re-enable bucket encryption** without first testing HTML5 audio Range requests.
- **Do NOT add a `Content-Length` header workaround:** The real fix is keeping Range mapping intact via unencrypted storage.

---

## 🧪 Testing and Verification

- Unit tests for the synchronous duration prober reside in [media_uploader_duration_test.dart](file:///Users/dulorai/olitun/olitunapp/test/core/storage/media_uploader_duration_test.dart).
- Test suites in `test/features/admin/bakhed/` simulate the canonical picker-controller flow using `notifier.setUploadInProgress` and `notifier.updateAudio` to verify race condition guards.
