import 'package:flutter/material.dart';

import '../../widgets/admin_form_widgets.dart';

class AdminBadgeNamesSection extends StatelessWidget {
  const AdminBadgeNamesSection({
    super.key,
    required this.archerNameController,
    required this.kudumNameController,
    required this.kherwalNameController,
    required this.onSave,
    required this.onReset,
  });

  final TextEditingController archerNameController;
  final TextEditingController kudumNameController;
  final TextEditingController kherwalNameController;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTextField(
            controller: archerNameController,
            label: 'Archer Badge (Folk Craft / Mastery)',
            hint: 'Santali Archer',
            prefixIcon: Icons.insights_rounded,
          ),
          const SizedBox(height: 16),
          AdminTextField(
            controller: kudumNameController,
            label: 'Kudum Badge (Folk Proverbs / Riddles)',
            hint: 'Kudum Master',
            prefixIcon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 16),
          AdminTextField(
            controller: kherwalNameController,
            label: 'Kherwal Badge (Traditional Elder / Storyteller)',
            hint: 'Kherwal Elder',
            prefixIcon: Icons.people_outline_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AdminPrimaryButton(
                  label: 'Save Badge Names',
                  icon: Icons.save_rounded,
                  onTap: onSave,
                ),
              ),
              const SizedBox(width: 12),
              AdminSecondaryButton(
                label: 'Reset Defaults',
                icon: Icons.restore_rounded,
                onTap: onReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
