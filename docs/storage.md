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

## 🛡️ Stale Client Defense Architecture

To prevent storage orphans caused by stale browser caches or edge proxy invalidations, we operate a robust **Three-Layer Caching Defense System**:

| Layer | What it catches | Worst-case window | Failure mode |
|---|---|---|---|
| **Reference Guard (Server)** | All media orphan attempts | 0 ms (Immediate) | **Fail-Safe**: Refuses delete on query/reference match or database check failures |
| **SW Caching Exclusion (Client)** | Cached bootstrap script | Per-resource cache hit | **Fail-Safe**: Bypasses service worker cache, forcing network fetch |
| **SHA Mismatch Detector (Client UX)** | Stale code path in active browser tabs | 5 min (polling) + edge TTL | **Fail-Open**: Bypasses dialog warnings, allowing normal CMS operations |

For deployment contracts and edge cache timing constraints, see [docs/web_deployment.md](file:///Users/dulorai/olitun/olitunapp/docs/web_deployment.md).

---

## 🎬 Cover Media Bucket Strategy

To support beautiful image and video covers for rhymes, we utilize a dual-bucket strategy:
1. **Images Bucket (`images`):** Used for standard static image covers.
2. **Cover Videos Bucket (`cover_videos`):** Dedicated to premium autoplaying loop video covers.

### Bucket Configurations & Constraints

| Bucket | Purpose | Max Size | Allowed Extensions | Permissions |
|---|---|---|---|---|
| **`images`** | Image covers, icons, static assets | 10 MB | `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif` | `read("any")` / Admin write |
| **`cover_videos`** | Autoplay video cover loops | 10 MB | `.mp4`, `.webm`, `.mov` | `read("any")` / Admin write |

### Discriminator and Media Mapping
All cover assignments are stored in the `rhymes` database collection under a single model property:
- **`coverMediaType`:** Enum field (`"image"` or `"video"`) that designates the active cover type.
- **`hero_media` / `heroMedia`:** A nested JSON object storing the media `url`, storage `fileId`, and media `kind` (`"image"` or `"video"`).
- **`thumbnailUrl`:** Populated for image-cover rhymes. For video-cover rhymes, `thumbnailUrl` is intentionally set to `null` to avoid passing a video URL to standard background audio notification layouts (which expect static images and fall back to the generic app logo).

---

## 🧪 Testing and Verification

- Unit tests for the synchronous duration prober reside in [media_uploader_duration_test.dart](file:///Users/dulorai/olitun/olitunapp/test/core/storage/media_uploader_duration_test.dart).
- Test suites in `test/features/admin/bakhed/` simulate the canonical picker-controller flow using `notifier.setUploadInProgress` and `notifier.updateAudio` to verify race condition guards.
- Stale client detector stream and HTTP mock tests reside in [build_version_checker_test.dart](file:///Users/dulorai/olitun/olitunapp/test/core/version/build_version_checker_test.dart).
- Widget destructive actions guard and reload dialog verification reside in [media_picker_field_test.dart](file:///Users/dulorai/olitun/olitunapp/test/features/admin/widgets/media_picker_field_test.dart).


