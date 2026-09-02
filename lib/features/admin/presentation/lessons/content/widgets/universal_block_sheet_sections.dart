part of 'universal_block_sheet.dart';

// ── Private sub-widgets ────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  final bool isDark;
  const _DragHandle({required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white24 : Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

class _SheetHeader extends StatelessWidget {
  final bool isEditing;
  final String inferredType;
  final VoidCallback onClose;
  final bool isDark;

  const _SheetHeader({
    required this.isEditing,
    required this.inferredType,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.add_box_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit lesson block' : 'Add lesson block',
                style: AdminTokens.sectionTitle(isDark).copyWith(fontSize: 18),
              ),
              Text(
                'Detected type: $inferredType',
                style: AdminTokens.label(isDark),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close block editor',
          onPressed: onClose,
          color: AdminTokens.textTertiary(isDark),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;
  final bool isDark;

  const _SectionLabel(this.text, {this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text, style: AdminTokens.bodyStrong(isDark)),
      if (subtitle != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle!, style: AdminTokens.label(isDark)),
        ),
    ],
  );
}

class _AdvancedToggle extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  final bool isDark;

  const _AdvancedToggle({
    required this.open,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: AdminTokens.textSecondary(isDark),
          ),
          const SizedBox(width: 8),
          Text('Advanced', style: AdminTokens.bodyStrong(isDark)),
        ],
      ),
    ),
  );
}

class _CalloutPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _CalloutPicker({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  static const _options = <String?, String>{
    null: 'None',
    'info': 'Info',
    'tip': 'Tip',
    'warning': 'Warning',
    'success': 'Success',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Callout style', style: AdminTokens.bodyStrong(isDark)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _options.entries
            .map(
              (e) => ChoiceChip(
                label: Text(e.value),
                selected: value == e.key,
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                onSelected: (_) => onChanged(e.key),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _ThemeColorPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _ThemeColorPicker({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  static const _presets = <String, Color>{
    '#34D399': Color(0xFF34D399),
    '#22D3EE': Color(0xFF22D3EE),
    '#60A5FA': Color(0xFF60A5FA),
    '#F472B6': Color(0xFFF472B6),
    '#FBBF24': Color(0xFFFBBF24),
    '#374151': Color(0xFF374151),
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Theme color', style: AdminTokens.bodyStrong(isDark)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _swatch(null, Colors.transparent, isNone: true),
          for (final e in _presets.entries) _swatch(e.key, e.value),
        ],
      ),
    ],
  );

  Widget _swatch(String? key, Color color, {bool isNone = false}) =>
      GestureDetector(
        onTap: () => onChanged(key),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: value == key ? AppColors.primary : Colors.black12,
              width: value == key ? 2.5 : 1,
            ),
          ),
          child: isNone
              ? const Icon(Icons.block_rounded, size: 16, color: Colors.grey)
              : null,
        ),
      );
}
