# Phase 4 Audit: Home Widgets and Color Tokens

This document presents the detailed subtractive cleanup audit of the home screen widgets, local home directory structure, and global color design tokens in `app_colors.dart`.

---

## 1. Widget Inventory under `lib/features/home/presentation/widgets/`

Below is the complete list of files residing under `lib/features/home/presentation/widgets/`, along with their byte sizes, their import status within the `lib/features/home/` directory (e.g. `home_screen.dart`), and whether they are imported or used anywhere outside `lib/features/home/`.

| File Path | Size (Bytes) | Imported by `home_screen.dart`? | Imported outside `lib/features/home/`? | Usage/Status |
|---|---|---|---|---|
| `ai_magic_hub.dart` | 4,274 | ❌ No | ❌ No | **DEAD**. Instantiates premium translation shortcut but is completely unreferenced. |
| `home_bento_widgets.dart` | 45 |  Yes | ❌ No | **DEAD**. Shim file containing `export 'home_bento/home_bento_widgets.dart';`. |
| `learning_path_preview.dart` | 11,458 |  Yes | ❌ No | **ACTIVE**. Renders mobile learning preview card slider. |
| `magic_translate_dialog.dart` | 5,550 | ❌ No | ❌ No | **DEAD**. Dialog template for translation features, completely unreferenced. |
| `mistake_review_card.dart` | 6,240 | ❌ No |  Yes | **ACTIVE** (externally). Imported only by `lib/features/quiz/presentation/widgets/quiz_complete_screen.dart`. |
| `next_best_action_card.dart` | 8,094 |  Yes | ❌ No | **ACTIVE**. CTA for continuing learning. |
| `today_affirmation_card.dart` | 14,228 | ❌ No | ❌ No | **ACTIVE** (pending integration). Will be integrated as a core block on Home. |
| `today_mission_card.dart` | 10,373 |  Yes | ❌ No | **ACTIVE**. Daily missions completion strip. |

---

## 2. Directory Contents of `home_bento/`

* **Location:** `lib/features/home/presentation/widgets/home_bento/`
* **Contents:**
  * `home_bento_widgets.dart` (40,401 bytes): This contains the actual implementations for Bento cards, stats displays, grids, and skeleton loader widgets for home screen statistics.
* **Analysis:** The `home_bento_widgets.dart` shim at the parent widgets folder merely exports this large file. The Bento grid layout on the home screen is slated for complete removal (or relocation to the Profile screen) to simplify the visual layout.

---

## 3. Translation Dialog and AI Magic Hub Build Tree References

* **`ai_magic_hub.dart`:** Verified by recursive codebase grep to have **0 references** across the entire `lib/` and `test/` directory. It is not imported, instantiated, or mentioned anywhere in the active build tree.
* **`magic_translate_dialog.dart`:** Verified by recursive codebase grep to have **0 references** across the entire `lib/` and `test/` directory.

> [!NOTE]
> The active translation screen route `/translate` maps to `AiTranslatorScreen` (defined in `ai_translator_screen.dart`), rendering a fully structured standalone page instead of using either of these legacy widgets. Both of these are 100% confirmed dead.

---

## 4. `mistake_review_card.dart` Status

* **Status:** The `MistakeReviewCard` widget is **not** rendered on the current `HomeScreen`.
* **Current Usage:** It is imported and rendered exclusively inside the quiz flow at `lib/features/quiz/presentation/widgets/quiz_complete_screen.dart`.
* **Action:** To resolve this orphaned module structure, we will relocate the file to `lib/features/quiz/presentation/widgets/mistake_review_card.dart` and update the quiz imports.

---

## 5. Color Tokens Audit of `app_colors.dart`

The following is a comprehensive usage list of all public symbols exported by `lib/core/theme/app_colors.dart` sorted alphabetically, showing the exact number of times the symbol is referenced outside of `app_colors.dart` itself in `lib/`:

| Symbol | Count in lib/ | Status |
|---|---|---|
| `AppColors.accentCoral` | 2 | **USED** |
| `AppColors.accentCyan` | 3 | **USED** |
| `AppColors.accentGold` | 0 | **UNUSED** |
| `AppColors.accentMint` | 0 | **UNUSED** |
| `AppColors.accentOrange` | 0 | **UNUSED** |
| `AppColors.accentPeach` | 0 | **UNUSED** |
| `AppColors.accentPink` | 1 | **USED** |
| `AppColors.accentPurple` | 3 | **USED** |
| `AppColors.accentYellow` | 0 | **UNUSED** |
| `AppColors.avatarPalettes` | 5 | **USED** |
| `AppColors.bento1` | 0 | **UNUSED** |
| `AppColors.bento2` | 0 | **UNUSED** |
| `AppColors.bento3` | 0 | **UNUSED** |
| `AppColors.bento4` | 0 | **UNUSED** |
| `AppColors.bentoShadow` | 0 | **UNUSED** |
| `AppColors.brandIconDark` | 0 | **UNUSED** |
| `AppColors.brandIconLight` | 0 | **UNUSED** |
| `AppColors.brandTextDark` | 14 | **USED** |
| `AppColors.brandTextLight` | 14 | **USED** |
| `AppColors.buttonShadow` | 2 | **USED** |
| `AppColors.charcoal` | 1 | **USED** |
| `AppColors.coloredShadow` | 0 | **UNUSED** |
| `AppColors.coralGradient` | 0 | **UNUSED** |
| `AppColors.darkBackground` | 12 | **USED** |
| `AppColors.darkBorder` | 4 | **USED** |
| `AppColors.darkBorderSubtle` | 0 | **UNUSED** |
| `AppColors.darkCardGradient` | 0 | **UNUSED** |
| `AppColors.darkPremiumGradient` | 0 | **UNUSED** |
| `AppColors.darkSurface` | 9 | **USED** |
| `AppColors.darkSurfaceElevated` | 8 | **USED** |
| `AppColors.darkSurfaceVariant` | 4 | **USED** |
| `AppColors.duoBlue` | 27 | **USED** |
| `AppColors.duoBlueDark` | 3 | **USED** |
| `AppColors.duoGreen` | 7 | **USED** |
| `AppColors.duoGreenDark` | 0 | **UNUSED** |
| `AppColors.duoOrange` | 44 | **USED** |
| `AppColors.duoOrangeDark` | 5 | **USED** |
| `AppColors.duoPurple` | 5 | **USED** |
| `AppColors.duoPurpleDark` | 0 | **UNUSED** |
| `AppColors.duoRed` | 9 | **USED** |
| `AppColors.duoRedDark` | 1 | **USED** |
| `AppColors.duoYellow` | 22 | **USED** |
| `AppColors.duoYellowDark` | 2 | **USED** |
| `AppColors.error` | 89 | **USED** |
| `AppColors.errorSoft` | 0 | **UNUSED** |
| `AppColors.errorTextLight` | 0 | **UNUSED** |
| `AppColors.fluidShadow` | 1 | **USED** |
| `AppColors.glass` | 4 | **USED** |
| `AppColors.glassBorderColor` | 0 | **UNUSED** |
| `AppColors.glowShadow` | 2 | **USED** |
| `AppColors.greenGlowGradient` | 0 | **UNUSED** |
| `AppColors.heroGradient` | 11 | **USED** |
| `AppColors.heroGradientAlt` | 1 | **USED** |
| `AppColors.info` | 0 | **UNUSED** |
| `AppColors.infoSoft` | 0 | **UNUSED** |
| `AppColors.largeShadow` | 1 | **USED** |
| `AppColors.lightBackground` | 13 | **USED** |
| `AppColors.lightBorder` | 4 | **USED** |
| `AppColors.lightBorderSubtle` | 0 | **UNUSED** |
| `AppColors.lightSurface` | 6 | **USED** |
| `AppColors.lightSurfaceElevated` | 0 | **UNUSED** |
| `AppColors.lightSurfaceVariant` | 4 | **USED** |
| `AppColors.logoGradient` | 0 | **UNUSED** |
| `AppColors.mediumShadow` | 0 | **UNUSED** |
| `AppColors.meshDark` | 0 | **UNUSED** |
| `AppColors.meshLight` | 0 | **UNUSED** |
| `AppColors.mintGradient` | 7 | **USED** |
| `AppColors.neonGlow` | 0 | **UNUSED** |
| `AppColors.peachGradient` | 9 | **USED** |
| `AppColors.premiumCoral` | 1 | **USED** |
| `AppColors.premiumCyan` | 5 | **USED** |
| `AppColors.premiumGreen` | 3 | **USED** |
| `AppColors.premiumMint` | 1 | **USED** |
| `AppColors.premiumOrange` | 3 | **USED** |
| `AppColors.premiumPink` | 0 | **UNUSED** |
| `AppColors.premiumPurple` | 4 | **USED** |
| `AppColors.primary` | 552 | **USED** |
| `AppColors.primaryDark` | 26 | **USED** |
| `AppColors.primaryDeep` | 0 | **UNUSED** |
| `AppColors.primaryGradient` | 0 | **UNUSED** |
| `AppColors.primaryLight` | 4 | **USED** |
| `AppColors.primaryMuted` | 0 | **UNUSED** |
| `AppColors.primaryPurple` | 1 | **USED** |
| `AppColors.pureBlack` | 5 | **USED** |
| `AppColors.pureWhite` | 0 | **UNUSED** |
| `AppColors.purpleGradient` | 5 | **USED** |
| `AppColors.quizBackground` | 2 | **USED** |
| `AppColors.quizBackgroundDark` | 0 | **UNUSED** |
| `AppColors.quizBadgeA` | 4 | **USED** |
| `AppColors.quizBadgeB` | 3 | **USED** |
| `AppColors.quizBadgeC` | 2 | **USED** |
| `AppColors.quizBadgeD` | 2 | **USED** |
| `AppColors.quizCardA` | 1 | **USED** |
| `AppColors.quizCardB` | 1 | **USED** |
| `AppColors.quizCardC` | 1 | **USED** |
| `AppColors.quizCardD` | 1 | **USED** |
| `AppColors.quizCorrect` | 8 | **USED** |
| `AppColors.quizDarkBackground` | 4 | **USED** |
| `AppColors.quizDarkBubble` | 2 | **USED** |
| `AppColors.quizDarkCard` | 3 | **USED** |
| `AppColors.quizDarkCardAlt` | 3 | **USED** |
| `AppColors.quizIncorrect` | 5 | **USED** |
| `AppColors.quizLightBubble` | 2 | **USED** |
| `AppColors.quizLightSuccessSurface` | 1 | **USED** |
| `AppColors.quizNextButton` | 2 | **USED** |
| `AppColors.richBlack` | 0 | **UNUSED** |
| `AppColors.skyBlueGradient` | 9 | **USED** |
| `AppColors.softBlack` | 1 | **USED** |
| `AppColors.softShadow` | 3 | **USED** |
| `AppColors.subtleShadow` | 0 | **UNUSED** |
| `AppColors.success` | 28 | **USED** |
| `AppColors.successSoft` | 0 | **UNUSED** |
| `AppColors.successTextLight` | 0 | **UNUSED** |
| `AppColors.sunsetGradient` | 7 | **USED** |
| `AppColors.textDisabledDark` | 1 | **USED** |
| `AppColors.textDisabledLight` | 1 | **USED** |
| `AppColors.textPrimaryDark` | 10 | **USED** |
| `AppColors.textPrimaryLight` | 11 | **USED** |
| `AppColors.textSecondaryDark` | 5 | **USED** |
| `AppColors.textSecondaryLight` | 5 | **USED** |
| `AppColors.textTertiaryDark` | 3 | **USED** |
| `AppColors.textTertiaryLight` | 4 | **USED** |
| `AppColors.warning` | 2 | **USED** |
| `AppColors.warningSoft` | 0 | **UNUSED** |
| `AppColors.warningTextLight` | 0 | **UNUSED** |
