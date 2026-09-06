part of 'universal_block_sheet.dart';

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

  static Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static final _presets = <String, Color>{
    '#34D399': _parseHex('#34D399'),
    '#22D3EE': _parseHex('#22D3EE'),
    '#60A5FA': _parseHex('#60A5FA'),
    '#F472B6': _parseHex('#F472B6'),
    '#FBBF24': _parseHex('#FBBF24'),
    '#374151': _parseHex('#374151'),
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

class _BlockAdvancedSection extends StatelessWidget {
  final bool open;
  final VoidCallback onToggleOpen;
  final bool isDark;
  final String? audioUrl;
  final ValueChanged<String?> onAudioUploaded;
  final TextEditingController pronCtrl;
  final AsyncValue quizzesAsync;
  final TextEditingController quizRefCtrl;
  final bool showCustomQuizIdInput;
  final ValueChanged<bool> onCustomQuizIdToggled;
  final String? calloutVariant;
  final ValueChanged<String?> onCalloutChanged;
  final bool tracingAllowed;
  final bool tracingEnabled;
  final ValueChanged<bool> onTracingToggled;
  final String? themeColor;
  final ValueChanged<String?> onThemeColorChanged;
  final VoidCallback onStateChange;

  const _BlockAdvancedSection({
    required this.open,
    required this.onToggleOpen,
    required this.isDark,
    required this.audioUrl,
    required this.onAudioUploaded,
    required this.pronCtrl,
    required this.quizzesAsync,
    required this.quizRefCtrl,
    required this.showCustomQuizIdInput,
    required this.onCustomQuizIdToggled,
    required this.calloutVariant,
    required this.onCalloutChanged,
    required this.tracingAllowed,
    required this.tracingEnabled,
    required this.onTracingToggled,
    required this.themeColor,
    required this.onThemeColorChanged,
    required this.onStateChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdvancedToggle(open: open, onTap: onToggleOpen, isDark: isDark),
        if (open) ...[
          const SizedBox(height: 16),
          AdminMediaField(
            label: 'Pronunciation audio (optional)',
            icon: Icons.mic_rounded,
            accent: AppColors.accentPink,
            currentUrl: audioUrl,
            uploadFolder: 'lesson-audio',
            fileType: FileType.custom,
            allowedExtensions: const ['mp3', 'wav', 'ogg', 'm4a', 'aac'],
            onUploaded: onAudioUploaded,
          ),
          const SizedBox(height: 16),
          AdminTextField(
            label: 'Pronunciation guide (text)',
            controller: pronCtrl,
            onChanged: (_) => onStateChange(),
          ),
          const SizedBox(height: 16),
          quizzesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Text(
              'Failed to load quizzes: $err',
              style: const TextStyle(color: Colors.red),
            ),
            data: (quizzesList) {
              final currentValue = quizRefCtrl.text.trim();
              final inList = quizzesList.any((q) => q.id == currentValue);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Invitation (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: showCustomQuizIdInput
                        ? '__custom__'
                        : (inList ? currentValue : ''),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None / Clear Quiz'),
                      ),
                      for (final q in quizzesList)
                        DropdownMenuItem<String>(
                          value: q.id,
                          child: Text(
                            '${q.title ?? 'Untitled Quiz'} (${q.id})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const DropdownMenuItem<String>(
                        value: '__custom__',
                        child: Text('Custom ID (Manual Entry)...'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == '__custom__') {
                        onCustomQuizIdToggled(true);
                        quizRefCtrl.clear();
                      } else {
                        onCustomQuizIdToggled(false);
                        quizRefCtrl.text = val ?? '';
                      }
                      onStateChange();
                    },
                  ),
                  if (showCustomQuizIdInput) ...[
                    const SizedBox(height: 12),
                    AdminTextField(
                      label: 'Custom Quiz ID',
                      controller: quizRefCtrl,
                      hint: 'Paste Appwrite Quiz ID here',
                      onChanged: (_) => onStateChange(),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _CalloutPicker(
            value: calloutVariant,
            onChanged: onCalloutChanged,
            isDark: isDark,
          ),
          if (tracingAllowed) ...[
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Enable tracing practice',
                style: AdminTokens.bodyStrong(isDark),
              ),
              subtitle: Text(
                'Finger-trace strokes — alphabets & numbers only',
                style: AdminTokens.label(isDark),
              ),
              value: tracingEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: onTracingToggled,
            ),
          ],
          const SizedBox(height: 16),
          _ThemeColorPicker(
            value: themeColor,
            onChanged: onThemeColorChanged,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}
