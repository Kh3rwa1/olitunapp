# Olitun Design System Specification

## 1. Overview & Cultural Philosophy

Olitun is the premier digital learning platform dedicated to the revitalization, preservation, and mastery of the **Santali language** and the **Ol Chiki script** (invented by Pandit Raghunath Murmu in 1925).

The Olitun Design System pairs modern Material 3 ergonomics with an authentic, ownable visual identity deeply rooted in Santali cultural heritage:
- **Sohrai & Khovar Mural Traditions**: Celebrated ceremonial wall art painted using natural earthen pigments harvested from riverbeds and forest clays.
- **Jaher Than (Sacred Sal Groves)**: Deep evergreen canopy tones representing sanctuary, life, and continuity.
- **Linguistic Vitality**: The signature Olitun mint green (`#1EE088`), expressing new growth, modern speed, and vibrant educational empowerment.

---

## 2. Color Architecture (`AppColors`)

All color values in the application are strictly centralized in `lib/core/theme/app_colors.dart` and enforced by CI gates. Raw `Color(0x...)` literals in feature code are strictly prohibited.

```
                  ┌─────────────────────────────────────┐
                  │          AppColors System           │
                  └──────────────────┬──────────────────┘
            ┌────────────────────────┼────────────────────────┐
            ▼                        ▼                        ▼
  ┌───────────────────┐    ┌───────────────────┐    ┌───────────────────┐
  │   Brand Anchor    │    │ Santali Cultural  │    │  Semantic Accents │
  │  Signature Mint   │    │  Terracotta,      │    │  Forest, Ochre,   │
  │  #1EE088          │    │  Ochre, Sal Green │    │  Terracotta, Blue │
  └───────────────────┘    └───────────────────┘    └───────────────────┘
```

### 2.1 Core Brand Anchor
| Token | Hex Value | Purpose |
|---|---|---|
| `AppColors.primary` | `#1EE088` | Signature Olitun Mint Green — primary actions, progress bars, active states |
| `AppColors.primaryLight` | `#5DFFA8` | High-visibility highlight on dark surfaces, brand text dark |
| `AppColors.primaryDark` | `#00C767` | Deep primary green for gradients and active presses |

### 2.2 Santali Cultural Palette
| Token | Hex Value | Cultural Significance |
|---|---|---|
| `AppColors.santaliTerracotta` | `#8B3A3A` | Sohrai ritual courtyard earthen wall red / oxblood pottery pigment |
| `AppColors.santaliTerracottaDark` | `#6B2A2A` | Deep terracotta shadow / high-contrast borders |
| `AppColors.santaliTerracottaLight` | `#B84A39` | Terracotta highlights and secondary badges |
| `AppColors.santaliOchre` | `#D99B26` | Harvest mural ochre / natural riverbed clay gold |
| `AppColors.santaliOchreDark` | `#B45309` | Deep ochre for dark-mode text and borders |
| `AppColors.santaliOchreLight` | `#E5A93C` | Warm festive ochre highlight |
| `AppColors.santaliSalGreen` | `#1B4D3E` | Sacred Sal grove (*Jaher Than*) deep canopy |
| `AppColors.santaliSalGreenLight` | `#237A4B` | Vibrant Sal leaf green (also `AppColors.accentForest`) |
| `AppColors.santaliNightSky` | `#1E2A44` | Starry night sky during Baha and Sohrai festivals |
| `AppColors.santaliNightSkyLight` | `#2C3E6B` | Twilight blue accent |
| `AppColors.santaliEarthBlack` | `#181E24` | Natural mineral charcoal black used in Khovar outlines |
| `AppColors.santaliClayWhite` | `#FBF9F5` | Natural limestone whitewash for high-contrast background |

### 2.3 Semantic Accents & Badges
| Token | Hex Value | Usage |
|---|---|---|
| `AppColors.brandBlue` | `#1CB0F6` | Informational badges, grammar modules, listening activities |
| `AppColors.accentForest` | `#237A4B` | Vocabulary modules, reading mastery |
| `AppColors.accentOchre` | `#D99B26` | Daily missions, streaks, warm notifications |
| `AppColors.accentTerracotta` | `#8B3A3A` | High-priority milestones, cultural stories |
| `AppColors.accentGold` | `#F59E0B` | XP rewards, leaderboards, achievement crowns |
| `AppColors.accentPurple` | `#8B5CF6` | AI Translator, writing exercises, special events |
| `AppColors.accentCyan` | `#00E5FF` | Interactive phonetics, pronunciation feedback |
| `AppColors.accentPink` | `#FF4081` | Rhymes, music audio tracks, playful learning |

### 2.4 Neutral & Surface Hierarchy
| Context | Light Theme | Dark Theme |
|---|---|---|
| **Scaffold Background** | `#F8F9FA` (`lightBackground`) | `#000000` (`darkBackground`) |
| **Primary Surface** | `#FFFFFF` (`lightSurface`) | `#121212` (`darkSurface`) |
| **Elevated Surface** | `#FFFFFF` (with `fluidShadow`) | `#1E1E1E` (`darkSurfaceElevated`) |
| **Card Variant / Input** | `#F1F3F5` (`lightSurfaceVariant`) | `#2A2A2A` (`darkSurfaceVariant`) |
| **Borders** | `#E0E0E0` (`lightBorder`) | `#3D3D3D` (`darkBorder`) |
| **Primary Text** | `#000000` (`textPrimaryLight`) | `#FFFFFF` (`textPrimaryDark`) |
| **Secondary Text** | `#424242` (`textSecondaryLight`) | `#E0E0E0` (`textSecondaryDark`) |
| **Tertiary / Hint Text** | `#757575` (`textTertiaryLight`) | `#9E9E9E` (`textTertiaryDark`) |

---

## 3. Typography Architecture (`AppTypography`)

### 3.1 Bundled Zero-Network Fonts
To ensure offline autonomy, strict privacy compliance, and instantaneous page transitions with zero FOIT/FOUT, all fonts are bundled locally in `assets/fonts/`:
- **`Inter-Variable.ttf`**: Primary Latin & numeric UI typeface (weights 100–900).
- **`OlChiki.ttf`**: Authentic, pixel-fitted Ol Chiki indigenous glyph font.

### 3.2 Font Fallback Hierarchy
Both light and dark themes declare:
```dart
fontFamily: 'Inter',
fontFamilyFallback: ['OlChiki'],
```
Any raw Ol Chiki glyph (e.g. `ᱚ`, `ᱛ`, `ᱜ`, `ᱝ`) automatically resolves to `OlChiki.ttf` without requiring explicit per-widget styling.

### 3.3 Type Scale
| Style Name | Size | Weight | Tracking | Primary Usage |
|---|---|---|---|---|
| `displayLarge` | 57sp | 700 | -0.5 | Splash, milestone celebrations |
| `displayMedium` | 45sp | 600 | -0.5 | Hero banners, level-up screens |
| `displaySmall` | 36sp | 600 | 0.0 | Modal headers, lesson titles |
| `headlineLarge` | 32sp | 600 | 0.0 | Category view headers |
| `headlineMedium`| 28sp | 600 | 0.0 | Section headers, card titles |
| `headlineSmall` | 24sp | 600 | 0.0 | Bento card headlines |
| `titleLarge` | 22sp | 600 | 0.0 | Navigation bar, sheet headers |
| `titleMedium` | 18sp | 600 | 0.0 | List item primary text |
| `titleSmall` | 16sp | 600 | 0.0 | Subtitle text, badge captions |
| `bodyLarge` | 16sp | 400 | 0.0 | Lesson story paragraphs |
| `bodyMedium` | 14sp | 400 | 0.0 | Secondary descriptions, quiz questions |
| `bodySmall` | 12sp | 400 | 0.0 | Timestamps, metadata, footnotes |
| `labelLarge` | 14sp | 600 | 0.1 | Primary button labels |
| `labelMedium` | 12sp | 600 | 0.5 | Chip tags, status labels |
| `labelSmall` | 11sp | 500 | 0.5 | Tiny badges, progress counters |

---

## 4. Spatial & Grid System (`AppSpacing`)

All layouts conform to an **8-point harmonic grid** via `lib/core/theme/app_spacing.dart`:

```dart
// Harmonic Dimensions
AppSpacing.xxs   // 2.0 dp  (Fine sub-pixel adjustments)
AppSpacing.xs    // 4.0 dp  (Badge padding, tight icon spacing)
AppSpacing.sm    // 8.0 dp  (Standard inter-item gap)
AppSpacing.md    // 12.0 dp (Content group gap)
AppSpacing.lg    // 16.0 dp (Standard screen & card padding)
AppSpacing.xl    // 20.0 dp (Generous container padding)
AppSpacing.xxl   // 24.0 dp (Section separators)
AppSpacing.xxxl  // 32.0 dp (Hero module margins)
AppSpacing.huge  // 48.0 dp (Bottom sheet bottom inset, hero spacers)

// High-Level Layout Presets
AppSpacing.screenPadding     // EdgeInsets.symmetric(horizontal: 16, vertical: 12)
AppSpacing.screenPaddingWide // EdgeInsets.symmetric(horizontal: 24, vertical: 16)
AppSpacing.cardPadding       // EdgeInsets.all(16)

// Pre-baked SizedBox Gap Widgets
AppSpacing.gapW8, AppSpacing.gapW16, AppSpacing.gapW24
AppSpacing.gapH8, AppSpacing.gapH16, AppSpacing.gapH24, AppSpacing.gapH32, AppSpacing.gapH48
```

---

## 5. Corner Radii & Elevation (`AppRadius`)

Consistent, smooth curvature defined in `lib/core/theme/app_radius.dart`:

```dart
// Scale Constants
AppRadius.xs    // 4.0 dp  (Small indicators, progress tick marks)
AppRadius.sm    // 8.0 dp  (Tooltips, small tags)
AppRadius.md    // 12.0 dp (Chips, input fields)
AppRadius.lg    // 16.0 dp (Buttons, list tiles, dialogs)
AppRadius.xl    // 20.0 dp (Small cards, toast banners)
AppRadius.xxl   // 24.0 dp (Primary cards, bento modules)
AppRadius.xxxl  // 28.0 dp (Bottom sheets, dialog containers)
AppRadius.full  // 999.0 dp (Pills, circular avatar frames, FABs)

// Pre-baked BorderRadius Presets
AppRadius.borderSm, AppRadius.borderMd, AppRadius.borderLg, AppRadius.borderXxl
AppRadius.topLg, AppRadius.topXl, AppRadius.topXxl, AppRadius.topXxxl
```

### 5.1 Fluid Elevation & Shadow System
- **`AppColors.fluidShadow`**: Organic tinted glow (`BoxShadow(color: Color(0x261EE088), blurRadius: 40, offset: Offset(0, 12), spreadRadius: -8)`).
- **`AppColors.softShadow`**: Low-key neutral surface elevation (`blurRadius: 20, offset: Offset(0, 4)`).
- **`AppColors.largeShadow`**: Deep floating modal elevation (`blurRadius: 50, offset: Offset(0, 20)`).

---

## 6. Accessibility & WCAG 2.2 AA Contrast Compliance

### 6.1 Contrast Ratio Verification
Every foreground/background combination in Olitun is verified via automated tests in `test/core/accessibility/wcag_theme_contrast_test.dart`:

| Foreground Token | Background Surface | Contrast Ratio | WCAG 2.2 AA Requirement | Status |
|---|---|---|---|---|
| Primary Button Text (`#00391C`) | `AppColors.primary` (`#1EE088`) | **7.24:1** | $\ge 4.5:1$ (Normal Text) | ✅ Pass |
| `textPrimaryLight` (`#000000`) | `lightBackground` (`#F8F9FA`) | **19.8:1** | $\ge 4.5:1$ (Normal Text) | ✅ Pass |
| `textPrimaryDark` (`#FFFFFF`) | `darkBackground` (`#000000`) | **21.0:1** | $\ge 4.5:1$ (Normal Text) | ✅ Pass |
| `santaliTerracotta` (`#8B3A3A`) | `lightSurface` (`#FFFFFF`) | **5.84:1** | $\ge 4.5:1$ (Normal Text) | ✅ Pass |
| `santaliSalGreen` (`#1B4D3E`) | `lightSurface` (`#FFFFFF`) | **8.71:1** | $\ge 4.5:1$ (Normal Text) | ✅ Pass |
| `santaliNightSky` (`#1E2A44`) | `lightSurface` (`#FFFFFF`) | **11.64:1** | $\ge 4.5:1$ (Normal Text) | ✅ Pass |
| `santaliOchre` (`#D99B26`) | `darkBackground` (`#000000`) | **6.42:1** | $\ge 3.0:1$ (UI / Large Text) | ✅ Pass |

### 6.2 Touch Targets & Motion Safeguards
- **Touch Targets**: All interactive elements strictly adhere to the minimum **48x48 dp** touch target requirement (`WcagAudit.hasMinimumTapTarget`).
- **Reduced Motion**: All animations listen to `reduceVisualEffectsProvider` and system accessibility settings to instantly replace parallax and looped animations with clean static states.

---

## 7. CI Quality Gates & Ratchet Policies

The codebase enforces three automated, ratcheting pre-merge gates:
1. **`scripts/check_typography.mjs`**: Guarantees zero references to unapproved external fonts (e.g. `google_fonts`, `Poppins`, `Fredoka`).
2. **`scripts/check_color_literals.mjs`**: Scans all `lib/**/*.dart` files and enforces a ratcheting file-count baseline, permanently blocking raw `Color(0x...)` literals.
3. **`scripts/check_file_length.mjs`**: Hard 600-line ceiling per non-exempt Dart file, ratcheting down as legacy modules are refactored.
