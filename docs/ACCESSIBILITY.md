# Accessibility Standards & WCAG 2.2 AA Compliance

Olitun is committed to providing an inclusive, barrier-free learning experience for all learners of the Santali language and Ol Chiki script across mobile, desktop, and web platforms.

---

## 1. Compliance Level & Guarantees

Olitun targets and adheres to **WCAG 2.2 Level AA** standards:

| Criterion | Requirement | Olitun Implementation |
|---|---|---|
| **1.4.3 Contrast (Minimum)** | Contrast ratio $ge 4.5:1$ for normal text, $ge 3:1$ for large text | Verified via automated contrast tests against all light and dark theme tokens |
| **1.4.4 Resize Text** | Text scalable up to 200% without loss of content or functionality | Layouts designed with fluid constraints and flexible auto-wrapping |
| **2.5.5 / 2.5.8 Target Size** | Minimum interactive touch target of $48 \times 48\text{ dp}$ | All icon buttons, cards, and quiz options enforce minimum bounding boxes |
| **2.3.3 Animation from Interactions** | Respect reduced motion user preferences | All animations wrapped in `RespectMotion` tokens |
| **1.1.1 Non-text Content** | Text alternatives for non-text Ol Chiki script and glyphs | Structured semantics with phonetic romanization and English meaning |

---

## 2. Ol Chiki Script & Screen Reader Semantics

Because many standard operating system text-to-speech (TTS) engines lack native phoneme synthesis for Ol Chiki Unicode characters (U+1C50–U+1C7F), Olitun uses a structured semantic labeling model via `LearningSemantics`:

- **Character Glyphs:** Provide spoken character names (e.g. *"Ol Chiki character ᱚ (LA), pronounced La"*).
- **Words & Sentences:** Provide composite semantics combining original Ol Chiki, phonetic Latin reading, and English translation.
- **Stroke Animations:** Tagged with semantic descriptions indicating stroke sequence and directional flow.
- **Quiz Interactions:** Options announce option index, label, selection state, and immediate feedback state (*"Answer A, ᱚ, selected, correct"*).

---

## 3. Motion & Cognitive Accessibility

1. **Reduced Motion:** When the OS setting for reduced motion is enabled, all non-essential decorative animations, hero pulse effects, and continuous rotations are disabled or replaced with immediate crossfades.
2. **Predictable Navigation:** Navigation follows consistent hierarchical drill-down and shell navigation patterns with explicit back navigation.
3. **No Flashing Content:** No element flashes more than 3 times in any 1-second period.
