import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';

class NumberFormSheet extends ConsumerStatefulWidget {
  final NumberModel? number;
  const NumberFormSheet({super.key, this.number});

  static void show(BuildContext context, WidgetRef ref, NumberModel? number) {
    showAdminBottomSheet(
      context: context,
      builder: (_) => NumberFormSheet(number: number),
    );
  }

  @override
  ConsumerState<NumberFormSheet> createState() => _NumberFormSheetState();
}

class _NumberFormSheetState extends ConsumerState<NumberFormSheet> {
  late final TextEditingController _numeralCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _nameOlChikiCtrl;
  late final TextEditingController _nameLatinCtrl;
  late final TextEditingController _pronCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _themeColorCtrl;

  String? _audioUrl;
  String? _mediaUrl;

  bool get _isEditing => widget.number != null;

  bool _isAnimationOrVideoOrHtml(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.json') ||
        lower.contains('.lottie') ||
        lower.contains('.mp4') ||
        lower.contains('.webm') ||
        lower.contains('.mov') ||
        lower.contains('.m4v') ||
        lower.contains('.3gp') ||
        lower.contains('.avi') ||
        lower.contains('.html') ||
        lower.contains('/buckets/animations/') ||
        lower.contains('/buckets/videos/') ||
        lower.contains('/buckets/html/');
  }

  @override
  void initState() {
    super.initState();
    final n = widget.number;
    _numeralCtrl = TextEditingController(text: n?.numeral ?? '');
    _valueCtrl = TextEditingController(text: (n?.value ?? 0).toString());
    _nameOlChikiCtrl = TextEditingController(text: n?.nameOlChiki ?? '');
    _nameLatinCtrl = TextEditingController(text: n?.nameLatin ?? '');
    _pronCtrl = TextEditingController(text: n?.pronunciation ?? '');
    _orderCtrl = TextEditingController(text: (n?.order ?? 0).toString());
    _themeColorCtrl = TextEditingController(text: n?.themeColor ?? '');
    _audioUrl = n?.audioUrl;
    _mediaUrl = n?.animationUrl ?? n?.imageUrl;
  }

  @override
  void dispose() {
    _numeralCtrl.dispose();
    _valueCtrl.dispose();
    _nameOlChikiCtrl.dispose();
    _nameLatinCtrl.dispose();
    _pronCtrl.dispose();
    _orderCtrl.dispose();
    _themeColorCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final media = _mediaUrl?.trim();
    final isAnim = media != null && _isAnimationOrVideoOrHtml(media);

    final number = NumberModel(
      id: widget.number?.id ?? const Uuid().v4(),
      numeral: _numeralCtrl.text.trim(),
      value: int.tryParse(_valueCtrl.text.trim()) ?? 0,
      nameOlChiki: _nameOlChikiCtrl.text.trim(),
      nameLatin: _nameLatinCtrl.text.trim(),
      pronunciation: _pronCtrl.text.trim().isNotEmpty
          ? _pronCtrl.text.trim()
          : null,
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      audioUrl: _audioUrl,
      imageUrl: isAnim ? null : media,
      animationUrl: isAnim ? media : null,
      themeColor: _themeColorCtrl.text.trim().isNotEmpty
          ? _themeColorCtrl.text.trim()
          : null,
    );
    if (_isEditing) {
      ref.read(numbersProvider.notifier).updateNumber(number);
    } else {
      ref.read(numbersProvider.notifier).addNumber(number);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildTitle(isDark),
          Divider(height: 1, color: AdminTokens.divider(isDark)),
          Expanded(child: _buildFields(isDark)),
          _buildActions(isDark),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditing ? Icons.edit_rounded : Icons.add_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isEditing ? 'Edit Number' : 'New Number',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminTextField(
                  controller: _numeralCtrl,
                  label: 'Ol Chiki Numeral',
                  hint: 'e.g., ᱑',
                  prefixIcon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminTextField(
                  controller: _valueCtrl,
                  label: 'Numeric Value',
                  hint: 'e.g., 1',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.numbers_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _nameOlChikiCtrl,
            label: 'Name (Ol Chiki)',
            hint: 'e.g., ᱢᱤᱫ',
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _nameLatinCtrl,
            label: 'Name (Latin)',
            hint: 'e.g., Mit (one)',
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _pronCtrl,
            label: 'Pronunciation (optional)',
            hint: 'e.g., mit',
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _orderCtrl,
            label: 'Display Order',
            hint: '0',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.sort_rounded,
          ),
          const SizedBox(height: 24),
          _buildThemeColorSelector(isDark),
          const SizedBox(height: 24),
          AdminMediaField(
            label: 'Audio Pronunciation',
            icon: Icons.audiotrack_rounded,
            accent: const Color(0xFF3B82F6),
            currentUrl: _audioUrl,
            uploadFolder: 'numbers-audio',
            fileType: FileType.audio,
            onUploaded: (url) => setState(() => _audioUrl = url),
          ),
          const SizedBox(height: 24),
          AdminMediaField(
            label: 'Hero Media (Optional)',
            subtitle:
                'Upload high-quality image, GIF, SVG, Lottie (JSON), audio, video, or HTML file',
            icon: Icons.play_circle_outline_rounded,
            accent: const Color(0xFF6366F1),
            currentUrl: _mediaUrl,
            uploadFolder: 'numbers-media',
            fileType: FileType.any,
            onUploaded: (url) => setState(() => _mediaUrl = url),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AdminTokens.baseTint(isDark),
        border: Border(top: BorderSide(color: AdminTokens.divider(isDark))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AdminSecondaryButton(
                label: 'Cancel',
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AdminPrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Add Number',
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeColorSelector(bool isDark) {
    // Avoid purple/violet per Purple Ban.
    final presets = [
      {'name': 'Mint', 'hex': '#10B981'},
      {'name': 'Teal', 'hex': '#14B8A6'},
      {'name': 'Sky', 'hex': '#0EA5E9'},
      {'name': 'Rose', 'hex': '#F43F5E'},
      {'name': 'Amber', 'hex': '#F59E0B'},
      {'name': 'Charcoal', 'hex': '#1E293B'},
      {'name': 'White', 'hex': '#FFFFFF'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Color (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final p in presets)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _themeColorCtrl.text = p['hex']!);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(p['hex']!.replaceFirst('#', '0xFF')),
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _themeColorCtrl.text.toUpperCase() == p['hex']
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white24 : Colors.black12),
                        width: _themeColorCtrl.text.toUpperCase() == p['hex']
                            ? 2
                            : 1,
                      ),
                      boxShadow: [
                        if (_themeColorCtrl.text.toUpperCase() == p['hex'])
                          BoxShadow(
                            color: Color(
                              int.parse(p['hex']!.replaceFirst('#', '0xFF')),
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _themeColorCtrl.clear());
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _themeColorCtrl.text.isEmpty
                          ? (isDark ? Colors.white : Colors.black)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.format_color_reset_rounded,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdminTextField(
          controller: _themeColorCtrl,
          label: 'Custom HEX Code',
          hint: 'e.g., #FF5722',
          prefixIcon: Icons.color_lens_rounded,
        ),
      ],
    );
  }
}
