part of 'admin_sidebar.dart';

// Collapsible navigation groups used by the admin sidebar.

class _CollapsibleNavGroup extends ConsumerStatefulWidget {
  final String label;
  final String persistenceKey;
  final bool isCompact;
  final bool hasActiveChild;
  final List<Widget> children;

  const _CollapsibleNavGroup({
    required this.label,
    required this.persistenceKey,
    required this.isCompact,
    this.hasActiveChild = false,
    required this.children,
  });

  @override
  ConsumerState<_CollapsibleNavGroup> createState() =>
      _CollapsibleNavGroupState();
}

class _CollapsibleNavGroupState extends ConsumerState<_CollapsibleNavGroup> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final stored = prefs.getBool(
        'admin_sidebar_group_${widget.persistenceKey}',
      );
      if (stored != null && mounted) {
        setState(() => _isExpanded = stored);
      }
    } catch (_) {
      // Prefs unavailable — keep the default expanded state.
    }
  }

  Future<void> _toggle() async {
    final next = !_isExpanded;
    setState(() => _isExpanded = next);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('admin_sidebar_group_${widget.persistenceKey}', next);
    } catch (e) {
      // Persisting the toggle is best-effort; UI state is already updated,
      // but log the missed write so collapsed state loss is diagnosable.
      AppLogger.warning(
        'AdminSidebarNavGroups: failed to persist group state: $e',
        name: 'AdminSidebarNavGroups',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(label: widget.label, isCompact: true),
          ...widget.children,
          const SizedBox(height: 12),
        ],
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivelyExpanded = _isExpanded || widget.hasActiveChild;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: '${widget.label} navigation section',
          button: true,
          expanded: effectivelyExpanded,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: AdminTokens.eyebrow(isDark).copyWith(
                      fontSize: 10.5,
                      color: AdminTokens.textMuted(isDark),
                      letterSpacing: 1.6,
                    ),
                  ),
                  Icon(
                    effectivelyExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AdminTokens.textMuted(isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (effectivelyExpanded) ...widget.children,
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isCompact;
  const _SectionLabel({required this.label, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            width: 18,
            height: 2,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white12
                  : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Text(
        label,
        style: AdminTokens.eyebrow(isDark).copyWith(
          fontSize: 10.5,
          color: AdminTokens.textMuted(isDark),
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}
