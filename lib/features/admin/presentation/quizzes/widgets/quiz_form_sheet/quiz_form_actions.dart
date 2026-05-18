import 'package:flutter/material.dart';

class QuizFormActions extends StatelessWidget {
  final bool isEditing;
  final bool isSaveEnabled;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const QuizFormActions({
    super.key,
    required this.isEditing,
    required this.isSaveEnabled,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: isSaveEnabled ? onSave : null,
              child: Text(isEditing ? 'Save Changes' : 'Create Quiz'),
            ),
          ),
        ],
      ),
    );
  }
}
