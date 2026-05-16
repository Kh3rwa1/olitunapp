import 'package:flutter/material.dart';
import '../../../../../../shared/models/content_models.dart' hide CategoryModel;

/// This file is reserved for extracting the state management logic
/// of the quiz form (e.g., as a Notifier or a dedicated State class)
/// in the future, decoupling it from the QuizFormSheet widget.
class QuizFormState {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController orderCtrl;
  final TextEditingController passingScoreCtrl;
  String? selectedCategoryId;
  String level;
  bool isActive;
  List<QuizQuestion> questions;

  QuizFormState({
    required this.formKey,
    required this.titleCtrl,
    required this.orderCtrl,
    required this.passingScoreCtrl,
    this.selectedCategoryId,
    this.level = 'beginner',
    this.isActive = true,
    required this.questions,
  });

  void dispose() {
    titleCtrl.dispose();
    orderCtrl.dispose();
    passingScoreCtrl.dispose();
  }
}
