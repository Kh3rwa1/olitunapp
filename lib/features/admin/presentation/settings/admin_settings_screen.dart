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
import 'sections/admin_admob_section.dart';
import 'sections/admin_badge_names_section.dart';
import 'sections/admin_danger_zone_section.dart';
import 'sections/admin_desktop_behavior_section.dart';
import 'sections/admin_onboarding_video_section.dart';
import 'widgets/admin_settings_section_card.dart';
part 'widgets/admin_settings_sections.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  /// Forwards to [setState] so extracted section builders (extensions on this
  /// State) can trigger rebuilds without touching protected members directly.
  void _setState(VoidCallback fn) => setState(fn);

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
                    _buildOnboardingGoalsSection(state, isDark),
                    const SizedBox(height: 24),

                    // Monetization Controls Section
                    _buildMonetizationSection(state, isDark),
                    const SizedBox(height: 24),

                    // Google AdMob Monetization Section
                    const AdminSettingsSectionCard(
                      icon: Icons.ads_click_rounded,
                      title: 'Google AdMob Monetization',
                      subtitle:
                          'Configure banner, interstitial, rewarded, and native ads, frequency caps, and test tools.',
                      child: AdminAdmobSection(),
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
