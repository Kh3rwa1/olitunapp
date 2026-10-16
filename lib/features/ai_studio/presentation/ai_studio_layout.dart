import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'ai_studio_session.dart';

/// Dark-mode atmospheric background. Must be a direct [Stack] child.
class StudioAtmosphere extends StatelessWidget {
  const StudioAtmosphere({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return const SizedBox.shrink();
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.translatorDarkBg,
              AppColors.translatorDarkMid,
              AppColors.studioAtmosphereDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -100,
              child: Container(
                width: 440,
                height: 440,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.bakhedGlowBlue.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Studio navigation header with back, title, [statusBadge] and the
/// converter shortcut.
class StudioAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudioAppBar({super.key, required this.statusBadge});

  final Widget statusBadge;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark
          ? AppColors.translatorDarkBg.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 52,
      leadingWidth: 50,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.06,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.aiStudioTitle,
            style: AppTypography.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          statusBadge,
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Center(
            child: IconButton(
              tooltip: l10n.aiStudioLookingForConverter,
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              onPressed: () => context.push('/translate'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill capsule for switching between the studio tools.
class StudioToolSwitcher extends StatelessWidget {
  const StudioToolSwitcher({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final StudioTool selected;
  final ValueChanged<StudioTool> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final tool in StudioTool.values)
              _StudioToolPill(
                tool: tool,
                selected: selected == tool,
                onTap: () => onSelect(tool),
              ),
          ],
        ),
      ),
    );
  }
}

class _StudioToolPill extends StatelessWidget {
  const _StudioToolPill({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final StudioTool tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      key: Key('tool-${tool.name}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tool.icon,
                size: 14,
                color: selected
                    ? AppColors.elevatedButtonFg
                    : isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                tool.localizedLabel(l10n),
                style: TextStyle(
                  color: selected
                      ? AppColors.elevatedButtonFg
                      : isDark
                      ? Colors.white70
                      : Colors.black87,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-screen viewport: two columns on wide layouts, a flip card (input
/// front, result back) on mobile.
class StudioWorkspaceBody extends StatelessWidget {
  const StudioWorkspaceBody({
    super.key,
    required this.isWide,
    required this.configured,
    required this.toolSwitcher,
    required this.inputPanel,
    required this.resultPanel,
    required this.flipKey,
    required this.flipController,
  });

  final bool isWide;
  final bool configured;
  final Widget toolSwitcher;
  final Widget inputPanel;
  final Widget resultPanel;
  final Key flipKey;
  final FlipCardController flipController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isWide ? _desktop(l10n, isDark) : _mobile(l10n, isDark);
  }

  // ── Desktop Single Screen Viewport (Two Columns, Non-Scrollable) ──────
  Widget _desktop(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toolSwitcher,
          const SizedBox(height: 12),
          if (!configured) ...[
            StudioNotice(
              l10n.aiStudioNotConfigured,
              icon: Icons.cloud_off_outlined,
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: inputPanel),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: resultPanel),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiStudioDisclaimer,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Mobile Flip Viewport (Input front, Result back) ──────────────────
  Widget _mobile(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toolSwitcher,
          const SizedBox(height: 8),
          if (!configured) ...[
            StudioNotice(
              l10n.aiStudioNotConfigured,
              icon: Icons.cloud_off_outlined,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: FlipCard(
              key: flipKey,
              controller: flipController,
              rotateSide: RotateSide.right,
              animationDuration: const Duration(milliseconds: 550),
              frontWidget: inputPanel,
              backWidget: resultPanel,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aiStudioDisclaimer,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Glass studio workspace card.
class StudioCard extends StatelessWidget {
  const StudioCard({
    super.key,
    required this.header,
    required this.body,
    this.footer,
    this.filler,
    required this.flex,
    required this.isMobile,
  });

  final Widget header;
  final Widget body;
  final Widget? footer;

  /// Fills whatever height the body leaves free above the footer (flex
  /// layout only). It is given exactly that height, or none.
  final Widget? filler;
  final bool flex;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final footer = this.footer;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.studioCardDark : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            SizedBox(height: isMobile ? 10 : 14),
            if (flex && filler != null)
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: body),
                    SliverFillRemaining(child: filler),
                  ],
                ),
              )
            else if (flex)
              Expanded(child: SingleChildScrollView(child: body))
            else
              body,
            if (footer != null) ...[
              SizedBox(height: isMobile ? 10 : 14),
              footer,
            ],
          ],
        ),
      ),
    );
  }
}

/// Info / error notice banner (live region).
class StudioNotice extends StatelessWidget {
  const StudioNotice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.error = false,
  });

  final String text;
  final IconData icon;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = error
        ? (isDark
              ? AppColors.studioNoticeErrorDark
              : AppColors.studioNoticeErrorLight)
        : (isDark
              ? AppColors.studioNoticeInfoDark
              : AppColors.studioNoticeInfoLight);
    final fg = error
        ? AppColors.studioNoticeErrorFg
        : (isDark ? Colors.white70 : AppColors.studioNoticeInfoFg);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: error
                ? AppColors.error.withValues(alpha: 0.3)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: fg,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
