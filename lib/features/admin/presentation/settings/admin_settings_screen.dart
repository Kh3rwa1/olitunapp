import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/appwrite_db_service.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/storage/upload_service.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/admin_form_widgets.dart';
import '../widgets/admin_page_header.dart';
import 'controllers/admin_maintenance_controller.dart';
import 'forms/admin_wipe_confirmation_dialog.dart';
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
  String? _currentVideoUrl;
  bool _isLoading = true;

  late final TextEditingController _archerNameController;
  late final TextEditingController _kudumNameController;
  late final TextEditingController _kherwalNameController;

  @override
  void initState() {
    super.initState();
    _archerNameController = TextEditingController();
    _kudumNameController = TextEditingController();
    _kherwalNameController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _archerNameController.dispose();
    _kudumNameController.dispose();
    _kherwalNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final docs = await db.listDocuments('app_settings');
      if (!mounted) return;

      final settings = <String, dynamic>{};
      for (final doc in docs) {
        settings[doc['settingKey'] as String] = doc['settingValue'];
      }
      setState(() {
        _currentVideoUrl = settings['onboarding_video_url'] as String?;
        _archerNameController.text = ref.read(
          badgeTraditionalArcherNameProvider,
        );
        _kudumNameController.text = ref.read(badgeTraditionalKudumNameProvider);
        _kherwalNameController.text = ref.read(
          badgeTraditionalKherwalNameProvider,
        );
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

      await _saveSetting('onboarding_video_url', uploadedUrl);
      if (!mounted) return;

      setState(() {
        _currentVideoUrl = uploadedUrl;
        _isUploading = false;
      });
      ref.invalidate(appSettingsProvider);
      _showSnackBar('Onboarding video updated! ✨', AppColors.success);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showSnackBar('Upload failed: $e', AppColors.error);
      }
    }
  }

  Future<void> _resetToDefault() async {
    try {
      await _saveSetting('onboarding_video_url', '');
      if (!mounted) return;

      setState(() => _currentVideoUrl = null);
      ref.invalidate(appSettingsProvider);
      _showSnackBar('Reset to default bundled video');
    } catch (e) {
      if (mounted) _showSnackBar('Reset failed: $e');
    }
  }

  Future<void> _saveBadgeNames() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final archer = _archerNameController.text.trim();
    final kudum = _kudumNameController.text.trim();
    final kherwal = _kherwalNameController.text.trim();

    if (archer.isEmpty || kudum.isEmpty || kherwal.isEmpty) {
      _showSnackBar('Badge names cannot be empty!', AppColors.error);
      return;
    }

    await prefs.setString('badge_traditional_archer_name', archer);
    await prefs.setString('badge_traditional_kudum_name', kudum);
    await prefs.setString('badge_traditional_kherwal_name', kherwal);

    ref.read(badgeTraditionalArcherNameProvider.notifier).state = archer;
    ref.read(badgeTraditionalKudumNameProvider.notifier).state = kudum;
    ref.read(badgeTraditionalKherwalNameProvider.notifier).state = kherwal;

    if (mounted) {
      _showSnackBar('Traditional badge names updated! 🎯', AppColors.success);
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

  Future<void> _saveSetting(String key, String value) async {
    final db = ref.read(appwriteDbServiceProvider);
    final data = {'settingKey': key, 'settingValue': value};

    try {
      await db.updateDocument('app_settings', key, data);
    } catch (_) {
      await db.createDocument('app_settings', key, data);
    }
  }

  Future<void> _showWipeConfirmationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          AdminWipeConfirmationDialog(onConfirm: _executeWipeAndSeed),
    );
  }

  Future<void> _executeWipeAndSeed() async {
    setState(() => _isLoading = true);

    try {
      final backupFileId = await AdminMaintenanceController(ref).wipeAndSeed();
      if (mounted) {
        _showSnackBar(
          backupFileId == null
              ? 'Database successfully wiped and seeded! ✨'
              : 'Database wiped and seeded. Backup: $backupFileId ✨',
          AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Wipe & Seeding failed: $e ❌', AppColors.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _loadSettings();
      }
    }
  }

  Future<void> _executeBackupContent() async {
    setState(() => _isLoading = true);

    try {
      final backupFileId = await AdminMaintenanceController(
        ref,
      ).backupContent();
      if (mounted) {
        _showSnackBar(
          backupFileId == null
              ? 'Content backup created.'
              : 'Content backup created: $backupFileId',
          AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Backup failed: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _loadSettings();
      }
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: AdminLoadingState(
                  label: 'Processing system settings & database updates…',
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AdminTokens.space7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminPageHeader(
                      title: 'App Settings',
                      subtitle:
                          'Manage onboarding, defaults, and app configuration',
                      eyebrow: 'SYSTEM · SETTINGS',
                    ),
                    const SizedBox(height: 40),
                    AdminSettingsSectionCard(
                      icon: Icons.ondemand_video_rounded,
                      title: 'Onboarding Video',
                      subtitle:
                          'Upload a custom onboarding video or use the default bundled asset. Disabled on desktop/web.',
                      child: AdminOnboardingVideoSection(
                        currentVideoUrl: _currentVideoUrl,
                        isUploading: _isUploading,
                        onUpload: _uploadOnboardingVideo,
                        onReset: _resetToDefault,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const AdminSettingsSectionCard(
                      icon: Icons.desktop_windows_rounded,
                      title: 'Desktop / Web Behavior',
                      subtitle:
                          'Onboarding video is automatically skipped on desktop screens (width > 900px). Users are redirected directly to the welcome or home screen.',
                      child: AdminDesktopBehaviorSection(),
                    ),
                    const SizedBox(height: 24),
                    AdminSettingsSectionCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Traditional Mastery Badges',
                      subtitle:
                          'Customize the names of the Santali traditional badges (Folk & Culture) displayed on user profiles.',
                      child: AdminBadgeNamesSection(
                        archerNameController: _archerNameController,
                        kudumNameController: _kudumNameController,
                        kherwalNameController: _kherwalNameController,
                        onSave: _saveBadgeNames,
                        onReset: _resetBadgeNamesToDefault,
                      ),
                    ),
                    const SizedBox(height: 24),
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
              ),
      ),
    );
  }
}
