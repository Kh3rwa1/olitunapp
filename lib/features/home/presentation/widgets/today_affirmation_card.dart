import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../../../affirmations/data/affirmation_share_service_provider.dart';
import '../../../affirmations/presentation/widgets/affirmation_share_sheet.dart';
import '../../../../core/audio/audio_providers.dart';
import '../../../content/presentation/providers/audio_playback_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class TodayAffirmationCard extends ConsumerStatefulWidget {
  const TodayAffirmationCard({super.key});

  @override
  ConsumerState<TodayAffirmationCard> createState() =>
      _TodayAffirmationCardState();
}

class _TodayAffirmationCardState extends ConsumerState<TodayAffirmationCard> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCard(AffirmationModel affirmation) async {
    if (_isSharing) return;
    _isSharing = true;
    HapticFeedback.mediumImpact();

    final shareText = affirmation.englishMeaning.trim().isNotEmpty
        ? affirmation.englishMeaning.trim()
        : (affirmation.santaliPhonetic.trim().isNotEmpty
              ? affirmation.santaliPhonetic.trim()
              : "Today's wisdom from Olitun 🪶");

    try {
      Uint8List? watermarkedBytes;

      try {
        final boundary =
            _repaintKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        // NOTE: never gate on boundary.debugNeedsPaint — it is assert-backed
        // and THROWS in release/profile builds, silently killing the share
        // screenshot. toImage() itself is the safe timing check.
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.5);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );

          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            final paint = Paint();

            final capturedImage = await _loadImage(pngBytes);
            canvas.drawImage(capturedImage, Offset.zero, paint);

            final watermarkStyle = TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            );
            final textSpan = TextSpan(text: 'Olitun 🪶', style: watermarkStyle);
            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            final textOffset = Offset(
              capturedImage.width - textPainter.width - 40,
              capturedImage.height - textPainter.height - 40,
            );
            textPainter.paint(canvas, textOffset);

            final watermarkImage = await recorder.endRecording().toImage(
              capturedImage.width,
              capturedImage.height,
            );
            final watermarkByteData = await watermarkImage.toByteData(
              format: ui.ImageByteFormat.png,
            );

            if (watermarkByteData != null) {
              watermarkedBytes = watermarkByteData.buffer.asUint8List();
            }
          }
        }
      } catch (imgErr) {
        AppLogger.debug('⚠️ Image capture fallback: $imgErr');
      }

      if (!mounted) return;

      if (watermarkedBytes != null) {
        // Step 2 in 2-step activation workflow: Show share sheet preview
        await AffirmationShareSheet.show(
          context,
          affirmation: affirmation,
          imageBytes: watermarkedBytes,
          shareText: shareText,
        );
      } else {
        // Text-only fallback if image capture failed
        final service = ref.read(affirmationShareServiceProvider);
        await service.shareText(
          text: shareText,
          title: "Today's Wisdom · Olitun 🪶",
        );
      }
    } catch (e) {
      AppLogger.debug('❌ Failed to share affirmation card: $e');
      if (mounted) {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wisdom copied to clipboard! 📋'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<ui.Image> _loadImage(Uint8List imgBytes) async {
    final codec = await ui.instantiateImageCodec(imgBytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _toggleAudio(String? audioUrl, String affirmationId) async {
    if (audioUrl == null) return;
    HapticFeedback.lightImpact();

    // Truth comes from audioIsPlayingProvider (player state stream), so a
    // failed load or natural completion can never leave a stuck 'Stop'.
    // Playback routes through the central controller (one global player).
    final playback = ref.read(playbackControllerProvider);
    if (ref.read(audioIsPlayingProvider).value == true) {
      await playback.stop();
    } else {
      await playback.playSingle(
        id: audioUrl,
        contentKind: 'affirmation',
        contentId: affirmationId,
        trackType: 'targetNormal',
        languageCode: 'sat',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAffAsync = ref.watch(todayAffirmationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlaying = ref.watch(audioIsPlayingProvider).value == true;

    return todayAffAsync.when(
      data: (affirmation) {
        if (affirmation == null) return const SizedBox.shrink();

        final isRead = ref.watch(todayAffirmationReadProvider);

        final backgroundGradient = isDark
            ? const LinearGradient(
                colors: [Color(0xFF101724), Color(0xFF0B1220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFF0FDF4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

        return RepaintBoundary(
          key: _repaintKey,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.09)
                    : const Color(0xFFE3E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : const Color(0xFF0F172A).withValues(alpha: 0.07),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -14,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.08 : 0.07,
                  ),
                  blurRadius: 48,
                  offset: const Offset(0, 12),
                  spreadRadius: -20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Emerald top hairline
                  Positioned(
                    top: 0,
                    left: 32,
                    right: 32,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1EE088), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -24,
                    bottom: -28,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 168,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.035)
                          : AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: Color(0xFF00A355),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "TODAY'S WISDOM",
                              style: AppTypography.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                                color: Color(0xFF00A355),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            affirmation.olChikiText,
                            style: TextStyle(
                              fontFamily: 'OlChiki',
                              fontFamilyFallback: const ['Inter', 'sans-serif'],
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.45,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (affirmation.englishMeaning.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            affirmation.englishMeaning.trim(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontSize: 13.5,
                              height: 1.5,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Divider(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE3E8F0),
                          height: 1,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (affirmation.audioUrl != null)
                              _ActionButton(
                                icon: isPlaying
                                    ? Icons.stop_rounded
                                    : Icons.volume_up_rounded,
                                label: isPlaying
                                    ? AppLocalizations.of(
                                        context,
                                      )!.affirmationStop
                                    : AppLocalizations.of(
                                        context,
                                      )!.affirmationListen,
                                isDark: isDark,
                                onTap: () => _toggleAudio(
                                  affirmation.audioUrl,
                                  affirmation.id,
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            _ActionButton(
                              icon: isRead
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              label: isRead ? 'Read' : 'Mark Read',
                              color: isRead ? Colors.green : null,
                              isDark: isDark,
                              onTap: isRead
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(
                                            todayAffirmationReadProvider
                                                .notifier,
                                          )
                                          .markAsRead();
                                    },
                            ),
                            _ActionButton(
                              icon: Icons.share_rounded,
                              label: 'Share',
                              isDark: isDark,
                              onTap: () => _shareCard(affirmation),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? (isDark ? Colors.white70 : const Color(0xFF475569));
    final disabled = onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: disabled
                ? Colors.transparent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFF0F172A).withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE3E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: disabled
                    ? resolvedColor.withValues(alpha: 0.4)
                    : resolvedColor,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: disabled
                      ? resolvedColor.withValues(alpha: 0.4)
                      : resolvedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
