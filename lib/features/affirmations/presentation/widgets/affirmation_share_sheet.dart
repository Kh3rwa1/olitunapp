import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../data/affirmation_share_service_provider.dart';
import '../../domain/affirmation_share_service.dart';

class AffirmationShareSheet extends ConsumerStatefulWidget {
  final AffirmationModel affirmation;
  final Uint8List imageBytes;
  final String shareText;

  const AffirmationShareSheet({
    super.key,
    required this.affirmation,
    required this.imageBytes,
    required this.shareText,
  });

  static Future<void> show(
    BuildContext context, {
    required AffirmationModel affirmation,
    required Uint8List imageBytes,
    required String shareText,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AffirmationShareSheet(
        affirmation: affirmation,
        imageBytes: imageBytes,
        shareText: shareText,
      ),
    );
  }

  @override
  ConsumerState<AffirmationShareSheet> createState() =>
      _AffirmationShareSheetState();
}

class _AffirmationShareSheetState extends ConsumerState<AffirmationShareSheet> {
  bool _isProcessing = false;

  Future<void> _handleShareImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final service = ref.read(affirmationShareServiceProvider);
      final filename =
          'olitun_wisdom_${widget.affirmation.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png';

      final result = await service.shareImage(
        imageBytes: widget.imageBytes,
        filename: filename,
        title: "Today's Wisdom · Olitun 🪶",
        text: widget.shareText,
      );

      if (!mounted) return;
      _handleResult(result);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDownloadImage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final service = ref.read(affirmationShareServiceProvider);
      final filename =
          'olitun_wisdom_${widget.affirmation.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png';

      final result = await service.downloadImage(
        imageBytes: widget.imageBytes,
        filename: filename,
      );

      if (!mounted) return;
      _handleResult(result);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleShareText() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final service = ref.read(affirmationShareServiceProvider);
      final result = await service.shareText(
        text: widget.shareText,
        title: "Today's Wisdom · Olitun 🪶",
      );

      if (!mounted) return;
      _handleResult(result);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCopyText() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final service = ref.read(affirmationShareServiceProvider);
      final result = await service.copyToClipboard(widget.shareText);

      if (!mounted) return;
      _handleResult(result);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleResult(AffirmationShareResult result) {
    Navigator.of(context).pop();

    switch (result) {
      case AffirmationShareResult.shared:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wisdom card shared! 🪶'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case AffirmationShareResult.downloaded:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wisdom card saved! 📥'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case AffirmationShareResult.textCopied:
      case AffirmationShareResult.linkCopied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wisdom copied to clipboard! 📋'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case AffirmationShareResult.cancelled:
        // Clean dismiss without error banner
        break;
      case AffirmationShareResult.unsupported:
      case AffirmationShareResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sharing encountered an issue. Try copying text instead.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Wisdom Card',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Image Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 20),

            // Actions Grid / Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleShareImage,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Share Image',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _handleDownloadImage,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Download PNG',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isProcessing ? null : _handleShareText,
                    icon: const Icon(Icons.text_fields_rounded, size: 16),
                    label: const Text('Share Text Only'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isProcessing ? null : _handleCopyText,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Text'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
