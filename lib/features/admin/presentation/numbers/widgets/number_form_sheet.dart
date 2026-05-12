import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';

class NumberFormSheet extends ConsumerStatefulWidget {
  final NumberModel? number;
  const NumberFormSheet({super.key, this.number});

  static void show(BuildContext context, WidgetRef ref, NumberModel? number) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  bool get _isEditing => widget.number != null;

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
  }

  @override
  void dispose() {
    _numeralCtrl.dispose();
    _valueCtrl.dispose();
    _nameOlChikiCtrl.dispose();
    _nameLatinCtrl.dispose();
    _pronCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final number = NumberModel(
      id: widget.number?.id ?? const Uuid().v4(),
      numeral: _numeralCtrl.text.trim(),
      value: int.tryParse(_valueCtrl.text.trim()) ?? 0,
      nameOlChiki: _nameOlChikiCtrl.text.trim(),
      nameLatin: _nameLatinCtrl.text.trim(),
      pronunciation: _pronCtrl.text.trim().isNotEmpty ? _pronCtrl.text.trim() : null,
      order: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      audioUrl: widget.number?.audioUrl,
      imageUrl: widget.number?.imageUrl,
      animationUrl: widget.number?.animationUrl,
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
}
