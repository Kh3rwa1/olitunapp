part of '../admin_settings_screen.dart';

// Section builders extracted from the admin settings screen build method.
extension _AdminSettingsSections on _AdminSettingsScreenState {
  Widget _buildOnboardingGoalsSection(AdminSettingsState state, bool isDark) {
    return AdminSettingsSectionCard(
      icon: Icons.checklist_rounded,
      title: 'Onboarding Goals Management',
      subtitle:
          'Manage the multi-select learning goals displayed during the onboarding wizard flow.',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _localGoalsList.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 20, color: AdminTokens.divider(isDark)),
                  itemBuilder: (context, index) {
                    final goal = _localGoalsList[index];
                    final goalTitleField = TextFormField(
                      key: ValueKey('${goal['id']}_title_$index'),
                      initialValue: goal['title'],
                      style: AdminTokens.body(isDark),
                      decoration: InputDecoration(
                        labelText: 'Goal Title',
                        labelStyle: AdminTokens.label(isDark),
                        filled: true,
                        fillColor: AdminTokens.sunken(isDark),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AdminTokens.border(isDark),
                          ),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        _localGoalsList[index]['title'] = val;
                        ref
                            .read(adminSettingsControllerProvider.notifier)
                            .markDirty(true);
                      },
                    );

                    final goalIconDropdown = DropdownButtonFormField<String>(
                      initialValue: goal['icon'],
                      dropdownColor: AdminTokens.overlay(isDark),
                      style: AdminTokens.body(isDark),
                      decoration: InputDecoration(
                        labelText: 'Icon',
                        labelStyle: AdminTokens.label(isDark),
                        filled: true,
                        fillColor: AdminTokens.sunken(isDark),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AdminTokens.border(isDark),
                          ),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(
                            AdminTokens.radiusSm,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'translate_rounded',
                          child: Text('Translate'),
                        ),
                        DropdownMenuItem(
                          value: 'calendar_today_rounded',
                          child: Text('Calendar'),
                        ),
                        DropdownMenuItem(
                          value: 'trending_up_rounded',
                          child: Text('Trending Up'),
                        ),
                        DropdownMenuItem(
                          value: 'event_note_rounded',
                          child: Text('Event Note'),
                        ),
                        DropdownMenuItem(
                          value: 'business_center_rounded',
                          child: Text('Business'),
                        ),
                        DropdownMenuItem(
                          value: 'school_rounded',
                          child: Text('School'),
                        ),
                        DropdownMenuItem(
                          value: 'star_rounded',
                          child: Text('Star'),
                        ),
                        DropdownMenuItem(
                          value: 'favorite_rounded',
                          child: Text('Heart'),
                        ),
                        DropdownMenuItem(
                          value: 'lightbulb_rounded',
                          child: Text('Lightbulb'),
                        ),
                        DropdownMenuItem(
                          value: 'language_rounded',
                          child: Text('Language'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          _setState(() {
                            _localGoalsList[index]['icon'] = val;
                          });
                          ref
                              .read(adminSettingsControllerProvider.notifier)
                              .markDirty(true);
                        }
                      },
                    );

                    final deleteBtn = IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                      tooltip: 'Remove Goal',
                      onPressed: () {
                        _setState(() {
                          _localGoalsList.removeAt(index);
                        });
                        ref
                            .read(adminSettingsControllerProvider.notifier)
                            .markDirty(true);
                      },
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          goalTitleField,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: goalIconDropdown),
                              const SizedBox(width: 8),
                              deleteBtn,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: goalTitleField),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: goalIconDropdown),
                        const SizedBox(width: 8),
                        deleteBtn,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Actions row (Wrap for small screens)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AdminSecondaryButton(
                      icon: Icons.add_rounded,
                      label: 'Add Goal',
                      onTap: () {
                        _setState(() {
                          final uniqueId =
                              'goal_${DateTime.now().millisecondsSinceEpoch}';
                          _localGoalsList.add({
                            'id': uniqueId,
                            'title': 'New Learning Goal',
                            'icon': 'translate_rounded',
                          });
                        });
                        ref
                            .read(adminSettingsControllerProvider.notifier)
                            .markDirty(true);
                      },
                    ),
                    AdminSecondaryButton(
                      label: 'Reset Defaults',
                      onTap: () {
                        _setState(() {
                          _localGoalsList = AdminSettingsController.defaultGoals
                              .map(Map<String, String>.from)
                              .toList();
                        });
                        ref
                            .read(adminSettingsControllerProvider.notifier)
                            .markDirty(true);
                      },
                    ),
                    AdminPrimaryButton(
                      label: state.isSaving('onboarding_goals')
                          ? 'Saving Goals…'
                          : 'Save Goals',
                      icon: Icons.save_rounded,
                      onTap: () async {
                        final success = await ref
                            .read(adminSettingsControllerProvider.notifier)
                            .saveGoals(_localGoalsList);
                        if (mounted) {
                          if (success) {
                            _showSnackBar(
                              'Onboarding goals updated successfully! 🎯',
                              AppColors.success,
                            );
                          } else {
                            final err =
                                ref
                                    .read(adminSettingsControllerProvider)
                                    .failure
                                    ?.userMessage ??
                                'Failed to save onboarding goals.';
                            _showSnackBar(err, AppColors.error);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonetizationSection(AdminSettingsState state, bool isDark) {
    return AdminSettingsSectionCard(
      icon: Icons.monetization_on_rounded,
      title: 'Monetization Controls',
      subtitle:
          'Configure pricing options, payment gateway credentials, and global course unlock methods.',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SwitchListTile paints its background and ink on the nearest
            // Material ancestor; the section card's decorated Container
            // would hide both (framework assert) — give the tile its own
            // transparent Material.
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Global Play Store Review Unlock',
                  style: AdminTokens.bodyStrong(isDark),
                ),
                subtitle: Text(
                  'When enabled, users can unlock eligible premium categories by leaving a Play Store review instead of paying. Note: Each user can only use the review unlock method once across all courses.',
                  style: AdminTokens.body(isDark).copyWith(fontSize: 12),
                ),
                value: state.globalReviewUnlockEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) async {
                  final success = await ref
                      .read(adminSettingsControllerProvider.notifier)
                      .saveSetting(
                        'global_review_unlock_enabled',
                        val.toString(),
                      );
                  if (mounted) {
                    if (success) {
                      _showSnackBar(
                        'Monetization settings updated! 🪙',
                        AppColors.success,
                      );
                    } else {
                      _showSnackBar(
                        'Failed to update monetization settings.',
                        AppColors.error,
                      );
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: AdminTokens.divider(isDark)),
            ),

            // Gateway status indicator
            Row(
              children: [
                Icon(
                  state.razorpayKeyId.isNotEmpty
                      ? Icons.vpn_key_rounded
                      : Icons.lock_outline_rounded,
                  color: state.razorpayKeyId.isNotEmpty
                      ? AppColors.success
                      : Colors.orangeAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.razorpayKeyId.isNotEmpty
                        ? 'Custom Gateway Key ID Active'
                        : 'Default Build Gateway Key Active (Fallback)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: state.razorpayKeyId.isNotEmpty
                          ? AppColors.success
                          : Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AdminTextField(
              controller: _razorpayKeyController,
              label: 'Razorpay Publishable Key ID',
              hint: 'rzp_live_xxxxxxxxxxxxxx or rzp_test_xxxxxxxxxxxxxx',
              prefixIcon: Icons.vpn_key_rounded,
              helperText:
                  'Enter only the publishable Key ID (starts with rzp_live_ or rzp_test_). Never enter a secret key. If left blank, the app uses bundled credentials.',
            ),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: AdminPrimaryButton(
                label: state.isSaving('razorpay_key_id')
                    ? 'Saving Key…'
                    : 'Save Gateway Key',
                icon: Icons.save_rounded,
                onTap: () async {
                  final key = _razorpayKeyController.text.trim();
                  final success = await ref
                      .read(adminSettingsControllerProvider.notifier)
                      .saveSetting('razorpay_key_id', key);

                  if (mounted) {
                    if (success) {
                      _showSnackBar(
                        'Razorpay gateway key updated successfully! 💳',
                        AppColors.success,
                      );
                    } else {
                      final err =
                          ref
                              .read(adminSettingsControllerProvider)
                              .failure
                              ?.userMessage ??
                          'Failed to save gateway key.';
                      _showSnackBar(err, AppColors.error);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
