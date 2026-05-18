import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../widgets/admin_page_header.dart';

class RhymeCategoriesHeader extends StatelessWidget {
  final int count;

  const RhymeCategoriesHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminTokens.space7),
      child: AdminPageHeader(
        title: 'Bakhed Categories',
        subtitle: 'Manage categories & subcategories ($count categories)',
        eyebrow: 'CONTENT · CATEGORIES',
      ),
    );
  }
}
