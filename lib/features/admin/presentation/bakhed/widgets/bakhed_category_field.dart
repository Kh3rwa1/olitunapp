import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';

class BakhedCategoryField extends ConsumerWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const BakhedCategoryField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(rhymeCategoriesProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (list) => list.map((c) => c.nameLatin).toList(),
      orElse: () => <String>[],
    );

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text.trim();
        final matching = categories
            .where((opt) => opt.toLowerCase().contains(text.toLowerCase()))
            .toList();

        if (text.isEmpty) {
          return matching;
        }

        final hasExactMatch = categories.any(
          (opt) => opt.toLowerCase() == text.toLowerCase(),
        );

        if (!hasExactMatch) {
          return ['+ Create new: "$text"', ...matching];
        }
        return matching;
      },
      onSelected: (String selection) {
        if (selection.startsWith('+ Create new: "')) {
          final cleanValue = selection.substring(
            selection.indexOf('"') + 1,
            selection.lastIndexOf('"'),
          );
          onChanged(cleanValue);
        } else {
          onChanged(selection);
        }
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  final text = textEditingController.text.trim();
                  if (text.isEmpty) {
                    onChanged(null);
                  } else {
                    onChanged(text);
                  }
                }
              },
              child: TextField(
                controller: textEditingController,
                focusNode: focusNode,
                enabled: enabled,
                onSubmitted: (val) {
                  final text = val.trim();
                  if (text.isEmpty) {
                    onChanged(null);
                  } else {
                    onChanged(text);
                  }
                  onFieldSubmitted();
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: 'Enter category name (e.g. Sohrai)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: enabled
                        ? () {
                            textEditingController.clear();
                            onChanged(null);
                          }
                        : null,
                  ),
                ),
              ),
            );
          },
      initialValue: TextEditingValue(text: initialValue ?? ''),
    );
  }
}
