# App-Wide Premium Enhancement Plan

## Goal
Transform the app into a buttery-smooth, whimsical, and premium learning experience. This focus is on the "First Contentful Paint" (Splash), the "Introduction" (Onboarding), and the "Global Polish" (Theme & Transitions).

## User Review Required
> [!IMPORTANT]
> - We are introducing a dedicated **Splash Screen** which will add ~1.5s to the initial startup for animation and pre-fetching assets.
> - We will be using **AI-generated illustrations** for onboarding slides to ensure a unique, boutique look.

## Proposed Changes

---

### 🚀 Phase 1: The "Grand Entrance" (Splash & Entry)
**Agents**: `mobile-developer`, `performance-optimizer`

- **[NEW] lib/features/onboarding/presentation/splash_screen.dart**:
  - A beautiful, high-contrast splash screen with a scale/fade-in animation of the Olitun logo.
  - Integration with `flutter_native_splash` or a custom Dart-based splash that handles pre-fetching.
- **[MODIFY] lib/main.dart**:
  - Update `GoRouter` to start at `/splash` and orchestrate the transition to `/onboarding` or `/home`.

---

### 🎨 Phase 2: The "Smooth" Introduction (Onboarding)
**Agents**: `frontend-specialist`, `mobile-developer`

- **[MODIFY] lib/features/onboarding/presentation/onboarding_screen.dart**:
  - Implement a `LiquidSwipe` or `Parallax` PageView transition.
  - Refactor navigation buttons into a "Floating Action Pad" with whimsical animations.
- **[MODIFY] lib/features/onboarding/presentation/widgets/onboarding_slide.dart**:
  - Replace static Icons with high-quality AI-generated Illustrations.
  - Add layered background animations (parallax depth).

---

### ✨ Phase 3: Global "Pro Max" Polish (Theme & Shell)
**Agents**: `frontend-specialist`, `performance-optimizer`

- **[MODIFY] lib/core/theme/app_theme.dart**:
  - Inject **Fredoka** font as the primary display font (headings).
  - Update global shadow tokens to "Fluid Shadows" (layered blurs).
  - add custom `PageRouteBuilder` for smooth, whimsical transitions between all screens.
- **[MODIFY] lib/features/main/presentation/main_shell_screen.dart**:
  - Add a "Springy" animation to the Glassmorphic Bottom Bar.
  - Implement a global "Living Background" (similar to RhymeScreen) for the Home and Progress tabs.

## Verification Plan

### Automated Tests
- `flutter test`: Verify navigation flow from Splash -> Onboarding -> Home.
- `flutter analyze`: Ensure no performance regressions or deprecated member usage.

### Manual Verification
- **FPS Check**: Verify 60fps transitions on the emulator during onboarding swipes.
- **Visual Audit**: Compare Splash -> Onboarding flow against premium design standards (Duolingo/Apple style).
