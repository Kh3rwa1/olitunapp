# Olitun Translate — Appwrite Function

Replaces the PHP proxy at `olitun.in/admin-panel/api/v1/translate.php`.

## Deploy

1. In Appwrite Console → Functions → Create Function:
   - **Runtime:** Dart 3.0
   - **Entrypoint:** `lib/main.dart`
   - **HTTP method:** POST

2. Or via CLI:
```bash
cd functions/translate
appwrite functions createDeployment \
  --functionId=translate \
  --entrypoint=lib/main.dart \
  --code=.
```

3. Update the Flutter app to point to the new endpoint:
```dart
// In lib/core/api/ai_service.dart, change AiConfig:
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://sgp.cloud.appwrite.io/v1/functions/translate/executions',
);
```

## API Contract

**Request:** `POST` with JSON body:
```json
{ "text": "Hello", "from": "auto", "to": "sat" }
```

**Response:**
```json
{
  "success": true,
  "data": {
    "translation": "ᱡᱚᱦᱟᱨ",
    "detectedLanguage": "en",
    "from": "auto",
    "to": "sat",
    "cached": false
  }
}
```

Same contract as `translate.php` — no client changes needed beyond the URL.
