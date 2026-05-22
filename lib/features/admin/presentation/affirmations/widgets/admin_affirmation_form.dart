import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';

class AdminAffirmationForm extends ConsumerStatefulWidget {
  final AffirmationModel? affirmation;

  const AdminAffirmationForm({super.key, this.affirmation});

  static void show(
    BuildContext context,
    WidgetRef ref,
    AffirmationModel? affirmation,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminAffirmationForm(affirmation: affirmation),
    );
  }

  @override
  ConsumerState<AdminAffirmationForm> createState() =>
      _AdminAffirmationFormState();
}

class _AdminAffirmationFormState extends ConsumerState<AdminAffirmationForm> {
  late final TextEditingController _olChikiCtrl;
  late final TextEditingController _phoneticCtrl;
  late final TextEditingController _meaningCtrl;
  late final TextEditingController _orderCtrl;
  String? _audioUrl;
  late String _selectedCategory;
  late bool _isPremium;
  late DateTime _publishedAt;

  bool get _isEditing => widget.affirmation != null;

  @override
  void initState() {
    super.initState();
    _olChikiCtrl = TextEditingController(
      text: widget.affirmation?.olChikiText ?? '',
    );
    _phoneticCtrl = TextEditingController(
      text: widget.affirmation?.santaliPhonetic ?? '',
    );
    _meaningCtrl = TextEditingController(
      text: widget.affirmation?.englishMeaning ?? '',
    );
    _orderCtrl = TextEditingController(
      text: widget.affirmation?.order.toString() ?? '0',
    );
    _audioUrl = widget.affirmation?.audioUrl;
    _selectedCategory = widget.affirmation?.category ?? 'identity';
    _isPremium = widget.affirmation?.isPremium ?? false;
    _publishedAt = widget.affirmation != null
        ? DateTime.tryParse(widget.affirmation!.publishedAt) ?? DateTime.now()
        : DateTime.now();
  }

  @override
  void dispose() {
    _olChikiCtrl.dispose();
    _phoneticCtrl.dispose();
    _meaningCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_olChikiCtrl.text.isEmpty ||
        _phoneticCtrl.text.isEmpty ||
        _meaningCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    final item = AffirmationModel(
      id: widget.affirmation?.id ?? const Uuid().v4(),
      olChikiText: _olChikiCtrl.text.trim(),
      santaliPhonetic: _phoneticCtrl.text.trim(),
      englishMeaning: _meaningCtrl.text.trim(),
      audioUrl: _audioUrl != null && _audioUrl!.isNotEmpty ? _audioUrl : null,
      category: _selectedCategory,
      isPremium: _isPremium,
      order: int.tryParse(_orderCtrl.text) ?? 0,
      publishedAt: _publishedAt.toIso8601String(),
    );

    final notifier = ref.read(affirmationsProvider.notifier);
    if (_isEditing) {
      notifier.update(item);
    } else {
      notifier.add(item);
    }
    Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishedAt,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _publishedAt = date);
    }
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.peachGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _isEditing ? 'Edit Affirmation' : 'New Affirmation',
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
          ),

          Divider(height: 1, color: AdminTokens.divider(isDark)),

          // Form Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ol Chiki text input with Ol Chiki preview
                  AdminTextField(
                    controller: _olChikiCtrl,
                    label: 'Ol Chiki Text (Required)',
                    hint: 'e.g., ᱫᱟᱨᱮ ᱜᱮ ᱡᱤᱣᱤ ᱠᱟᱱᱟ',
                    maxLines: 2,
                    onChanged: (val) => setState(() {}),
                  ),
                  if (_olChikiCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Preview: ${_olChikiCtrl.text}',
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 22,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  AdminTextField(
                    controller: _phoneticCtrl,
                    label: 'Santali Phonetic (Required)',
                    hint: 'e.g., Dare ge jiwi kana',
                  ),
                  const SizedBox(height: 20),

                  AdminTextField(
                    controller: _meaningCtrl,
                    label: 'English Meaning (Required)',
                    hint: 'e.g., Trees are life itself',
                  ),
                  const SizedBox(height: 20),

                  // Category Selector dropdown
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: AdminTokens.overlay(isDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AdminTokens.sunken(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusMd,
                        ),
                        borderSide: BorderSide(
                          color: AdminTokens.border(isDark),
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'identity',
                        child: Text('Identity & Self-Worth'),
                      ),
                      DropdownMenuItem(
                        value: 'habit',
                        child: Text('Habit & Consistency'),
                      ),
                      DropdownMenuItem(
                        value: 'wealth',
                        child: Text('Wealth & Growth Mindset'),
                      ),
                      DropdownMenuItem(
                        value: 'culture',
                        child: Text('Culture & Heritage'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Audio Upload
                  AdminMediaField(
                    label: 'Audio File (Optional)',
                    icon: Icons.audiotrack_rounded,
                    accent: AppColors.primary,
                    currentUrl: _audioUrl,
                    uploadFolder: 'affirmations-audio',
                    fileType: FileType.audio,
                    onUploaded: (url) => setState(() => _audioUrl = url),
                  ),
                  const SizedBox(height: 20),

                  // Order & Premium
                  Row(
                    children: [
                      Expanded(
                        child: AdminTextField(
                          controller: _orderCtrl,
                          label: 'Display Order',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium Content',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Switch(
                            value: _isPremium,
                            activeColor: AppColors.primary,
                            onChanged: (val) =>
                                setState(() => _isPremium = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date Picker for publishedAt
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publication Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_publishedAt.year}-${_publishedAt.month.toString().padLeft(2, '0')}-${_publishedAt.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                        ),
                        label: const Text('Change Date'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AdminTokens.baseTint(isDark),
              border: Border(
                top: BorderSide(color: AdminTokens.divider(isDark)),
              ),
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
                      label: _isEditing ? 'Save Changes' : 'Create Affirmation',
                      icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
