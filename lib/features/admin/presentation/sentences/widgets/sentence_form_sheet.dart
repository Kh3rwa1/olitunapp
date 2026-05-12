import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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
      pronunciation:
          _pronCtrl.text.trim().isNotEmpty ? _pronCtrl.text.trim() : null,
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      audioUrl: widget.sentence?.audioUrl,
      imageUrl: widget.sentence?.imageUrl,
      animationUrl: widget.sentence?.animationUrl,
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
}
