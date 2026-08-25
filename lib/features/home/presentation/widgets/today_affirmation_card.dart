import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../../../affirmations/data/affirmation_share_service_provider.dart';
import '../../../affirmations/presentation/widgets/affirmation_share_sheet.dart';
import '../../../../core/audio/audio_providers.dart';
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
              fontFamily: 'Poppins',
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

  Future<void> _toggleAudio(String? audioUrl) async {
    if (audioUrl == null) return;
    HapticFeedback.lightImpact();

    // Truth comes from audioIsPlayingProvider (player state stream), so a
    // failed load or natural completion can never leave a stuck 'Stop'.
    if (ref.read(audioIsPlayingProvider).value == true) {
      await ref.read(audioServiceProvider).stop();
    } else {
      await ref.read(audioServiceProvider).playUrl(audioUrl);
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
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFDF8F5), Color(0xFFF5EBE6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );

        final textColor = isDark ? Colors.white : Colors.black87;

        return RepaintBoundary(
          key: _repaintKey,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: backgroundGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black45
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 150,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "TODAY'S WISDOM",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Text(
                            affirmation.olChikiText,
                            style: TextStyle(
                              fontFamily: 'OlChiki',
                              fontFamilyFallback: const [
                                'Poppins',
                                'sans-serif',
                              ],
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.4,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          color: isDark ? Colors.white10 : Colors.black12,
                          height: 1,
                        ),
                        const SizedBox(height: 16),
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
                                onTap: () => _toggleAudio(affirmation.audioUrl),
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
    final resolvedColor = color ?? (isDark ? Colors.white70 : Colors.black54);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onTap == null
                  ? resolvedColor.withValues(alpha: 0.4)
                  : resolvedColor,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: onTap == null
                    ? resolvedColor.withValues(alpha: 0.4)
                    : resolvedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
