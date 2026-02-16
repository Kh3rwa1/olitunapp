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

class AdminWordsScreen extends ConsumerWidget {
  const AdminWordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsProvider);
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
                  child: wordsAsync.when(
                    data: (words) => words.isEmpty
                        ? _buildEmptyState(context, ref, isDark)
                        : _buildWordsGrid(
                            context,
                            ref,
                            words,
                            isDark,
                            isWideScreen,
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: SelectableText(
                        'Error loading words: $error',
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
        onPressed: () => _showWordDialog(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Word',
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
          'WORDS & PHRASES',
          style: TextStyle(
            fontSize: isWideScreen ? 40 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
        ),
        Text(
          'Manage Ol Chiki vocabulary, meanings, and usage',
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
            Icons.menu_book_rounded,
            size: 80,
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            'No words yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showWordDialog(context, ref, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('CREATE FIRST WORD'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsGrid(
    BuildContext context,
    WidgetRef ref,
    List<WordModel> words,
    bool isDark,
    bool isWideScreen,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 4 : 1,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: isWideScreen ? 1.4 : 3.5,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return _buildWordCard(context, ref, word, isDark, isWideScreen);
      },
    );
  }

  Widget _buildWordCard(
    BuildContext context,
    WidgetRef ref,
    WordModel word,
    bool isDark,
    bool isWideScreen,
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
              onTap: () => _showWordDialog(context, ref, word),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            word.wordOlChiki,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            word.wordLatin,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            word.meaning,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (word.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              word.category!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (word.audioUrl != null)
                              const Icon(
                                Icons.volume_up_rounded,
                                size: 18,
                                color: AppColors.duoGreen,
                              ),
                            const SizedBox(width: 8),
                            if (word.imageUrl != null)
                              const Icon(
                                Icons.image_rounded,
                                size: 18,
                                color: AppColors.duoBlue,
                              ),
                          ],
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
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  void _showWordDialog(BuildContext context, WidgetRef ref, WordModel? word) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WordEditDialog(word: word),
    );
  }
}

class _WordEditDialog extends ConsumerStatefulWidget {
  final WordModel? word;

  const _WordEditDialog({this.word});

  @override
  ConsumerState<_WordEditDialog> createState() => _WordEditDialogState();
}

class _WordEditDialogState extends ConsumerState<_WordEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _wordOlChikiController;
  late TextEditingController _wordLatinController;
  late TextEditingController _meaningController;
  late TextEditingController _usageController;
  late TextEditingController _categoryController;
  late TextEditingController _orderController;
  late TextEditingController _pronunciationController;

  String? _imageUrl;
  String? _audioUrl;
  bool _isUploadingImage = false;
  bool _isUploadingAudio = false;

  @override
  void initState() {
    super.initState();
    _wordOlChikiController = TextEditingController(
      text: widget.word?.wordOlChiki,
    );
    _wordLatinController = TextEditingController(text: widget.word?.wordLatin);
    _meaningController = TextEditingController(text: widget.word?.meaning);
    _usageController = TextEditingController(text: widget.word?.usage);
    _categoryController = TextEditingController(text: widget.word?.category);
    _orderController = TextEditingController(
      text: (widget.word?.order ?? 0).toString(),
    );
    _pronunciationController = TextEditingController(
      text: widget.word?.pronunciation,
    );
    _imageUrl = widget.word?.imageUrl;
    _audioUrl = widget.word?.audioUrl;
  }

  @override
  void dispose() {
    _wordOlChikiController.dispose();
    _wordLatinController.dispose();
    _meaningController.dispose();
    _usageController.dispose();
    _categoryController.dispose();
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
            .uploadMedia(result.files.first, 'words-images');
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
        widget.word == null ? 'Add Word' : 'Edit Word',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 600,
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
                        controller: _wordOlChikiController,
                        label: 'Word (Ol Chiki)',
                        hint: 'e.g. ᱡᱚᱦᱟᱨ',
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _wordLatinController,
                        label: 'Word (Latin)',
                        hint: 'e.g. Johar',
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _meaningController,
                  label: 'Meaning (English)',
                  hint: 'e.g. Hello / Greetings',
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usageController,
                  label: 'Usage / Hint',
                  hint: 'When to use this word',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _categoryController,
                        label: 'Category',
                        hint: 'e.g. greetings, family',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _orderController,
                        label: 'Order',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Media Uploads
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaButton(
                        label: 'Hero Illustration',
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
        if (widget.word != null)
          TextButton(
            onPressed: () {
              ref.read(wordsProvider.notifier).delete(widget.word!.id);
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
            'SAVE WORD',
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
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
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
      final newWord = WordModel(
        id: widget.word?.id ?? const Uuid().v4(),
        wordOlChiki: _wordOlChikiController.text,
        wordLatin: _wordLatinController.text,
        meaning: _meaningController.text,
        usage: _usageController.text,
        category: _categoryController.text,
        order: int.tryParse(_orderController.text) ?? 0,
        pronunciation: _pronunciationController.text,
        imageUrl: _imageUrl,
        audioUrl: _audioUrl,
      );

      if (widget.word == null) {
        ref.read(wordsProvider.notifier).add(newWord);
      } else {
        ref.read(wordsProvider.notifier).update(newWord);
      }
      Navigator.pop(context);
    }
  }
}
