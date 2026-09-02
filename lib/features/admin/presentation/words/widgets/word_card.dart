import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';
import '../../widgets/admin_glass_card.dart';

class WordCard extends StatefulWidget {
  final WordModel word;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canDelete;

  const WordCard({
    super.key,
    required this.word,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    this.canDelete = true,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AdminGlassCard(
          padding: const EdgeInsets.all(18),
          border: Border.all(
            color: _hovering
                ? AppColors.primary.withValues(alpha: 0.4)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: _hovering
              ? AdminTokens.brandGlow(AppColors.primary, strength: 0.2)
              : null,
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    word.wordOlChiki.isNotEmpty ? word.wordOlChiki[0] : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          word.wordOlChiki,
                          style: AdminTokens.cardTitle(
                            isDark,
                          ).copyWith(fontSize: 17),
                        ),
                        Text(
                          word.wordLatin,
                          style: AdminTokens.body(isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.meaning,
                      style: AdminTokens.body(
                        isDark,
                      ).copyWith(color: AdminTokens.textSecondary(isDark)),
                    ),
                    if (word.category != null && word.category!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            label: word.category!,
                            color: AppColors.primary,
                            background: AdminTokens.accentSoft(isDark),
                            border: AdminTokens.accentBorder(isDark),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_hovering) ...[
                IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: widget.onEdit,
                  tooltip: 'Edit',
                ),
                if (widget.canDelete)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                  ),
              ] else
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: AdminTokens.textTertiary(isDark),
                  ),
                  tooltip: 'Edit word',
                  onPressed: widget.onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.background,
    required this.border,
  });

  final String label;
  final Color color;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
