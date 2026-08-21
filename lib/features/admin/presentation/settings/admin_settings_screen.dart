import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/upload_service.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_form_widgets.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_destructive_dialog.dart';
import 'controllers/admin_maintenance_controller.dart';
import 'controllers/admin_settings_controller.dart';
import 'sections/admin_badge_names_section.dart';
import 'sections/admin_danger_zone_section.dart';
import 'sections/admin_desktop_behavior_section.dart';
import 'sections/admin_onboarding_video_section.dart';
import 'widgets/admin_settings_section_card.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  bool _isUploading = false;
  late final TextEditingController _archerNameController;
  late final TextEditingController _kudumNameController;
  late final TextEditingController _kherwalNameController;
  late final TextEditingController _razorpayKeyController;
  List<Map<String, String>> _localGoalsList = [];
  bool _isGoalsInitialized = false;

  @override
  void initState() {
    super.initState();
    _archerNameController = TextEditingController();
    _kudumNameController = TextEditingController();
    _kherwalNameController = TextEditingController();
    _razorpayKeyController = TextEditingController();

    _archerNameController.addListener(_checkDirty);
    _kudumNameController.addListener(_checkDirty);
    _kherwalNameController.addListener(_checkDirty);
    _razorpayKeyController.addListener(_checkDirty);
  }

  @override
  void dispose() {
    _archerNameController.dispose();
    _kudumNameController.dispose();
    _kherwalNameController.dispose();
    _razorpayKeyController.dispose();
    super.dispose();
  }

  void _checkDirty() {
    final state = ref.read(adminSettingsControllerProvider);
    final isDirty =
        _archerNameController.text.trim() != state.badgeArcher ||
        _kudumNameController.text.trim() != state.badgeKudum ||
        _kherwalNameController.text.trim() != state.badgeKherwal ||
        _razorpayKeyController.text.trim() != state.razorpayKeyId;
    ref.read(adminSettingsControllerProvider.notifier).markDirty(isDirty);
  }

  void _syncControllersWithState(AdminSettingsState state) {
    if (state.isLoaded && !_isGoalsInitialized) {
      _archerNameController.text = state.badgeArcher;
      _kudumNameController.text = state.badgeKudum;
      _kherwalNameController.text = state.badgeKherwal;
      _razorpayKeyController.text = state.razorpayKeyId;
      _localGoalsList = List<Map<String, String>>.from(
        state.goalsList.map(Map<String, String>.from),
      );
      _isGoalsInitialized = true;
    }
  }

  Future<void> _uploadOnboardingVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'webm'],
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);
      final uploadedUrl = await ref
          .read(uploadServiceProvider)
          .uploadMedia(result.files.first, 'onboarding');

      if (uploadedUrl == null) {
        if (mounted) setState(() => _isUploading = false);
        return;
      }

      final success = await ref
          .read(adminSettingsControllerProvider.notifier)
          .saveSetting('onboarding_video_url', uploadedUrl);

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (success) {
        _showSnackBar('Onboarding video updated! ✨', AppColors.success);
      } else {
        _showSnackBar('Failed to update onboarding video.', AppColors.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Upload failed: $e', AppColors.error);
      }
    }
  }

  Future<void> _resetToDefaultVideo() async {
    final success = await ref
        .read(adminSettingsControllerProvider.notifier)
        .saveSetting('onboarding_video_url', '');
    if (mounted) {
      if (success) {
        _showSnackBar('Reset to default bundled video.');
      } else {
        _showSnackBar('Failed to reset video.', AppColors.error);
      }
    }
  }

  Future<void> _saveBadgeNames() async {
    final success = await ref
        .read(adminSettingsControllerProvider.notifier)
        .saveBadgeNames(
          archer: _archerNameController.text,
          kudum: _kudumNameController.text,
          kherwal: _kherwalNameController.text,
        );

    if (mounted) {
      if (success) {
        _showSnackBar('Traditional badge names updated! 🎯', AppColors.success);
      } else {
        final err =
            ref.read(adminSettingsControllerProvider).failure?.userMessage ??
            'Failed to save badge names.';
        _showSnackBar(err, AppColors.error);
      }
    }
  }

  void _resetBadgeNamesToDefault() {
    setState(() {
      _archerNameController.text = 'Santali Archer';
      _kudumNameController.text = 'Kudum Master';
      _kherwalNameController.text = 'Kherwal Elder';
    });
    _saveBadgeNames();
  }

  Future<void> _showWipeConfirmationDialog() async {
    await AdminDestructiveDialog.show(
      context: context,
      title: 'Database Reset & Re-Seed',
      actionName: 'Wipe & Re-Seed Database',
      targetName: 'All Appwrite database content collections',
      blastRadiusDescription:
          'This will trigger a server-side backup first, then purge all letters, words, sentences, stories, and quizzes, and seed default production datasets.',
      requiresTypedConfirmation: true,
      typedConfirmationKeyword: 'WIPE-AND-SEED',
      confirmButtonLabel: 'Wipe & Re-Seed Database',
      icon: Icons.delete_forever_rounded,
      onConfirm: () async {
        final backupId = await AdminMaintenanceController(ref).wipeAndSeed();
        if (mounted) {
          _showSnackBar(
            backupId == null
                ? 'Database successfully wiped and seeded! ✨'
                : 'Database wiped and seeded. Backup: $backupId ✨',
            AppColors.success,
          );
        }
      },
    );
  }

  Future<void> _executeBackupContent() async {
    try {
      final backupId = await AdminMaintenanceController(ref).backupContent();
      if (mounted) {
        _showSnackBar(
          backupId == null
              ? 'Content backup created successfully.'
              : 'Content backup created: $backupId',
          AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Backup failed: $e', AppColors.error);
    }
  }

  void _showSnackBar(String message, [Color? backgroundColor]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSettingsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _syncControllersWithState(state);

    return PopScope(
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes in Settings. Leaving now will discard your edits.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Discard & Leave'),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(
                  child: AdminLoadingState(
                    label: 'Loading system settings from server…',
                  ),
                );
              }

              if (state.hasLoadFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 540),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AdminTokens.raised(isDark),
                        borderRadius: BorderRadius.circular(
                          AdminTokens.radiusLg,
                        ),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.35),
                        ),
                        boxShadow: AdminTokens.raisedShadow(isDark),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(
                                alpha: isDark ? 0.16 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(
                                AdminTokens.radiusMd,
                              ),
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to Load Settings',
                            style: AdminTokens.sectionTitle(isDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.failure?.userMessage ??
                                'Unable to connect to settings database. Settings editors remain locked to protect configuration integrity.',
                            textAlign: TextAlign.center,
                            style: AdminTokens.body(isDark),
                          ),
                          const SizedBox(height: 20),
                          AdminPrimaryButton(
                            label: 'Retry Connection',
                            icon: Icons.refresh_rounded,
                            onTap: () => ref
                                .read(adminSettingsControllerProvider.notifier)
                                .loadSettings(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AdminTokens.space7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminPageHeader(
                      title: 'App Settings',
                      subtitle:
                          'Manage onboarding, payment gateways, and app configuration',
                      eyebrow: 'SYSTEM · SETTINGS',
                    ),
                    const SizedBox(height: 28),

                    // Onboarding Video Section
                    AdminSettingsSectionCard(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Onboarding Video',
                      subtitle:
                          'Upload a custom onboarding video or use the default bundled asset. Disabled on desktop/web.',
                      child: AdminOnboardingVideoSection(
                        currentVideoUrl: state.onboardingVideoUrl,
                        isUploading: _isUploading,
                        onUpload: _uploadOnboardingVideo,
                        onReset: _resetToDefaultVideo,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Desktop Behavior Section
                    const AdminSettingsSectionCard(
                      icon: Icons.desktop_windows_rounded,
                      title: 'Desktop / Web Behavior',
                      subtitle:
                          'Onboarding video is automatically skipped on desktop screens (width > 900px). Users are redirected directly to the welcome or home screen.',
                      child: AdminDesktopBehaviorSection(),
                    ),
                    const SizedBox(height: 24),

                    // Traditional Mastery Badges Section
                    AdminSettingsSectionCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Traditional Mastery Badges',
                      subtitle:
                          'Customize the names of the Santali traditional badges (Folk & Culture) displayed on user profiles. Stored in local preferences.',
                      child: AdminBadgeNamesSection(
                        archerNameController: _archerNameController,
                        kudumNameController: _kudumNameController,
                        kherwalNameController: _kherwalNameController,
                        onSave: _saveBadgeNames,
                        onReset: _resetBadgeNamesToDefault,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Onboarding Goals Section (Adaptive Mobile/Desktop)
                    AdminSettingsSectionCard(
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
                                  separatorBuilder: (_, _) => Divider(
                                    height: 20,
                                    color: AdminTokens.divider(isDark),
                                  ),
                                  itemBuilder: (context, index) {
                                    final goal = _localGoalsList[index];
                                    final goalTitleField = TextFormField(
                                      key: ValueKey(
                                        '${goal['id']}_title_$index',
                                      ),
                                      initialValue: goal['title'],
                                      style: AdminTokens.body(isDark),
                                      decoration: InputDecoration(
                                        labelText: 'Goal Title',
                                        labelStyle: AdminTokens.label(isDark),
                                        filled: true,
                                        fillColor: AdminTokens.sunken(isDark),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                                            .read(
                                              adminSettingsControllerProvider
                                                  .notifier,
                                            )
                                            .markDirty(true);
                                      },
                                    );

                                    final goalIconDropdown =
                                        DropdownButtonFormField<String>(
                                          initialValue: goal['icon'],
                                          dropdownColor: AdminTokens.overlay(
                                            isDark,
                                          ),
                                          style: AdminTokens.body(isDark),
                                          decoration: InputDecoration(
                                            labelText: 'Icon',
                                            labelStyle: AdminTokens.label(
                                              isDark,
                                            ),
                                            filled: true,
                                            fillColor: AdminTokens.sunken(
                                              isDark,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: AdminTokens.border(
                                                  isDark,
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AdminTokens.radiusSm,
                                                  ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
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
                                              setState(() {
                                                _localGoalsList[index]['icon'] =
                                                    val;
                                              });
                                              ref
                                                  .read(
                                                    adminSettingsControllerProvider
                                                        .notifier,
                                                  )
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
                                        setState(() {
                                          _localGoalsList.removeAt(index);
                                        });
                                        ref
                                            .read(
                                              adminSettingsControllerProvider
                                                  .notifier,
                                            )
                                            .markDirty(true);
                                      },
                                    );

                                    if (isNarrow) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: goalTitleField,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          flex: 2,
                                          child: goalIconDropdown,
                                        ),
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
                                        setState(() {
                                          final uniqueId =
                                              'goal_${DateTime.now().millisecondsSinceEpoch}';
                                          _localGoalsList.add({
                                            'id': uniqueId,
                                            'title': 'New Learning Goal',
                                            'icon': 'translate_rounded',
                                          });
                                        });
                                        ref
                                            .read(
                                              adminSettingsControllerProvider
                                                  .notifier,
                                            )
                                            .markDirty(true);
                                      },
                                    ),
                                    AdminSecondaryButton(
                                      label: 'Reset Defaults',
                                      onTap: () {
                                        setState(() {
                                          _localGoalsList =
                                              AdminSettingsController
                                                  .defaultGoals
                                                  .map(Map<String, String>.from)
                                                  .toList();
                                        });
                                        ref
                                            .read(
                                              adminSettingsControllerProvider
                                                  .notifier,
                                            )
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
                                            .read(
                                              adminSettingsControllerProvider
                                                  .notifier,
                                            )
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
                                                    .read(
                                                      adminSettingsControllerProvider,
                                                    )
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
                    ),
                    const SizedBox(height: 24),

                    // Monetization Controls Section
                    AdminSettingsSectionCard(
                      icon: Icons.monetization_on_rounded,
                      title: 'Monetization Controls',
                      subtitle:
                          'Configure pricing options, payment gateway credentials, and global course unlock methods.',
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Global Play Store Review Unlock',
                                style: AdminTokens.bodyStrong(isDark),
                              ),
                              subtitle: Text(
                                'When enabled, users can unlock eligible premium categories by leaving a Play Store review instead of paying. Note: Each user can only use the review unlock method once across all courses.',
                                style: AdminTokens.body(
                                  isDark,
                                ).copyWith(fontSize: 12),
                              ),
                              value: state.globalReviewUnlockEnabled,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) async {
                                final success = await ref
                                    .read(
                                      adminSettingsControllerProvider.notifier,
                                    )
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
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Divider(
                                color: AdminTokens.divider(isDark),
                              ),
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
                              hint:
                                  'rzp_live_xxxxxxxxxxxxxx or rzp_test_xxxxxxxxxxxxxx',
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
                                  final key = _razorpayKeyController.text
                                      .trim();
                                  final success = await ref
                                      .read(
                                        adminSettingsControllerProvider
                                            .notifier,
                                      )
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
                                              .read(
                                                adminSettingsControllerProvider,
                                              )
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
                    ),
                    const SizedBox(height: 24),

                    // Danger Zone Section
                    AdminSettingsSectionCard(
                      isDanger: true,
                      icon: Icons.dangerous_rounded,
                      title: 'Danger Zone',
                      subtitle:
                          'Perform privileged maintenance actions. Destructive resets create a server-side backup first.',
                      child: AdminDangerZoneSection(
                        onBackup: _executeBackupContent,
                        onWipe: _showWipeConfirmationDialog,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
