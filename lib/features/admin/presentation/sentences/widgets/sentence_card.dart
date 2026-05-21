import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';
import '../../widgets/admin_glass_card.dart';

class SentenceCard extends StatefulWidget {
  final SentenceModel sentence;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canDelete;

  const SentenceCard({
    super.key,
    required this.sentence,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    this.canDelete = true,
  });

  @override
  State<SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<SentenceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final sentence = widget.sentence;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sentence.sentenceOlChiki,
                      style: AdminTokens.cardTitle(
                        isDark,
                      ).copyWith(fontSize: 15, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sentence.sentenceLatin,
                      style: AdminTokens.body(isDark).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '-> ${sentence.meaning}',
                      style: AdminTokens.body(isDark).copyWith(
                        color: AdminTokens.textSecondary(isDark),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sentence.category != null &&
                        sentence.category!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            label: sentence.category!,
                            color: const Color(0xFF10B981),
                            background: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            border: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.3),
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
