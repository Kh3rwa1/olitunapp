import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';

class SentenceFormSheet extends ConsumerStatefulWidget {
  final SentenceModel? sentence;
  const SentenceFormSheet({super.key, this.sentence});

  static void show(
    BuildContext context,
    WidgetRef ref,
    SentenceModel? sentence,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SentenceFormSheet(sentence: sentence),
    );
  }

  @override
  ConsumerState<SentenceFormSheet> createState() => _SentenceFormSheetState();
}

class _SentenceFormSheetState extends ConsumerState<SentenceFormSheet> {
  late final TextEditingController _olChikiCtrl;
  late final TextEditingController _latinCtrl;
  late final TextEditingController _meaningCtrl;
  late final TextEditingController _usageCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _pronCtrl;
  late final TextEditingController _orderCtrl;
  late final TextEditingController _themeColorCtrl;

  String? _audioUrl;
  String? _imageUrl;
  String? _animationUrl;

  bool get _isEditing => widget.sentence != null;

  @override
  void initState() {
    super.initState();
    final s = widget.sentence;
    _olChikiCtrl = TextEditingController(text: s?.sentenceOlChiki ?? '');
    _latinCtrl = TextEditingController(text: s?.sentenceLatin ?? '');
    _meaningCtrl = TextEditingController(text: s?.meaning ?? '');
    _usageCtrl = TextEditingController(text: s?.usage ?? '');
    _categoryCtrl = TextEditingController(text: s?.category ?? '');
    _pronCtrl = TextEditingController(text: s?.pronunciation ?? '');
    _orderCtrl = TextEditingController(text: (s?.order ?? 0).toString());
    _themeColorCtrl = TextEditingController(text: s?.themeColor ?? '');
    _audioUrl = s?.audioUrl;
    _imageUrl = s?.imageUrl;
    _animationUrl = s?.animationUrl;
  }

  @override
  void dispose() {
    _olChikiCtrl.dispose();
    _latinCtrl.dispose();
    _meaningCtrl.dispose();
    _usageCtrl.dispose();
    _categoryCtrl.dispose();
    _pronCtrl.dispose();
    _orderCtrl.dispose();
    _themeColorCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final sentence = SentenceModel(
      id: widget.sentence?.id ?? const Uuid().v4(),
      sentenceOlChiki: _olChikiCtrl.text.trim(),
      sentenceLatin: _latinCtrl.text.trim(),
      meaning: _meaningCtrl.text.trim(),
      usage: _usageCtrl.text.trim().isNotEmpty ? _usageCtrl.text.trim() : null,
      category: _categoryCtrl.text.trim().isNotEmpty
          ? _categoryCtrl.text.trim()
          : null,
      pronunciation: _pronCtrl.text.trim().isNotEmpty
          ? _pronCtrl.text.trim()
          : null,
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      audioUrl: _audioUrl,
      imageUrl: _imageUrl,
      animationUrl: _animationUrl,
      themeColor: _themeColorCtrl.text.trim().isNotEmpty
          ? _themeColorCtrl.text.trim()
          : null,
    );
    if (_isEditing) {
      ref.read(sentencesProvider.notifier).update(sentence);
    } else {
      ref.read(sentencesProvider.notifier).add(sentence);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                colors: [Color(0xFF10B981), Color(0xFF047857)],
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
            _isEditing ? 'Edit Sentence' : 'New Sentence',
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
          AdminTextField(
            controller: _olChikiCtrl,
            label: 'Sentence (Ol Chiki)',
            hint: 'e.g., ᱡᱚᱦᱟᱨ, ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ?',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _latinCtrl,
            label: 'Sentence (Latin)',
            hint: 'e.g., Johar, am do ced nyutum kana?',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _meaningCtrl,
            label: 'Meaning (English)',
            hint: 'e.g., Hello, how are you?',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _usageCtrl,
            label: 'Usage / Context (optional)',
            hint: 'When to use this sentence',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AdminTextField(
                  controller: _categoryCtrl,
                  label: 'Category',
                  hint: 'e.g., Greeting',
                  prefixIcon: Icons.label_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminTextField(
                  controller: _orderCtrl,
                  label: 'Order',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.sort_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _pronCtrl,
            label: 'Pronunciation Guide (optional)',
            hint: 'e.g., Jo-har, am do ched nyu-tum ka-na?',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _buildThemeColorSelector(isDark),
          const SizedBox(height: 24),
          AdminMediaField(
            label: 'Audio Pronunciation',
            icon: Icons.audiotrack_rounded,
            accent: const Color(0xFF10B981),
            currentUrl: _audioUrl,
            uploadFolder: 'sentences-audio',
            fileType: FileType.audio,
            onUploaded: (url) => setState(() => _audioUrl = url),
          ),
          const SizedBox(height: 24),
          AdminMediaField(
            label: 'Hero Image/GIF (Optional)',
            subtitle: 'Upload high-quality image or animated GIF',
            icon: Icons.image_rounded,
            accent: const Color(0xFF6366F1),
            currentUrl: _imageUrl,
            uploadFolder: 'sentences-images',
            fileType: FileType.image,
            onUploaded: (url) => setState(() => _imageUrl = url),
            previewBuilder: (url) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_rounded,
                  size: 60,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AdminMediaField(
            label: 'Lottie Animation (Optional)',
            subtitle: 'Upload a .json Lottie animation file',
            icon: Icons.animation_rounded,
            accent: const Color(0xFF10B981),
            currentUrl: _animationUrl,
            uploadFolder: 'animations',
            fileType: FileType.custom,
            allowedExtensions: const ['json'],
            onUploaded: (url) => setState(() => _animationUrl = url),
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
                label: _isEditing ? 'Save Changes' : 'Add Sentence',
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
