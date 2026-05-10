import 'package:flutter/material.dart';
import '../../../../../shared/models/content_models.dart';
import 'letter_card.dart';

/// Grid layout for letter cards with responsive column count.
class LetterGrid extends StatelessWidget {
  final List<LetterModel> letters;
  final bool isDark;
  final bool isWideScreen;
  final void Function(LetterModel) onEdit;
  final void Function(LetterModel) onDelete;

  const LetterGrid({
    super.key,
    required this.letters,
    required this.isDark,
    required this.isWideScreen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
        return LetterCard(
          letter: letter,
          isDark: isDark,
          index: index,
          onEdit: () => onEdit(letter),
          onDelete: () => onDelete(letter),
        );
      },
    );
  }
}
