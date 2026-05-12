import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';

class WordFormSheet extends ConsumerStatefulWidget {
  final WordModel? word;
  const WordFormSheet({super.key, this.word});

  static void show(BuildContext context, WidgetRef ref, WordModel? word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WordFormSheet(word: word),
    );
  }

  @override
  ConsumerState<WordFormSheet> createState() => _WordFormSheetState();
}

class _WordFormSheetState extends ConsumerState<WordFormSheet> {
  late final TextEditingController _wordOlChikiCtrl;
  late final TextEditingController _wordLatinCtrl;
  late final TextEditingController _meaningCtrl;
  late final TextEditingController _usageCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _pronCtrl;
  late final TextEditingController _orderCtrl;

  bool get _isEditing => widget.word != null;

  @override
  void initState() {
    super.initState();
    final w = widget.word;
    _wordOlChikiCtrl = TextEditingController(text: w?.wordOlChiki ?? '');
    _wordLatinCtrl = TextEditingController(text: w?.wordLatin ?? '');
    _meaningCtrl = TextEditingController(text: w?.meaning ?? '');
    _usageCtrl = TextEditingController(text: w?.usage ?? '');
    _categoryCtrl = TextEditingController(text: w?.category ?? '');
    _pronCtrl = TextEditingController(text: w?.pronunciation ?? '');
    _orderCtrl = TextEditingController(text: (w?.order ?? 0).toString());
  }

  @override
  void dispose() {
    _wordOlChikiCtrl.dispose();
    _wordLatinCtrl.dispose();
    _meaningCtrl.dispose();
    _usageCtrl.dispose();
    _categoryCtrl.dispose();
    _pronCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final word = WordModel(
      id: widget.word?.id ?? const Uuid().v4(),
      wordOlChiki: _wordOlChikiCtrl.text.trim(),
      wordLatin: _wordLatinCtrl.text.trim(),
      meaning: _meaningCtrl.text.trim(),
      usage: _usageCtrl.text.trim().isNotEmpty ? _usageCtrl.text.trim() : null,
      category: _categoryCtrl.text.trim().isNotEmpty
          ? _categoryCtrl.text.trim()
          : null,
      pronunciation: _pronCtrl.text.trim().isNotEmpty
          ? _pronCtrl.text.trim()
          : null,
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      audioUrl: widget.word?.audioUrl,
      imageUrl: widget.word?.imageUrl,
      animationUrl: widget.word?.animationUrl,
    );
    if (_isEditing) {
      ref.read(wordsProvider.notifier).updateWord(word);
    } else {
      ref.read(wordsProvider.notifier).addWord(word);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
            _isEditing ? 'Edit Word' : 'New Word',
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
            controller: _wordOlChikiCtrl,
            label: 'Word (Ol Chiki)',
            hint: 'e.g., ᱡᱚᱦᱟᱨ',
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _wordLatinCtrl,
            label: 'Word (Latin)',
            hint: 'e.g., Johar',
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _meaningCtrl,
            label: 'Meaning (English)',
            hint: 'e.g., Hello / Greetings',
          ),
          const SizedBox(height: 20),
          AdminTextField(
            controller: _usageCtrl,
            label: 'Usage Example (optional)',
            hint: 'e.g., "Johar!" — used as a greeting',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AdminTextField(
                  controller: _categoryCtrl,
                  label: 'Category',
                  hint: 'e.g., Greetings',
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
            label: 'Pronunciation (optional)',
            hint: 'e.g., jo-har',
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
                label: _isEditing ? 'Save Changes' : 'Add Word',
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
