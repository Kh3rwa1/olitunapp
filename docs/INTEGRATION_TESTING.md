# Olitun Integration & End-to-End Testing Guide

## 1. Overview

Olitun uses Flutter's native `integration_test` package (`package:integration_test/integration_test.dart`) to validate complete end-to-end user journeys across mobile and web targets without mocks.

---

## 2. Integration Test Suites

| Test File | Target Platform | User Flow Covered |
| :--- | :--- | :--- |
| `integration_test/auth_flow_test.dart` | Web & Mobile | Guest onboarding, OAuth/OTP session persistence, logout, guest transition. |
| `integration_test/quiz_flow_test.dart` | Web & Mobile | Ol Chiki quiz catalog loading, option selection, score calculation, completion screen. |
| `integration_test/legal_smoke_test.dart` | Web & Mobile | Privacy policy dialog, data retention terms, translation disclosure visibility. |

---

## 3. Running Integration Tests Locally

### A. Web Target (Headless Chrome)
```bash
# 1. Start chromedriver
chromedriver --port=4444 &

# 2. Run web integration tests
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart \
  -d chrome
```

### B. Android Target (Emulator / Connected Device)
```bash
flutter test integration_test/quiz_flow_test.dart -d <device_id>
```

---

## 4. CI Integration Pipeline Configuration

In GitHub Actions (`.github/workflows/`), integration tests run against headless Web and Android emulators before merging to `main` and releasing:
1. `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<suite>.dart -d web-server`
2. Release Gate validates that static analysis, unit tests, widget tests, coverage thresholds, and release artifact verification all succeed before any artifact deployment.
