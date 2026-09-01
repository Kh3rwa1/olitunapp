import 'package:flutter/material.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';

class AddBlockSheet extends StatelessWidget {
  final ValueChanged<String> onSelectType;

  const AddBlockSheet({super.key, required this.onSelectType});

  static Future<void> show(
    BuildContext context,
    ValueChanged<String> onSelectType,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AddBlockSheet(onSelectType: onSelectType),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radius2xl),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_box_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Add Lesson Block',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              _buildTypeOption(
                context: context,
                icon: Icons.text_fields_rounded,
                label: 'Text',
                color: Colors.blue,
                type: 'text',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.image_rounded,
                label: 'Image',
                color: AppColors.brandBlue,
                type: 'image',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.polyline_rounded,
                label: 'SVG',
                color: const Color(0xFF0EA5E9),
                type: 'svg',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.audiotrack_rounded,
                label: 'Audio',
                color: Colors.orange,
                type: 'audio',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.videocam_rounded,
                label: 'Video',
                color: Colors.purple,
                type: 'video',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.quiz_rounded,
                label: 'Quiz',
                color: Colors.green,
                type: 'quiz',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.animation_rounded,
                label: 'Lottie',
                color: const Color(0xFF10B981),
                type: 'lottie',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.abc_rounded,
                label: 'Glyph',
                color: const Color(0xFFEC4899),
                type: 'glyph',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.lightbulb_rounded,
                label: 'Callout',
                color: const Color(0xFFF59E0B),
                type: 'callout',
              ),
              _buildTypeOption(
                context: context,
                icon: Icons.gesture_rounded,
                label: 'Tracing',
                color: const Color(0xFF14B8A6),
                type: 'tracing',
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String type,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSelectType(type);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
