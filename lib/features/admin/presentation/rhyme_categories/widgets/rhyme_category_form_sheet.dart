import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../rhymes/domain/rhyme_category_model.dart';
import '../../widgets/admin_form_widgets.dart';

class RhymeCategoryFormSheet extends StatefulWidget {
  final RhymeCategoryModel? category;
  final int categoryCount;
  final ValueChanged<RhymeCategoryModel> onSave;

  const RhymeCategoryFormSheet({
    super.key,
    this.category,
    required this.categoryCount,
    required this.onSave,
  });

  @override
  State<RhymeCategoryFormSheet> createState() => _RhymeCategoryFormSheetState();
}

class _RhymeCategoryFormSheetState extends State<RhymeCategoryFormSheet> {
  late final TextEditingController _nameLatinCtrl;
  late final TextEditingController _nameOlChikiCtrl;
  late String _iconName;

  final _iconOptions = const [
    'agriculture',
    'local_florist',
    'eco',
    'child_friendly',
    'favorite',
    'group',
  ];

  @override
  void initState() {
    super.initState();
    _nameLatinCtrl = TextEditingController(text: widget.category?.nameLatin);
    _nameOlChikiCtrl = TextEditingController(
      text: widget.category?.nameOlChiki,
    );
    _iconName = widget.category?.iconName ?? 'folder';
  }

  @override
  void dispose() {
    _nameLatinCtrl.dispose();
    _nameOlChikiCtrl.dispose();
    super.dispose();
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'agriculture':
        return Icons.agriculture_rounded;
      case 'local_florist':
        return Icons.local_florist_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'child_friendly':
        return Icons.child_friendly_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'group':
        return Icons.group_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminModalSheet(
      title: widget.category == null ? 'Add Category' : 'Edit Category',
      subtitle: 'Organise bakhed into top-level groups',
      icon: Icons.folder_rounded,
      primaryLabel: widget.category == null
          ? 'Create Category'
          : 'Save Changes',
      heightFactor: 0.7,
      onPrimary: () {
        final item = RhymeCategoryModel(
          id:
              widget.category?.id ??
              'rcat_${const Uuid().v4().substring(0, 8)}',
          nameOlChiki: _nameOlChikiCtrl.text,
          nameLatin: _nameLatinCtrl.text,
          iconName: _iconName,
          order: widget.category?.order ?? widget.categoryCount,
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
            hint: 'e.g. Animals',
          ),
          const SizedBox(height: AdminTokens.space5),
          AdminTextField(
            controller: _nameOlChikiCtrl,
            label: 'Name (Ol Chiki)',
            hint: 'ᱡᱟᱱᱣᱟᱨ',
          ),
          const SizedBox(height: AdminTokens.space5),
          Text('Icon', style: AdminTokens.label(isDark)),
          const SizedBox(height: AdminTokens.space2),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _iconOptions.map((e) {
              final selected = _iconName == e;
              return GestureDetector(
                onTap: () => setState(() => _iconName = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AdminTokens.accentSoft(isDark)
                        : AdminTokens.sunken(isDark),
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    border: Border.all(
                      color: selected
                          ? AdminTokens.accentBorder(isDark)
                          : AdminTokens.border(isDark),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconFromName(e),
                        size: 18,
                        color: selected
                            ? AdminTokens.accent
                            : AdminTokens.textSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e,
                        style: AdminTokens.label(isDark).copyWith(
                          color: selected
                              ? AdminTokens.accent
                              : AdminTokens.textSecondary(isDark),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
