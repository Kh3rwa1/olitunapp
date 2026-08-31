import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/providers/language_settings_providers.dart';
import 'settings_widgets.dart';

/// "Teaching language" tile for Settings → Appearance. The teaching
/// language drives meanings, explanations, and translation audio — it is
/// deliberately separate from the interface language (`appLanguage`).
class TeachingLanguageTile extends ConsumerWidget {
  const TeachingLanguageTile({super.key});

  static const _nativeNames = <String, String>{
    'en': 'English',
    'hi': 'हिंदी',
    'bn': 'বাংলা',
    'or': 'ଓଡ଼ିଆ',
    'sat': 'ᱥᱟᱱᱛᱟᱲᱤ',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = ref.watch(effectiveTeachingLanguageProvider);
    final currentName = _nativeNames[current] ?? 'English';

    return SettingTile(
      icon: Icons.record_voice_over_rounded,
      title: l10n.teachingLanguage,
      subtitle: '$currentName · ${l10n.teachingLanguageSubtitle}',
      isDark: isDark,
      onTap: () => _showTeachingLanguageDialog(context, ref, current),
    );
  }

  void _showTeachingLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.teachingLanguage,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            for (final code in kTeachingLanguages)
              _SelectionOption(
                label: _nativeNames[code] ?? code,
                selected: code == current,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(sheetContext);
                  updateTeachingLanguage(ref, code);
                  unawaited(
                    ref
                        .read(learningAnalyticsServiceProvider)
                        .track(
                          LearningAnalyticsEvents.teachingLanguageSelected,
                          source: 'settings',
                          metadata: {'teachingLanguage': code},
                        ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// "Lesson audio" tile for Settings → Appearance. Lets the learner choose
/// between Santali-only, bilingual sequencing, and translation-on-demand.
class LessonAudioModeTile extends ConsumerWidget {
  const LessonAudioModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = ref.watch(lessonAudioModeProvider);

    return SettingTile(
      icon: Icons.headphones_rounded,
      title: l10n.lessonAudioMode,
      subtitle: _modeLabel(l10n, current),
      isDark: isDark,
      onTap: () => _showAudioModeDialog(context, ref, current),
    );
  }

  String _modeLabel(AppLocalizations l10n, LessonAudioMode mode) {
    switch (mode) {
      case LessonAudioMode.targetOnly:
        return l10n.audioModeTargetOnly;
      case LessonAudioMode.bilingual:
        return l10n.audioModeBilingual;
      case LessonAudioMode.translationOnDemand:
        return l10n.audioModeTranslationOnDemand;
    }
  }

  void _showAudioModeDialog(
    BuildContext context,
    WidgetRef ref,
    LessonAudioMode current,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.lessonAudioMode,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            for (final mode in LessonAudioMode.values)
              _SelectionOption(
                label: _modeLabel(l10n, mode),
                selected: mode == current,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(sheetContext);
                  updateLessonAudioMode(ref, mode);
                  unawaited(
                    ref
                        .read(learningAnalyticsServiceProvider)
                        .track(
                          LearningAnalyticsEvents.audioModeSelected,
                          source: 'settings',
                          metadata: {'audioMode': mode.name},
                        ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Generic single-select row used by the new settings sheets. Mirrors the
/// styling of the existing `LanguageOption` / `ScriptOption` widgets.
class _SelectionOption extends StatelessWidget {
  const _SelectionOption({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
