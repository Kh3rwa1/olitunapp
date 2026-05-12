import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';

class WordCard extends StatefulWidget {
  final WordModel word;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WordCard({
    super.key,
    required this.word,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.word;
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
                  w.wordOlChiki.isNotEmpty ? w.wordOlChiki[0] : '?',
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
                  Row(
                    children: [
                      Text(
                        w.wordOlChiki,
                        style: AdminTokens.cardTitle(
                          isDark,
                        ).copyWith(fontSize: 17),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        w.wordLatin,
                        style: AdminTokens.body(isDark).copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    w.meaning,
                    style: AdminTokens.body(
                      isDark,
                    ).copyWith(color: AdminTokens.textSecondary(isDark)),
                  ),
                  if (w.category != null && w.category!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTokens.accentSoft(isDark),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AdminTokens.accentBorder(isDark),
                        ),
                      ),
                      child: Text(
                        w.category!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
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
