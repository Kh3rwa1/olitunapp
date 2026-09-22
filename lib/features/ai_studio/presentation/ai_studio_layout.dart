part of 'ai_studio_screen.dart';

extension _AiStudioLayout on _AiStudioScreenState {
  // ── Atmospheric Background ───────────────────────────────────────────
  Widget _buildAtmosphere(bool isDark) {
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

  // ── Sleek Studio Navigation Header ────────────────────────────────────
  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, bool isDark) {
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
          _statusBadge(l10n, ref.watch(aiStudioServiceProvider).configured),
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

  // ── Tool Switcher Pill Capsule ───────────────────────────────────────
  Widget _buildToolSwitcher(AppLocalizations l10n, bool isDark) {
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
            for (final tool in _Tool.values) _toolPill(tool, l10n, isDark),
          ],
        ),
      ),
    );
  }

  Widget _toolPill(_Tool tool, AppLocalizations l10n, bool isDark) {
    final selected = _tool == tool;
    return Material(
      key: Key('tool-${tool.name}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => _selectTool(tool),
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

  // ── Desktop Single Screen Viewport (Two Columns, Non-Scrollable) ──────
  Widget _buildDesktopSingleScreenBody(
    bool configured,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolSwitcher(l10n, isDark),
          const SizedBox(height: 12),
          if (!configured) ...[
            _notice(l10n.aiStudioNotConfigured, icon: Icons.cloud_off_outlined),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _inputPanel(
                    configured,
                    l10n,
                    isDark,
                    flex: true,
                    isMobile: false,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: _resultPanel(
                    l10n,
                    isDark,
                    flex: true,
                    isMobile: false,
                  ),
                ),
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
  Widget _buildMobileSingleScreenBody(
    bool configured,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolSwitcher(l10n, isDark),
          const SizedBox(height: 8),
          if (!configured) ...[
            _notice(l10n.aiStudioNotConfigured, icon: Icons.cloud_off_outlined),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: FlipCard(
              key: _flipKey,
              controller: _flip,
              rotateSide: RotateSide.right,
              animationDuration: const Duration(milliseconds: 550),
              frontWidget: _inputPanel(
                configured,
                l10n,
                isDark,
                flex: true,
                isMobile: true,
              ),
              backWidget: _resultPanel(
                l10n,
                isDark,
                flex: true,
                isMobile: true,
              ),
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

  // ── Glass Studio Workspace Card ──────────────────────────────────────
  Widget _studioCard({
    required Widget header,
    required Widget body,
    Widget? footer,
    required bool isDark,
    required bool flex,
    required bool isMobile,
  }) {
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
            if (flex)
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

  // ── Notice Banner ────────────────────────────────────────────────────
  Widget _notice(
    String text, {
    IconData icon = Icons.info_outline,
    bool error = false,
  }) {
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
