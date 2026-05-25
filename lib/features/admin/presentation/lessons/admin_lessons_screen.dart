import 'package:flutter/material.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/shared/models/content_item.dart';

class AdminLessonsScreen extends StatelessWidget {
  final String? categoryId;
  const AdminLessonsScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return AdminContentListScreen(
      kind: ContentKind.lesson,
      categoryId: categoryId,
    );
  }
}
