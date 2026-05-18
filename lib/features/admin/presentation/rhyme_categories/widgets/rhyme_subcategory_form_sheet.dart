import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../rhymes/domain/rhyme_category_model.dart';
import '../../widgets/admin_form_widgets.dart';

class RhymeSubcategoryFormSheet extends StatefulWidget {
  final String categoryId;
  final RhymeSubcategoryModel? subcategory;
  final int categorySubcategoriesCount;
  final ValueChanged<RhymeSubcategoryModel> onSave;

  const RhymeSubcategoryFormSheet({
    super.key,
    required this.categoryId,
    this.subcategory,
    required this.categorySubcategoriesCount,
    required this.onSave,
  });

  @override
  State<RhymeSubcategoryFormSheet> createState() =>
      _RhymeSubcategoryFormSheetState();
}

class _RhymeSubcategoryFormSheetState extends State<RhymeSubcategoryFormSheet> {
  late final TextEditingController _nameLatinCtrl;
  late final TextEditingController _nameOlChikiCtrl;

  @override
  void initState() {
    super.initState();
    _nameLatinCtrl = TextEditingController(text: widget.subcategory?.nameLatin);
    _nameOlChikiCtrl = TextEditingController(
      text: widget.subcategory?.nameOlChiki,
    );
  }

  @override
  void dispose() {
    _nameLatinCtrl.dispose();
    _nameOlChikiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminModalSheet(
      title: widget.subcategory == null
          ? 'Add Subcategory'
          : 'Edit Subcategory',
      subtitle: 'A child group nested under a category',
      icon: Icons.subdirectory_arrow_right_rounded,
      primaryLabel: widget.subcategory == null
          ? 'Create Subcategory'
          : 'Save Changes',
      heightFactor: 0.55,
      onPrimary: () {
        final item = RhymeSubcategoryModel(
          id:
              widget.subcategory?.id ??
              'rsub_${const Uuid().v4().substring(0, 8)}',
          categoryId: widget.categoryId,
          nameOlChiki: _nameOlChikiCtrl.text,
          nameLatin: _nameLatinCtrl.text,
          order: widget.subcategory?.order ?? widget.categorySubcategoriesCount,
        );
        widget.onSave(item);
        Navigator.pop(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTextField(
            controller: _nameLatinCtrl,
            label: 'Name (Latin)',
            hint: 'e.g. Tigers',
          ),
          const SizedBox(height: AdminTokens.space5),
          AdminTextField(
            controller: _nameOlChikiCtrl,
            label: 'Name (Ol Chiki)',
            hint: 'ᱠᱩᱞ',
          ),
        ],
      ),
    );
  }
}
