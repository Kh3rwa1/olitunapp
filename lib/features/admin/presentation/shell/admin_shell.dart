import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../providers/admin_auth_provider.dart';
import 'widgets/admin_brand_mark.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    final isDesktop = width > 1180;
    final isTablet = width > 760 && width <= 1180;

    final adminAsync = ref.watch(adminAuthProvider);
    if (adminAsync.isLoading) {
      return Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (adminAsync.value != true) {
      return Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTokens.accentSoft(isDark),
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminTokens.accentBorder(isDark)),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Admin access required',
                style: AdminTokens.sectionTitle(isDark),
              ),
            ],
          ),
        ),
      );
    }

    _warmAdminContent(ref);

    if (isDesktop || isTablet) {
      return Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        body: Stack(
          children: [
            _buildAmbientBackdrop(isDark),
            Row(
              children: [
                Container(
                  width: isDesktop ? 272 : 84,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A0E15).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.85),
                    border: Border(
                      right: BorderSide(color: AdminTokens.divider(isDark)),
                    ),
                  ),
                  child: AdminSidebar(isCompact: !isDesktop),
                ),
                Expanded(
                  child: Column(
                    children: [
                      AdminTopBar(isDark: isDark),
                      Expanded(
                        child: ClipRect(
                          child: Material(
                            color: Colors.transparent,
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Mobile
    return Scaffold(
      backgroundColor: AdminTokens.base(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AdminTokens.textPrimary(isDark),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdminBrandMark(size: 28),
            const SizedBox(width: 10),
            Text('Olitun CMS', style: AdminTokens.cardTitle(isDark)),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: AdminTokens.raised(isDark),
        width: 288,
        child: const AdminSidebar(),
      ),
      body: Stack(
        children: [
          _buildAmbientBackdrop(isDark),
          Material(color: Colors.transparent, child: child),
        ],
      ),
    );
  }

  void _warmAdminContent(WidgetRef ref) {
    ref
      ..read(categoryNotifierProvider)
      ..read(lessonNotifierProvider)
      ..read(featuredBannersProvider)
      ..read(lettersProvider)
      ..read(numbersProvider)
      ..read(wordsProvider)
      ..read(sentencesProvider)
      ..read(quizzesProvider)
      ..read(rhymesProvider)
      ..read(rhymeCategoriesProvider)
      ..read(rhymeSubcategoriesProvider);
  }

  Widget _buildAmbientBackdrop(bool isDark) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.9),
              radius: 1.4,
              colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
