// Word of the day: one new Santali word every day from the existing corpus,
// with pronunciation and a one-tap path into daily practice seeded with it.
// Hidden while the corpus loads or when it is empty — never a placeholder.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/eyebrow.dart';
import '../../../../shared/providers/language_settings_providers.dart';
import '../../../practice/daily/presentation/daily_practice_screen.dart';
import '../../../practice/daily/presentation/providers/daily_practice_providers.dart';
import '../providers/word_of_day_provider.dart';

class WordOfDayCard extends ConsumerWidget {
  const WordOfDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = ref.watch(wordOfDayProvider);
    if (word == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(effectiveTeachingLanguageProvider);
    final meaning = word.localizedMeaning(lang);
    final hasAudio = (word.audioUrl ?? '').trim().isNotEmpty;

    Future<void> play() async {
      final url = word.audioUrl?.trim();
      if (url == null || url.isEmpty) return;
      unawaited(
        ref
            .read(learningAnalyticsServiceProvider)
            .track(
              LearningAnalyticsEvents.wordOfDayPlayed,
              source: 'home',
              sourceId: word.id,
            ),
      );
      try {
        await ref.read(audioServiceProvider).playUrl(url);
      } catch (_) {
        // Audio must never break Home.
      }
    }

    void practice() {
      ref.read(dailyPracticeSeedWordProvider.notifier).state = word.id;
      context.push(dailyPracticeRoute);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.quizDarkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.webBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(l10n.wordOfDayEyebrow)),
              if (hasAudio)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: l10n.wordOfDayPlay,
                    onPressed: play,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      foregroundColor: isDark
                          ? Colors.white
                          : AppColors.primaryDark,
                    ),
                    icon: const Icon(Icons.volume_up_rounded, size: 22),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            word.wordOlChiki,
            style: AppTypography.olChiki(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: isDark ? Colors.white : AppColors.webInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meaning.isEmpty ? word.wordLatin : '${word.wordLatin}  ·  $meaning',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.webSlate,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: practice,
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.primaryLight
                    : AppColors.emeraldDeep,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                l10n.wordOfDayPractice,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
