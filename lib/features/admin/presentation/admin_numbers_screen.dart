import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../core/storage/supabase_service.dart';
import 'package:file_picker/file_picker.dart';

class AdminNumbersScreen extends ConsumerWidget {
  const AdminNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbersAsync = ref.watch(numbersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                  child: _buildHeader(context, isDark, isWideScreen),
                ),
                Expanded(
                  child: numbersAsync.when(
                    data: (numbers) => numbers.isEmpty
                        ? _buildEmptyState(context, ref, isDark)
                        : _buildNumbersGrid(
                            context,
                            ref,
                            numbers,
                            isDark,
                            isWideScreen,
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: SelectableText(
                        'Error loading numbers: $error',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNumberDialog(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Number',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0A0E14), const Color(0xFF0D1117)]
              : [const Color(0xFFF8FAFC), Colors.white],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isWideScreen)
          GestureDetector(
            onTap: () => context.go('/admin'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
        if (!isWideScreen) const SizedBox(height: 20),
        Text(
          'NUMBERS',
          style: TextStyle(
            fontSize: isWideScreen ? 40 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
        ),
        Text(
          'Manage Ol Chiki numerals and their data',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_list_numbered_rounded,
            size: 80,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            'No numbers yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showNumberDialog(context, ref, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('CREATE FIRST NUMBER'),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersGrid(
    BuildContext context,
    WidgetRef ref,
    List<NumberModel> numbers,
    bool isDark,
    bool isWideScreen,
  ) {
    final sortedNumbers = [...numbers]
      ..sort((a, b) => a.order.compareTo(b.order));

    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 5 : 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.85,
      ),
      itemCount: sortedNumbers.length,
      itemBuilder: (context, index) {
        final number = sortedNumbers[index];
        return _buildNumberCard(context, ref, number, isDark);
      },
    );
  }

  Widget _buildNumberCard(
    BuildContext context,
    WidgetRef ref,
    NumberModel number,
    bool isDark,
  ) {
    return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showNumberDialog(context, ref, number),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          number.numeral,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      number.nameLatin,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Value: ${number.value}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (number.audioUrl != null)
                          const Icon(
                            Icons.volume_up_rounded,
                            size: 16,
                            color: AppColors.duoGreen,
                          ),
                        const SizedBox(width: 8),
                        if (number.imageUrl != null)
                          const Icon(
                            Icons.image_rounded,
                            size: 16,
                            color: AppColors.duoBlue,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 50.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  void _showNumberDialog(
    BuildContext context,
    WidgetRef ref,
    NumberModel? number,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NumberEditDialog(number: number),
    );
  }
}

class _NumberEditDialog extends ConsumerStatefulWidget {
  final NumberModel? number;

  const _NumberEditDialog({this.number});

  @override
  ConsumerState<_NumberEditDialog> createState() => _NumberEditDialogState();
}

class _NumberEditDialogState extends ConsumerState<_NumberEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeralController;
  late TextEditingController _valueController;
  late TextEditingController _nameOlChikiController;
  late TextEditingController _nameLatinController;
  late TextEditingController _orderController;
  late TextEditingController _pronunciationController;

  String? _imageUrl;
  String? _audioUrl;
  bool _isUploadingImage = false;
  bool _isUploadingAudio = false;

  @override
  void initState() {
    super.initState();
    _numeralController = TextEditingController(text: widget.number?.numeral);
    _valueController = TextEditingController(
      text: widget.number?.value.toString(),
    );
    _nameOlChikiController = TextEditingController(
      text: widget.number?.nameOlChiki,
    );
    _nameLatinController = TextEditingController(
      text: widget.number?.nameLatin,
    );
    _orderController = TextEditingController(
      text: (widget.number?.order ?? 0).toString(),
    );
    _pronunciationController = TextEditingController(
      text: widget.number?.pronunciation,
    );
    _imageUrl = widget.number?.imageUrl;
    _audioUrl = widget.number?.audioUrl;
  }

  @override
  void dispose() {
    _numeralController.dispose();
    _valueController.dispose();
    _nameOlChikiController.dispose();
    _nameLatinController.dispose();
    _orderController.dispose();
    _pronunciationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final url = await ref
            .read(supabaseServiceProvider)
            .uploadMedia(result.files.first, 'numbers-images');
        setState(() => _imageUrl = url);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _pickAudio() async {
    setState(() => _isUploadingAudio = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final url = await ref
            .read(supabaseServiceProvider)
            .uploadMedia(result.files.first, 'lesson-audio');
        setState(() => _audioUrl = url);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploadingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        widget.number == null ? 'Add Number' : 'Edit Number',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _numeralController,
                        label: 'Numeral (Ol Chiki)',
                        hint: 'e.g. ᱑',
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _valueController,
                        label: 'Value',
                        hint: 'e.g. 1',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameOlChikiController,
                  label: 'Name (Ol Chiki)',
                  hint: 'e.g. ᱢᱤᱫ',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameLatinController,
                  label: 'Name (Latin)',
                  hint: 'e.g. Mit (One)',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _pronunciationController,
                  label: 'Pronunciation Hint',
                  hint: 'e.g. Like "meet"',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _orderController,
                  label: 'Display Order',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Media Uploads
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaButton(
                        label: 'Hero Image',
                        icon: Icons.image_rounded,
                        url: _imageUrl,
                        isUploading: _isUploadingImage,
                        onTap: _pickImage,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMediaButton(
                        label: 'Pronunciation Audio',
                        icon: Icons.volume_up_rounded,
                        url: _audioUrl,
                        isUploading: _isUploadingAudio,
                        onTap: _pickAudio,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: Colors.grey[600])),
        ),
        if (widget.number != null)
          TextButton(
            onPressed: () {
              ref.read(numbersProvider.notifier).delete(widget.number!.id);
              Navigator.pop(context);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'SAVE NUMBER',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  Widget _buildMediaButton({
    required String label,
    required IconData icon,
    required String? url,
    required bool isUploading,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: url != null ? AppColors.duoGreen : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          color: url != null
              ? AppColors.duoGreen.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            if (isUploading)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                url != null ? Icons.check_circle_rounded : icon,
                color: url != null ? AppColors.duoGreen : Colors.grey[600],
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: url != null ? AppColors.duoGreen : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final newNumber = NumberModel(
        id: widget.number?.id ?? const Uuid().v4(),
        numeral: _numeralController.text,
        value: int.tryParse(_valueController.text) ?? 0,
        nameOlChiki: _nameOlChikiController.text,
        nameLatin: _nameLatinController.text,
        order: int.tryParse(_orderController.text) ?? 0,
        pronunciation: _pronunciationController.text,
        imageUrl: _imageUrl,
        audioUrl: _audioUrl,
      );

      if (widget.number == null) {
        ref.read(numbersProvider.notifier).add(newNumber);
      } else {
        ref.read(numbersProvider.notifier).update(newNumber);
      }
      Navigator.pop(context);
    }
  }
}
