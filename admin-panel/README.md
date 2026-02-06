# Hostinger Admin Panel Deployment

## Folder Structure
```
public_html/
├── index.html          (Flutter web build)
├── main.dart.js
├── flutter.js
├── manifest.json
├── assets/
├── api/
│   └── upload.php      (Audio upload API)
└── audio/
    ├── letters/        (Letter pronunciations)
    └── lessons/        (Lesson audio)
```

## Deployment Steps

### 1. Build Flutter Web
```bash
cd /Users/dulorai/olitun/olitunapp
flutter build web --release --no-pub -t lib/main_admin.dart
```

### 2. Upload to Hostinger
1. Login to Hostinger hPanel
2. Go to **File Manager** → **public_html**
3. Upload contents of `build/web/` to `public_html/`
4. Upload `api/upload.php` to `public_html/api/`
5. Create `audio/letters/` and `audio/lessons/` folders

### 3. Set Permissions
```
api/upload.php → 644
audio/ → 755 (writable)
```

## Configuration

Update the base URL in Flutter:
- File: `lib/core/config/app_config.dart`
- Set `apiBaseUrl` to your Hostinger domain
