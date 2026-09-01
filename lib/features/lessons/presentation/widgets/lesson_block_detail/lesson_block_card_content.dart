import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/ads/widgets/native_ad_widget.dart';
import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';
import 'package:itun/core/presentation/animations/scale_button.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/practice/presentation/providers/typing_practice_controller.dart';
import 'package:itun/shared/providers/providers.dart';
import '../lesson_block_widgets.dart';

/// Interactive content card section displaying target Ol Chiki characters,
/// centered pronunciation transliteration guide, audio playback,
/// typing triggers, and native ads.
class LessonBlockCardContent extends ConsumerWidget {
  const LessonBlockCardContent({
    super.key,
    required this.block,
    required this.index,
    required this.accentColor,
    required this.isDark,
    required this.lesson,
    required this.displayText,
    required this.isAudioPlaying,
    required this.playingId,
    required this.onPlayAudio,
    this.typingPracticeArgs,
    this.isEligibleForTyping = false,
  });

  final LessonBlockEntity block;
  final int index;
  final Color accentColor;
  final bool isDark;
  final LessonEntity lesson;
  final String displayText;
  final bool isAudioPlaying;
  final String? playingId;
  final void Function(String url, String id) onPlayAudio;
  final TypingPracticeArgs? typingPracticeArgs;
  final bool isEligibleForTyping;

  double _resolveFontSize(String text) {
    final length = text.trim().length;
    if (length <= 2) return 64;
    if (length <= 6) return 44;
    if (length <= 20) return 32;
    if (length <= 50) return 24;
    return 20;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachingLanguage = ref.watch(effectiveTeachingLanguageProvider);
    final scriptMode = ref.watch(effectiveScriptModeProvider);

    final display = OlChikiMultilingualHelper.resolveBlockDisplay(
      textOlChiki: block.textOlChiki,
      textLatin: block.textLatin,
      textBengali: block.textBengali,
      textHindi: block.textHindi,
      textOdia: block.textOdia,
      explicitMeaning: block.data?['meaning'] as String?,
      explicitPronunciation: block.data?['pronunciation'] as String?,
      teachingLanguage: teachingLanguage,
      scriptMode: scriptMode,
    );

    final cleanOlChiki = display.scriptText.isNotEmpty
        ? display.scriptText
        : OlChikiMultilingualHelper.sanitizeOlChiki(block.textOlChiki ?? '');
    final fallbackLatin = block.textLatin ?? '';
    final targetScriptText = cleanOlChiki.isNotEmpty
        ? cleanOlChiki
        : (fallbackLatin.isNotEmpty ? fallbackLatin : lesson.titleLatin);

    final buttonText = display.ctaText;
    final blockAudioId =
        '${block.textOlChiki ?? block.textLatin ?? block.type}_$index';
    final isThisPlaying = isAudioPlaying && playingId == blockAudioId;
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Interactive target text card with audio playback
          ScaleButton(
            onPressed: block.audioUrl != null && block.audioUrl!.isNotEmpty
                ? () => onPlayAudio(block.audioUrl!, blockAudioId)
                : null,
            child: () {
              Widget cardBody = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Target Ol Chiki Script Text
                    Text(
                      targetScriptText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _resolveFontSize(targetScriptText),
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : accentColor,
                        fontFamily: cleanOlChiki.isNotEmpty ? 'OlChiki' : null,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : accentColor.withValues(alpha: 0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),

                    // 2. Subtitle Pronunciation Transliteration in user's script
                    if (display.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        display.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondaryLight,
                          height: 1.35,
                        ),
                      ),
                    ],

                    // 3. Audio indicator pill
                    if (block.audioUrl != null &&
                        block.audioUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : accentColor.withValues(alpha: 0.06)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : accentColor.withValues(alpha: 0.1)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              color: isDark ? Colors.white70 : accentColor,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TAP TO HEAR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white70 : accentColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );

              cardBody = cardBody
                  .animate()
                  .fade(duration: const Duration(milliseconds: 500))
                  .slide(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );

              if (!isTest) {
                cardBody = cardBody
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.03, 1.03),
                      duration: const Duration(milliseconds: 2400),
                      curve: Curves.easeInOut,
                    );
              }
              return cardBody;
            }(),
          ),
          const SizedBox(height: 24),

          // Tactile 3D Action Button (Typing practice or Listen)
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: isEligibleForTyping && typingPracticeArgs != null
                ? Tactile3DButton(
                    color: AppColors.primary,
                    onPressed: () {
                      ref
                          .read(
                            typingPracticeControllerProvider(
                              typingPracticeArgs!,
                            ).notifier,
                          )
                          .startPractice();
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_outlined, color: Colors.black),
                        SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'PRACTICE TYPING',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Tactile3DButton(
                    color: accentColor,
                    onPressed:
                        block.audioUrl != null && block.audioUrl!.isNotEmpty
                        ? () => onPlayAudio(block.audioUrl!, blockAudioId)
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isThisPlaying
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            buttonText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // Native ad
          if (index % 3 == 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: NativeAdWidget(placement: 'lesson_block_card'),
            ),
        ],
      ),
    );
  }
}
