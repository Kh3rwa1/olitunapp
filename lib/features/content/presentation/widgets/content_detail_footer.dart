import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/practice/data/typing_practice_settings.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import 'package:itun/shared/models/content_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/audio_playback_providers.dart';
import 'audio_controls_bar.dart';

// Bottom action footer: typing-practice launcher (with the audio
// controls bar) or the lesson-completion CTA gated on tracing.
class ContentDetailFooter extends ConsumerWidget {
  const ContentDetailFooter({
    super.key,
    required this.item,
    required this.accentColor,
    required this.isDark,
    required this.isTracingCompleted,
    required this.onCompleteContent,
  });

  final ContentItem item;
  final Color accentColor;
  final bool isDark;
  final bool isTracingCompleted;
  final Future<void> Function(ContentItem item) onCompleteContent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(typingPracticeSettingsProvider);
    final bool isEligible =
        settings.enabled &&
        (item.kind == ContentKind.word || item.kind == ContentKind.sentence) &&
        item.olChiki != null &&
        item.olChiki!.isNotEmpty &&
        item.olChiki!.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F);

    if (isEligible) {
      final typingPracticeArgs = TypingPracticeArgs(
        itemKey: item.id,
        target: item.olChiki!,
        latin: item.title,
        meaning: item.subtitle ?? '',
        contentType: item.kind == ContentKind.word ? 'word' : 'sentence',
      );
      final typingState = ref.watch(
        typingPracticeControllerProvider(typingPracticeArgs),
      );

      if (typingState.phase == TypingPhase.idle) {
        // Mode-aware audio bundle (targetOnly/bilingual/translationOnDemand):
        // Phase 2 audio_tracks + localized_contents with legacy inline
        // fields as offline-first fallback. Failure-swallowing by design.
        final bundleAsync = ref.watch(
          audioBundleProvider(
            AudioBundleRequest(
              contentKind: item.kind.name,
              contentId: item.id,
              legacyAudioUrl: item.effectiveAudioUrl,
              legacyMeaning: item.subtitle ?? '',
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.quizDarkCardAlt : Colors.white)
                .withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full pedagogical controls (Santali/Slow/Meaning/Repeat/
                // speed/progress) routed through the central controller.
                // The bundle itself surfaces unavailable states, so the
                // bar renders whenever the bundle resolved.
                bundleAsync.maybeWhen(
                  data: (bundle) => AudioControlsBar(bundle: bundle),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(
                                  typingPracticeControllerProvider(
                                    typingPracticeArgs,
                                  ).notifier,
                                )
                                .startPractice();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_outlined,
                            color: Colors.black,
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.practiceTyping,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.quizDarkCardAlt : Colors.white).withValues(
          alpha: 0.85,
        ),
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isTracingCompleted
                ? () => unawaited(onCompleteContent(item))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              disabledBackgroundColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(
              isTracingCompleted
                  ? Icons.check_circle_outline
                  : Icons.gesture_rounded,
            ),
            label: Text(
              isTracingCompleted
                  ? 'Finish Practice (+25 stars)'
                  : 'Complete Tracing Exercise first',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
