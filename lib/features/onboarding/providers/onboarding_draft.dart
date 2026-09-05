import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/providers/local_settings_provider.dart';

/// Interrupted-onboarding draft for the legacy 6-step [OnboardingScreen].
///
/// The v2 flow already persists every choice at tap time plus the step index
/// (`OnboardingV2Screen`); this mirrors that recovery behavior for the
/// default legacy flow, whose choices otherwise live only in widget state and
/// are lost on process death. Keys are namespaced `onboarding_v1_draft_*` so
/// they never collide with the v2 step key or the real settings keys that are
/// only written on completion. The draft is cleared on finish/skip.
class OnboardingDraft {
  static const stepKey = 'onboarding_v1_draft_step';
  static const teachingLanguageKey = 'onboarding_v1_draft_teaching_lang';
  static const levelKey = 'onboarding_v1_draft_level';
  static const scriptModeKey = 'onboarding_v1_draft_script_mode';
  static const dailyGoalKey = 'onboarding_v1_draft_daily_goal';
  static const goalsKey = 'onboarding_v1_draft_goals';

  static const totalSteps = 6;
  static const validScriptModes = {'both', 'olchiki', 'latin'};

  final int step;
  final String? teachingLanguage;
  final LearnerLevel level;
  final String scriptMode;
  final int dailyGoal;
  final List<String> goals;

  const OnboardingDraft({
    this.step = 0,
    this.teachingLanguage,
    this.level = LearnerLevel.beginner,
    this.scriptMode = 'both',
    this.dailyGoal = 5,
    this.goals = const [],
  });

  /// Returns null when no draft was saved (fresh onboarding start).
  static OnboardingDraft? load(SharedPreferences prefs) {
    final step = prefs.getInt(stepKey);
    if (step == null) return null;
    final scriptMode = prefs.getString(scriptModeKey) ?? 'both';
    return OnboardingDraft(
      step: step.clamp(0, totalSteps - 1),
      teachingLanguage: prefs.getString(teachingLanguageKey),
      level: LearnerLevel.values.firstWhere(
        (e) => e.name == prefs.getString(levelKey),
        orElse: () => LearnerLevel.beginner,
      ),
      scriptMode: validScriptModes.contains(scriptMode) ? scriptMode : 'both',
      dailyGoal: prefs.getInt(dailyGoalKey) ?? 5,
      goals: prefs.getStringList(goalsKey) ?? const [],
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setInt(stepKey, step);
    final lang = teachingLanguage;
    if (lang == null) {
      await prefs.remove(teachingLanguageKey);
    } else {
      await prefs.setString(teachingLanguageKey, lang);
    }
    await prefs.setString(levelKey, level.name);
    await prefs.setString(scriptModeKey, scriptMode);
    await prefs.setInt(dailyGoalKey, dailyGoal);
    await prefs.setStringList(goalsKey, goals);
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await Future.wait([
      prefs.remove(stepKey),
      prefs.remove(teachingLanguageKey),
      prefs.remove(levelKey),
      prefs.remove(scriptModeKey),
      prefs.remove(dailyGoalKey),
      prefs.remove(goalsKey),
    ]);
  }
}
