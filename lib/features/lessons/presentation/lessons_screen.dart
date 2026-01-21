import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';

class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Lessons',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryLessonCard(
            category: category,
            isDark: isDark,
            index: index,
            onTap: () => context.go('/lessons/category/${category.id}'),
          );
        },
      ),
    );
  }
}

class _CategoryLessonCard extends StatelessWidget {
  final dynamic category;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const _CategoryLessonCard({
    required this.category,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  LinearGradient _getGradient(String preset) {
    switch (preset) {
      case 'skyBlue': return AppColors.skyBlueGradient;
      case 'peach': return AppColors.peachGradient;
      case 'mint': return AppColors.mintGradient;
      case 'sunset': return AppColors.sunsetGradient;
      case 'purple': return AppColors.purpleGradient;
      default: return AppColors.skyBlueGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient(category.gradientPreset);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.titleLatin,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (category.titleOlChiki.isNotEmpty)
                      Text(
                        category.titleOlChiki,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'OlChiki',
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    if (category.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          category.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: -0.1);
  }
}
