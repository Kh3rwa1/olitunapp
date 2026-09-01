import 'dart:io' show Platform;
import 'dart:ui';
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
import 'lesson_block_glass_card.dart';

/// Interactive content card section displaying characters, audio playback,
/// pronunciation notes, typing triggers, and native ads.
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

    final textOlChiki = block.textOlChiki ?? '';
    final textLatin = block.textLatin ?? '';
    final pron = block.data?['pronunciation'] as String?;
    final cardText = textOlChiki.isNotEmpty ? textOlChiki : display.scriptText;
    final isLongText = cardText.length > 6 || cardText.contains(' ');
    final buttonText = display.ctaText;
    final blockAudioId =
        '${block.textOlChiki ?? block.textLatin ?? block.type}_$index';
    final isThisPlaying = isAudioPlaying && playingId == blockAudioId;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Large character card with entrance & optional loop breathing animation
          ScaleButton(
            onPressed: block.audioUrl != null && block.audioUrl!.isNotEmpty
                ? () => onPlayAudio(block.audioUrl!, blockAudioId)
                : null,
            child: () {
              final isTest =
                  !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
              Widget content;
              if (isLongText || cardText.contains('\n')) {
                final isMultiLine =
                    cardText.contains('\n') || cardText.length > 60;

                content = Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (textOlChiki.isNotEmpty)
                        Text(
                          textOlChiki,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMultiLine ? 24 : 32,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : accentColor,
                            fontFamily: 'OlChiki',
                            height: 1.35,
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
                      if (display.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          display.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMultiLine ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondaryLight,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (textOlChiki.isEmpty &&
                          display.subtitle.isEmpty &&
                          textLatin.isNotEmpty)
                        Text(
                          textLatin,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMultiLine ? 17 : 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : accentColor,
                            height: 1.35,
                          ),
                        ),
                      if (textOlChiki.isEmpty && textLatin.isEmpty)
                        Text(
                          lesson.titleLatin,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : accentColor,
                          ),
                        ),

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
              } else {
                content = Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Glow Ring
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : accentColor.withValues(alpha: 0.15)),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(
                                  alpha: isDark ? 0.15 : 0.2,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Glass body
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          Colors.white.withValues(alpha: 0.06),
                                          Colors.white.withValues(alpha: 0.02),
                                        ]
                                      : [
                                          Colors.white.withValues(alpha: 0.8),
                                          Colors.white.withValues(alpha: 0.45),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Subtle Watermark
                                  CustomPaint(
                                    size: const Size(210, 210),
                                    painter: LessonBlockWatermarkPainter(
                                      text: textOlChiki.isNotEmpty
                                          ? textOlChiki
                                          : textLatin,
                                      style: TextStyle(
                                        fontSize: 160,
                                        fontWeight: FontWeight.w900,
                                        color:
                                            (isDark
                                                    ? Colors.white
                                                    : accentColor)
                                                .withValues(alpha: 0.04),
                                      ),
                                    ),
                                  ),
                                  // Main Character Text
                                  Text(
                                    textOlChiki.isNotEmpty
                                        ? textOlChiki
                                        : textLatin,
                                    style: TextStyle(
                                      fontSize:
                                          (textOlChiki.isNotEmpty
                                                      ? textOlChiki
                                                      : textLatin)
                                                  .length <
                                              3
                                          ? 84
                                          : 44,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : accentColor,
                                      shadows: [
                                        Shadow(
                                          color: isDark
                                              ? Colors.black.withValues(
                                                  alpha: 0.3,
                                                )
                                              : accentColor.withValues(
                                                  alpha: 0.15,
                                                ),
                                          offset: const Offset(0, 3),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Pulsing speaker icon
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                            : accentColor.withValues(
                                                alpha: 0.08,
                                              )),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.12,
                                                )
                                              : accentColor.withValues(
                                                  alpha: 0.12,
                                                )),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        color: isDark
                                            ? Colors.white70
                                            : accentColor,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  // Tap to Hear Badge
                                  Positioned(
                                    bottom: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
                                            : accentColor.withValues(
                                                alpha: 0.06,
                                              )),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.1,
                                                )
                                              : accentColor.withValues(
                                                  alpha: 0.1,
                                                )),
                                        ),
                                      ),
                                      child: Text(
                                        'TAP TO HEAR',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? Colors.white70
                                              : accentColor,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              content = content
                  .animate()
                  .fade(duration: const Duration(milliseconds: 500))
                  .slide(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );

              if (!isTest) {
                content = content
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.04, 1.04),
                      duration: const Duration(milliseconds: 2400),
                      curve: Curves.easeInOut,
                    );
              }
              return content;
            }(),
          ),
          if (!isLongText && display.subtitle.isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                display.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.3,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Tactile 3D Action Button
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
                              letterSpacing: 1.5,
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
                        Flexible(
                          child: Text(
                            buttonText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        if (block.audioUrl != null &&
                            block.audioUrl!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          SoundWaveIndicator(
                            color: Colors.white,
                            isPlaying: isThisPlaying,
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          if (pron != null && pron.isNotEmpty) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LessonBlockGlassCard(
                themeColor: accentColor,
                isDark: isDark,
                radius: 20,
                padding: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 52,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.hearing_rounded,
                                color: isDark ? Colors.white70 : accentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pronunciation',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white70 : accentColor,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pron,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF1A202C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: RepaintBoundary(
              child: NativeAdWidget(placement: 'lesson_block_native'),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
