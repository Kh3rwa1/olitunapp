import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';

class NumberGrid extends StatelessWidget {
  final List<NumberModel> numbers;
  final bool isDark;
  final bool isWideScreen;
  final ValueChanged<NumberModel> onEdit;
  final ValueChanged<NumberModel> onDelete;

  const NumberGrid({
    super.key,
    required this.numbers,
    required this.isDark,
    required this.isWideScreen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 4 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isWideScreen ? 1.1 : 0.95,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final number = numbers[index];
        return _NumberCard(
          number: number,
          isDark: isDark,
          onEdit: () => onEdit(number),
          onDelete: () => onDelete(number),
        ).animate().fadeIn(delay: (index * 60).ms).scale(
              begin: const Offset(0.95, 0.95),
              duration: 300.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

class _NumberCard extends StatefulWidget {
  final NumberModel number;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NumberCard({
    required this.number,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_NumberCard> createState() => _NumberCardState();
}

class _NumberCardState extends State<_NumberCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.number;
    final isDark = widget.isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onEdit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AdminTokens.raised(isDark),
            borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
            border: Border.all(
              color: _hovering
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AdminTokens.border(isDark),
            ),
            boxShadow: _hovering
                ? AdminTokens.brandGlow(AppColors.primary, strength: 0.3)
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    n.numeral,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                n.nameLatin,
                style: AdminTokens.cardTitle(isDark).copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${n.nameOlChiki} = ${n.value}',
                style: AdminTokens.label(isDark).copyWith(
                  color: AdminTokens.textTertiary(isDark),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (_hovering)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
