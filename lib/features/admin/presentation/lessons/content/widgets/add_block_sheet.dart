import 'package:flutter/material.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';

class AddBlockSheet extends StatelessWidget {
  final ValueChanged<String> onSelectType;

  const AddBlockSheet({super.key, required this.onSelectType});

  static void show(BuildContext context, ValueChanged<String> onSelectType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBlockSheet(onSelectType: onSelectType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Block Type',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                color: AppColors.duoBlue,
                type: 'image',
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
