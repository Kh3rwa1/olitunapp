import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';

class SentenceCard extends StatefulWidget {
  final SentenceModel sentence;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SentenceCard({
    super.key,
    required this.sentence,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<SentenceCard> createState() => _SentenceCardState();
}

class _SentenceCardState extends State<SentenceCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sentence;
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
          border: Border.all(
            color: _hovering
                ? AppColors.primary.withValues(alpha: 0.4)
                : AdminTokens.border(isDark),
          ),
          boxShadow: _hovering
              ? AdminTokens.brandGlow(AppColors.primary, strength: 0.2)
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
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
                    s.sentenceOlChiki,
                    style: AdminTokens.cardTitle(isDark).copyWith(
                      fontSize: 15,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.sentenceLatin,
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
                    '→ ${s.meaning}',
                    style: AdminTokens.body(isDark).copyWith(
                      color: AdminTokens.textSecondary(isDark),
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (s.category != null && s.category!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        s.category!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_hovering) ...[
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: widget.onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(
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
    );
  }
}
