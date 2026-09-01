import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/sharing/growth_share_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'share_card_payload.dart';
import 'social_share_card.dart';

class SocialShareModal extends StatefulWidget {
  final ShareCardPayload payload;
  final GrowthShareService shareService;

  const SocialShareModal({
    super.key,
    required this.payload,
    this.shareService = const GrowthShareService(),
  });

  static Future<void> show(
    BuildContext context, {
    required ShareCardPayload payload,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return SocialShareModal(payload: payload);
      },
    );
  }

  @override
  State<SocialShareModal> createState() => _SocialShareModalState();
}

class _SocialShareModalState extends State<SocialShareModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _handleShare() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final imageBytes = await widget.shareService.captureWidgetToImage(
        _cardKey,
      );

      if (imageBytes != null) {
        final outcome = await widget.shareService.shareCardImage(
          imageBytes: imageBytes,
          filename:
              'olitun_${widget.payload.kind.name}_${DateTime.now().millisecondsSinceEpoch}.png',
          title: widget.payload.title,
          text: widget.payload.shareMessage,
        );

        if (mounted) {
          if (outcome == ShareOutcome.copiedToClipboard) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Share text copied to clipboard! 📋'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // Fallback to text share
        await widget.shareService.shareText(
          text: widget.payload.shareMessage,
          title: widget.payload.title,
        );
      }
    } catch (e) {
      AppLogger.debug('Share failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleCopyText() async {
    HapticFeedback.selectionClick();
    final outcome = await widget.shareService.copyTextToClipboard(
      widget.payload.shareMessage,
    );

    if (mounted) {
      if (outcome == ShareOutcome.copiedToClipboard) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share message copied to clipboard! 📋'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: AppRadius.topXxl,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Title
              Text(
                'Share Your Milestone',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Inspire others to learn Santali & Ol Chiki',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Rendered Share Card with RepaintBoundary
              RepaintBoundary(
                key: _cardKey,
                child: SocialShareCard(payload: widget.payload),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _handleShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderXl,
                    ),
                  ),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    _isSharing ? 'Preparing...' : 'Share to Apps',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _handleCopyText,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderXl,
                    ),
                  ),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  label: Text(
                    'Copy Text Summary',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
