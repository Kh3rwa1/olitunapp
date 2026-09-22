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
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;
    return SliverAppBar(
      expandedHeight: isDesktop ? 320.0 : 260.0,
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
                  // Emerald depth orbs
                  Positioned(
                    right: -60,
                    top: -70,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 60,
                    top: 20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -60,
                    bottom: -60,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Giant Ol Chiki watermark — the $10B signature.
                  Positioned(
                    right: isDesktop ? 48 : 16,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Text(
                        category.titleOlChiki.isNotEmpty
                            ? category.titleOlChiki.characters
                                  .take(3)
                                  .toString()
                            : 'ᱚᱞ',
                        style: TextStyle(
                          fontFamily: 'OlChiki',
                          fontSize: isDesktop ? 150 : 110,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                  // Bottom fade into page canvas
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content layout
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 880 : double.infinity,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 44 : 20,
                          MediaQuery.of(context).padding.top + 56,
                          isDesktop ? 44 : 20,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Breadcrumb
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.canPop()
                                      ? context.pop()
                                      : context.go('/'),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Text(
                                      'LEARN',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.6,
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  category.titleLatin.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.6,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (category.titleOlChiki.isNotEmpty) ...[
                              Text(
                                category.titleOlChiki,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 1.2,
                                  fontFamily: 'OlChiki',
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              category.titleLatin,
                              style: TextStyle(
                                fontFamily: primaryLocalizedFontFamily(
                                  scriptMode,
                                ),
                                fontSize: isDesktop ? 46 : 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.2,
                                height: 1.02,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            if (category.description != null &&
                                category.description!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isDesktop ? 560 : 480,
                                ),
                                child: Text(
                                  category.description!,
                                  style: TextStyle(
                                    fontSize: isDesktop ? 15 : 13.5,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
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
                                  if (isDesktop) ...[
                                    const SizedBox(width: 8),
                                    _buildHeaderBadge(
                                      icon: Icons.timer_outlined,
                                      label: '~5 min each',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
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
