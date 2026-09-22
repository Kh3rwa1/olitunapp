import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../categories/domain/entities/category_entity.dart';

class CategoryEmptyState extends StatelessWidget {
  final bool isDark;
  final CategoryEntity? category;

  const CategoryEmptyState({super.key, required this.isDark, this.category});

  @override
  Widget build(BuildContext context) {
    final id = category?.id ?? '';
    final isAlphabet =
        id == 'cat_alphabets' || id == 'cat_letters' || id == 'letters';
    final reduceMotion = RespectMotion.of(context);

    Widget entrance(Widget child, int step, {bool pop = false}) {
      if (reduceMotion) return child;
      final animated = child
          .animate()
          .fadeIn(
            delay: MotionTokens.staggerFor(step),
            duration: MotionTokens.medium,
          )
          .slideY(
            begin: 0.12,
            end: 0,
            delay: MotionTokens.staggerFor(step),
            duration: MotionTokens.medium,
            curve: MotionTokens.emphasized,
          );
      return pop
          ? animated.scale(
              delay: MotionTokens.staggerFor(step),
              duration: MotionTokens.long,
              curve: MotionTokens.playfulSpring,
            )
          : animated;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          entrance(
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isAlphabet ? Icons.translate_rounded : Icons.school_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            0,
            pop: true,
          ),
          const SizedBox(height: 24),
          entrance(
            Text(
              isAlphabet ? 'Alphabet Dictionary' : 'No lessons yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            1,
          ),
          const SizedBox(height: 8),
          entrance(
            Text(
              isAlphabet
                  ? 'Browse all available Ol Chiki letters'
                  : 'Check back soon for new content',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            2,
          ),
          if (isAlphabet) ...[
            const SizedBox(height: 24),
            entrance(
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/letter/standalone/all');
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Open Dictionary'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              3,
            ),
          ],
        ],
      ),
    );
  }
}
