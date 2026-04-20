import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../core/storage/upload_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/ai_service.dart';

class AdminLettersScreen extends ConsumerWidget {
  const AdminLettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lettersAsync = ref.watch(lettersProvider);
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
                  child: lettersAsync.when(
                    data: (letters) => letters.isEmpty
                        ? _buildEmptyState(context, ref, isDark)
                        : _buildLettersGrid(
                            context,
                            ref,
                            letters,
                            isDark,
                            isWideScreen,
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: SelectableText(
                        'Error loading letters: $error',
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
        onPressed: () => _showLetterDialog(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Letter',
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
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        if (!isWideScreen) const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.premiumMint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ol Chiki Letters',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage alphabet characters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColors.premiumMint,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentMint.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ᱚ',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No letters yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add Ol Chiki alphabet letters',
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => _showLetterDialog(context, ref, null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.premiumMint,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentMint.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Add Letter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildLettersGrid(
    BuildContext context,
    WidgetRef ref,
    List<LetterModel> letters,
    bool isDark,
    bool isWideScreen,
  ) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 32 : 20,
        0,
        isWideScreen ? 32 : 20,
        100,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 6 : 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        return _LetterCard(
          letter: letter,
          isDark: isDark,
          index: index,
          onEdit: () => _showLetterDialog(context, ref, letter),
          onDelete: () => _showDeleteDialog(context, ref, letter),
        );
      },
    );
  }

  void _showLetterDialog(
    BuildContext context,
    WidgetRef ref,
    LetterModel? letter,
  ) {
    final isEditing = letter != null;
    final charController = TextEditingController(
      text: letter?.charOlChiki ?? '',
    );
    final romanController = TextEditingController(
      text: letter?.transliterationLatin ?? '',
    );
    final pronunciationController = TextEditingController(
      text: letter?.pronunciation ?? '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // State variables - declared OUTSIDE StatefulBuilder.builder() to preserve across rebuilds
    String? audioUrl = letter?.audioUrl;
    String? imageUrl = letter?.imageUrl;
    String? animationUrl = letter?.animationUrl;
    bool isUploading = false;
    bool isUploadingImage = false;
    bool isUploadingAnimation = false;
    bool isTranslatingRoman = false;
    bool isTranslatingPronunciation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> pickAudio() async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.audio,
                    withData:
                        true, // CRITICAL for web: ensures bytes are loaded
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setDialogState(() => isUploading = true);

                    final file = result.files.first;
                    debugPrint(
                      'Picked file: ${file.name}, size: ${file.size}, bytes: ${file.bytes != null}',
                    );

                    final uploadedUrl = await ref
                        .read(uploadServiceProvider)
                        .uploadMedia(file, 'letters-audio');

                    debugPrint('Upload result: $uploadedUrl');

                    setDialogState(() {
                      audioUrl = uploadedUrl;
                      isUploading = false;
                    });

                    if (uploadedUrl == null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Upload failed. Check console for details.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint('Error picking audio: $e');
                  setDialogState(() => isUploading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.premiumMint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit_rounded : Icons.add_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          isEditing ? 'Edit Letter' : 'New Letter',
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
                  Divider(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: charController,
                            label: 'Ol Chiki Character',
                            hint: 'e.g., ᱚ',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: romanController,
                                  label: 'Romanization',
                                  hint: 'e.g., a',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatefulBuilder(
                                builder: (context, setBtnState) {
                                  return IconButton.filledTonal(
                                    onPressed: isTranslatingRoman
                                        ? null
                                        : () async {
                                            if (charController.text
                                                .trim()
                                                .isEmpty) {
                                              return;
                                            }
                                            setBtnState(
                                              () => isTranslatingRoman = true,
                                            );
                                            try {
                                              final result = await ref
                                                  .read(aiServiceProvider)
                                                  .translateFromOlChiki(
                                                    charController.text.trim(),
                                                    to: 'en',
                                                  );
                                              if (result != null) {
                                                romanController.text = result
                                                    .translation
                                                    .toLowerCase();
                                              }
                                            } finally {
                                              setBtnState(
                                                () =>
                                                    isTranslatingRoman = false,
                                              );
                                            }
                                          },
                                    icon: isTranslatingRoman
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 20,
                                          ),
                                    tooltip: 'Magic Fill (Romanization)',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: pronunciationController,
                                  label: 'Pronunciation (optional)',
                                  hint: 'e.g., like "a" in "about"',
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatefulBuilder(
                                builder: (context, setBtnState) {
                                  return IconButton.filledTonal(
                                    onPressed: isTranslatingPronunciation
                                        ? null
                                        : () async {
                                            if (charController.text
                                                .trim()
                                                .isEmpty) {
                                              return;
                                            }
                                            setBtnState(
                                              () => isTranslatingPronunciation =
                                                  true,
                                            );
                                            try {
                                              final result = await ref
                                                  .read(aiServiceProvider)
                                                  .translateFromOlChiki(
                                                    charController.text.trim(),
                                                    to: 'en',
                                                  );
                                              if (result != null) {
                                                pronunciationController.text =
                                                    'like "${result.translation}" in ...';
                                              }
                                            } finally {
                                              setBtnState(
                                                () =>
                                                    isTranslatingPronunciation =
                                                        false,
                                              );
                                            }
                                          },
                                    icon: isTranslatingPronunciation
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 20,
                                          ),
                                    tooltip: 'Magic Fill (Pronunciation)',
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Audio Pronunciation',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: isUploading ? null : pickAudio,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isUploading
                                        ? Icons.hourglass_top_rounded
                                        : Icons.audiotrack_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isUploading
                                          ? 'Uploading...'
                                          : (audioUrl != null
                                                ? 'Audio Linked'
                                                : 'Upload Audio File'),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (audioUrl != null && !isUploading)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Image/GIF upload section
                          Text(
                            'Hero Image/GIF (Optional)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload high-quality image or animated GIF',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: isUploadingImage
                                ? null
                                : () async {
                                    try {
                                      final result = await FilePicker.platform
                                          .pickFiles(
                                            type: FileType.image,
                                            withData: true,
                                          );
                                      if (result != null &&
                                          result.files.isNotEmpty) {
                                        setDialogState(
                                          () => isUploadingImage = true,
                                        );
                                        final file = result.files.first;

                                        final uploadedUrl = await ref
                                            .read(uploadServiceProvider)
                                            .uploadMedia(
                                              file,
                                              'letters-images',
                                            );

                                        setDialogState(() {
                                          imageUrl = uploadedUrl;
                                          isUploadingImage = false;
                                        });

                                        if (uploadedUrl == null &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Image upload failed.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      setDialogState(
                                        () => isUploadingImage = false,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  if (imageUrl != null &&
                                      !isUploadingImage) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl!,
                                        height: 120,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.broken_image_rounded,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Row(
                                    children: [
                                      Icon(
                                        isUploadingImage
                                            ? Icons.hourglass_top_rounded
                                            : Icons.image_rounded,
                                        color: const Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          isUploadingImage
                                              ? 'Uploading...'
                                              : (imageUrl != null
                                                    ? 'Tap to change image'
                                                    : 'Upload Image or GIF'),
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (imageUrl != null && !isUploadingImage)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF6366F1),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Lottie Animation upload section
                          Text(
                            'Lottie Animation (Optional)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload a .json Lottie animation file',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: isUploadingAnimation
                                ? null
                                : () async {
                                    try {
                                      final result = await FilePicker.platform
                                          .pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: ['json'],
                                            withData: true,
                                          );
                                      if (result != null &&
                                          result.files.isNotEmpty) {
                                        setDialogState(
                                          () => isUploadingAnimation = true,
                                        );
                                        final file = result.files.first;

                                        final uploadedUrl = await ref
                                            .read(uploadServiceProvider)
                                            .uploadMedia(file, 'animations');

                                        setDialogState(() {
                                          animationUrl = uploadedUrl;
                                          isUploadingAnimation = false;
                                        });

                                        if (uploadedUrl == null &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Animation upload failed.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      setDialogState(
                                        () => isUploadingAnimation = false,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isUploadingAnimation
                                        ? Icons.hourglass_top_rounded
                                        : Icons.animation_rounded,
                                    color: const Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isUploadingAnimation
                                          ? 'Uploading...'
                                          : (animationUrl != null
                                                ? 'Animation Linked'
                                                : 'Upload Lottie Animation'),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (animationUrl != null &&
                                      !isUploadingAnimation)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D1117)
                          : const Color(0xFFF8FAFC),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final newLetter = LetterModel(
                                id: letter?.id ?? const Uuid().v4(),
                                charOlChiki: charController.text,
                                transliterationLatin: romanController.text,
                                pronunciation:
                                    pronunciationController.text.isNotEmpty
                                    ? pronunciationController.text
                                    : null,
                                order: letter?.order ?? 0,
                                isActive: true,
                                audioUrl: audioUrl,
                                imageUrl: imageUrl,
                                animationUrl: animationUrl,
                              );
                              if (isEditing) {
                                ref
                                    .read(lettersProvider.notifier)
                                    .updateLetter(newLetter);
                              } else {
                                ref
                                    .read(lettersProvider.notifier)
                                    .addLetter(newLetter);
                              }
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: AppColors.premiumMint,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentMint.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  isEditing ? 'Save Changes' : 'Add Letter',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.accentMint, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    LetterModel letter,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 14),
            const Text('Delete Letter'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${letter.charOlChiki}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(lettersProvider.notifier).deleteLetter(letter.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final LetterModel letter;
  final bool isDark;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LetterCard({
    required this.letter,
    required this.isDark,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onEdit,
          onLongPress: onDelete,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.premiumMint,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentMint.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter.charOlChiki,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'OlChiki',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    letter.transliterationLatin,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9));
  }
}
