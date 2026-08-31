import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../shared/utils/localized_content.dart';
import '../../../../categories/domain/entities/category_entity.dart';

class CategoryHeroHeader extends StatelessWidget {
  final CategoryEntity category;
  final LinearGradient brandGradient;
  final String scriptMode;
  final bool isDark;

  const CategoryHeroHeader({
    super.key,
    required this.category,
    required this.brandGradient,
    required this.scriptMode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      leadingWidth: 72,
      leading: _buildBackButton(context, isDark),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final isCollapsed =
              top <= kToolbarHeight + MediaQuery.of(context).padding.top;

          return FlexibleSpaceBar(
            centerTitle: true,
            title: isCollapsed
                ? Text(
                    category.titleLatin,
                    style: TextStyle(
                      fontFamily: primaryLocalizedFontFamily(scriptMode),
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  )
                : null,
            background: Container(
              decoration: BoxDecoration(gradient: brandGradient),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Decorative ambient overlays
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -50,
                    bottom: -30,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Content layout
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 48,
                      20,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (category.titleOlChiki.isNotEmpty) ...[
                          Text(
                            category.titleOlChiki,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                              fontFamily: 'OlChiki',
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          category.titleLatin,
                          style: TextStyle(
                            fontFamily: primaryLocalizedFontFamily(scriptMode),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (category.description != null &&
                            category.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            category.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildHeaderBadge(
                                icon: Icons.menu_book_rounded,
                                label:
                                    '${category.totalLessons > 0 ? category.totalLessons : 5} Lessons',
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderBadge(
                                icon: Icons.stars_rounded,
                                label: 'Free Access',
                              ),
                              const SizedBox(width: 8),
                              _buildHeaderBadge(
                                icon: Icons.cloud_done_rounded,
                                label: 'Offline Ready',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PressableScale(
          onTap: () => context.canPop() ? context.pop() : context.go('/'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
