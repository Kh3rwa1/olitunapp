part of 'lesson_block_card.dart';

// Live visual-preview sections rendered inside [LessonBlockCard].

class _BlockLivePreview extends StatelessWidget {
  final LessonBlockEntity block;
  final bool isDark;

  const _BlockLivePreview({required this.block, required this.isDark});

  @override
  Widget build(BuildContext context) => _buildLivePreview(context);

  Widget _buildLivePreview(BuildContext context) {
    switch (block.type) {
      case 'text':
        final hasText =
            block.textOlChiki != null && block.textOlChiki!.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasText ? block.textOlChiki! : 'No Ol Chiki text entered',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: hasText ? AppColors.primary : Colors.grey,
              ),
            ),
            if (block.textLatin != null && block.textLatin!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                block.textLatin!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ],
        );

      case 'image':
      case 'svg':
        final url = block.imageUrl;
        final isSvg =
            block.type == 'svg' ||
            (url?.toLowerCase().endsWith('.svg') ?? false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null && url.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  width: double.infinity,
                  height: 140,
                  child: isSvg
                      ? AnimatedSvgDisplay(
                          url: url,
                          placeholder: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.grey,
                                  size: 36,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Failed to load SVG',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, trace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.grey,
                                  size: 36,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              )
            else
              _buildEmptyPreview(
                block.type == 'svg'
                    ? Icons.polyline_rounded
                    : Icons.image_outlined,
                block.type == 'svg'
                    ? 'No SVG uploaded yet'
                    : 'No image uploaded yet',
              ),
            _buildCaption(),
          ],
        );

      case 'lottie':
        final url = block.data?['animationUrl'] ?? block.imageUrl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null && url.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: 140,
                  child: Center(
                    child: LottieDisplay(
                      url: url,
                      height: 120,
                      errorWidget: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey,
                            size: 36,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Failed to load Lottie animation',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              _buildEmptyPreview(
                Icons.animation_rounded,
                'No animation uploaded yet',
              ),
            _buildCaption(),
          ],
        );

      case 'video':
        // Safe check: Video URL might be in block.imageUrl or block.audioUrl (older versions)
        final url = block.imageUrl ?? block.audioUrl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null && url.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  color: Colors.black.withValues(alpha: 0.05),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          size: 44,
                          color: Colors.purple,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Video loaded successfully',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _buildEmptyPreview(
                Icons.videocam_outlined,
                'No video uploaded yet',
              ),
            _buildCaption(),
          ],
        );

      case 'audio':
        final url = block.audioUrl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null && url.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Track',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Audio stream validated & ready',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.orange.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              )
            else
              _buildEmptyPreview(
                Icons.audiotrack_outlined,
                'No audio uploaded yet',
              ),
            _buildCaption(),
          ],
        );

      case 'quiz':
        final refId = block.data?['quizId'] ?? block.data?['quizRefId'];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.premiumPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiz Invitation Card',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      refId != null && refId.toString().isNotEmpty
                          ? 'Ref ID: $refId'
                          : 'No Quiz Reference Selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        );

      case 'glyph':
        final hasOl =
            block.textOlChiki != null && block.textOlChiki!.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasOl ? block.textOlChiki! : 'No Ol Chiki glyph entered',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC4899),
              ),
            ),
            if (block.textLatin != null && block.textLatin!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Pronounced: ${block.textLatin!}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ],
        );

      case 'callout':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Text(
            block.textLatin ?? 'Callout note text',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        );

      case 'tracing':
        final glyph = block.data?['glyph'] as String? ?? '';
        return Row(
          children: [
            const Icon(Icons.gesture_rounded, color: Color(0xFF14B8A6)),
            const SizedBox(width: 8),
            Text(
              'Tracing Canvas: $glyph',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        );

      default:
        return Text(
          'Block preview unavailable for type: ${block.type}',
          style: const TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildEmptyPreview(IconData icon, String message) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey.withValues(alpha: 0.4), size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    if (block.textLatin != null && block.textLatin!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Caption: "${block.textLatin!}"',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
