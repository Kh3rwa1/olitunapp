import 'package:flutter/material.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/shared/models/content_item.dart';

class AdminLessonsScreen extends StatelessWidget {
  const AdminLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminContentListScreen(kind: ContentKind.lesson);
  }
}
