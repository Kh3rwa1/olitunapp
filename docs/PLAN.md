# PLAN: Production Deployment (Web & Mobile)

## Task
Deploy the "AAA+" Themed AI Translator and the refined "Practice Writing" corner-icon UI to both the live PWA (olitun.in) and the production mobile app.

## Target Platforms
1. **Web (PWA)**: Build and package for `olitun.in`.
2. **Mobile**: Build production APK/AAB for Android.

## Proposed Changes & Orchestration

### PHASE 1: PLANNING
- [project-planner] Create this deployment plan.

### PHASE 2: IMPLEMENTATION (After Approval)
- [devops-engineer]
    - Build Flutter Web for release (`--renderer canvaskit`).
    - Perform cache-busting on `index.html` (Version 8).
    - Package the build into `build_web_v8.zip`.
- [mobile-developer]
    - Build production APK (`flutter build apk --release`).
    - Build production AAB (`flutter build appbundle --release`).
- [test-engineer]
    - Verify the integrity of the zip package.
    - Confirm the presence of APK and AAB artifacts in the `build/app/outputs/flutter-apk` and `build/app/outputs/bundle` directories.

## Verification
- Final check of the versioned `index.html`.
- List all generated build artifacts.

---

✅ Plan oluşturuldu: docs/PLAN.md

Onaylıyor musunuz? (Y/N)
- Y: Implementation başlatılır
- N: Planı düzeltirim
