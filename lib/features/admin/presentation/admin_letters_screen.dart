import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';

class AdminLettersScreen extends ConsumerWidget {
  const AdminLettersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lettersAsync = ref.watch(lettersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isWideScreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              leading: CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.go('/admin'),
              ),
              title: const Text('Ol Chiki Letters'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLetterDialog(context, ref, null),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWideScreen)
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ol Chiki Letters',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Manage alphabet characters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    PrimaryButton(
                      text: 'Add Letter',
                      
                      icon: Icons.add_rounded,
                      onPressed: () => _showLetterDialog(context, ref, null),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: lettersAsync.when(
                data: (letters) {
                  if (letters.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.abc_rounded,
                            size: 64,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'No letters yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppConstants.spacingS),
                          PrimaryButton(
                            text: 'Add First Letter',
                            
                            onPressed: () => _showLetterDialog(context, ref, null),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWideScreen ? 6 : 3,
                      crossAxisSpacing: AppConstants.spacingM,
                      mainAxisSpacing: AppConstants.spacingM,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: letters.length,
                    itemBuilder: (context, index) {
                      final letter = letters[index];
                      return _LetterCard(
                        letter: letter,
                        onTap: () => _showLetterDialog(context, ref, letter),
                        onDelete: () => _showDeleteDialog(context, ref, letter),
                      );
                    },
                  );
                },
                loading: () => const ShimmerCategoryGrid(itemCount: 6),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLetterDialog(BuildContext context, WidgetRef ref, LetterModel? letter) {
    final isEditing = letter != null;
    final charController = TextEditingController(text: letter?.charOlChiki ?? '');
    final translitController = TextEditingController(text: letter?.transliterationLatin ?? '');
    final exampleOlChikiController = TextEditingController(text: letter?.exampleWordOlChiki ?? '');
    final exampleLatinController = TextEditingController(text: letter?.exampleWordLatin ?? '');
    final pronunciationController = TextEditingController(text: letter?.pronunciation ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: Text(isEditing ? 'Edit Letter' : 'Add Letter'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: charController,
                decoration: const InputDecoration(
                  labelText: 'Ol Chiki Character',
                  hintText: 'e.g., ᱚ',
                ),
                style: const TextStyle(fontFamily: 'OlChiki', fontSize: 24),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: translitController,
                decoration: const InputDecoration(
                  labelText: 'Transliteration (Latin)',
                  hintText: 'e.g., A',
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: pronunciationController,
                decoration: const InputDecoration(
                  labelText: 'Pronunciation',
                  hintText: 'e.g., ah (as in father)',
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: exampleOlChikiController,
                decoration: const InputDecoration(
                  labelText: 'Example Word (Ol Chiki)',
                  hintText: 'e.g., ᱟᱹᱜᱩ',
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: exampleLatinController,
                decoration: const InputDecoration(
                  labelText: 'Example Word (Latin)',
                  hintText: 'e.g., fire',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final contentRepo = ref.read(contentRepositoryProvider);
              final newLetter = LetterModel(
                id: letter?.id ?? '',
                charOlChiki: charController.text,
                transliterationLatin: translitController.text,
                exampleWordOlChiki: exampleOlChikiController.text.isNotEmpty ? exampleOlChikiController.text : null,
                exampleWordLatin: exampleLatinController.text.isNotEmpty ? exampleLatinController.text : null,
                pronunciation: pronunciationController.text.isNotEmpty ? pronunciationController.text : null,
                order: letter?.order ?? 0,
                isActive: true,
              );
              await contentRepo.saveLetter(newLetter);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, LetterModel letter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        title: const Text('Delete Letter'),
        content: Text('Are you sure you want to delete "${letter.charOlChiki}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final contentRepo = ref.read(contentRepositoryProvider);
              await contentRepo.deleteLetter(letter.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final LetterModel letter;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LetterCard({
    required this.letter,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingS),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: onDelete,
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.error,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter.charOlChiki,
                  style: const TextStyle(
                    fontFamily: 'OlChiki',
                    fontSize: 36,
                    color: AppColors.primaryCyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  letter.transliterationLatin,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (letter.exampleWordLatin != null)
                  Text(
                    letter.exampleWordLatin!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
