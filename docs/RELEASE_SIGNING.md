# Olitun Release Signing & Security Policy

## 1. Fail-Closed Release Signing Architecture

Olitun implements a strict fail-closed signing model in `android/app/build.gradle.kts` to prevent accidental distribution of unsigned or debug-signed binaries to production channels.

---

## 2. Signing Modes

### 1. Production Release Mode (Default)
- **Requirements:** A valid `android/key.properties` file must be present and contain:
  - `keyAlias`: Secret alias identifying the upload key in the keystore.
  - `keyPassword`: Password for the key.
  - `storeFile`: Path to the `.jks` or `.keystore` keystore file.
  - `storePassword`: Password for the keystore.
- **Fail-Closed Behavior:** If `key.properties` is missing, incomplete, or unreadable, the build **fails immediately** with a descriptive `GradleException`. Under no circumstances will a production release build silently fall back to debug signing.

### 2. CI / Build Verification Mode (Explicit Opt-In)
- **Requirements:** Used strictly in automated CI pipelines (e.g. `flutter-ci.yml`) to verify that the release artifact compilation, code shrinking (R8 / Proguard), and resource shrinking succeed without needing access to private production signing keys.
- **Enabling Verification Mode:**
  - Pass the Gradle property: `-PallowDebugReleaseSigning=true`
  - Or set the environment variable: `ALLOW_DEBUG_RELEASE_SIGNING=true`
- **Artifact Labeling:** In CI pipelines, release verification artifacts produced under this mode must be labeled explicitly as `android-release-verification-debug-signed` or similar, never published to Google Play or distributed to end users.

---

## 3. Secret Management in GitHub Actions

For production releases:
- The base64-encoded keystore is stored in GitHub Actions Secret `ANDROID_KEYSTORE_BASE64`.
- Keystore credentials are stored in `KEY_ALIAS`, `KEY_PASSWORD`, and `KEYSTORE_PASSWORD`.
- The release pipeline decodes the keystore temporarily in the runner workspace, generates `key.properties`, executes the release build, and securely purges the key files upon completion.
