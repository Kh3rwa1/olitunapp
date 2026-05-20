import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_page_header.dart';
import 'widgets/admin_form_widgets.dart';
import '../../../core/storage/upload_service.dart';
import '../../../core/api/appwrite_db_service.dart';
import '../../../core/storage/cache_service.dart';
import '../../../core/storage/hive_service.dart';
import '../../../shared/providers/providers.dart';

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
      if (mounted) {
        final settings = <String, dynamic>{};
        for (final doc in docs) {
          settings[doc['settingKey'] as String] = doc['settingValue'];
        }
        setState(() {
          _currentVideoUrl = settings['onboarding_video_url'] as String?;
          _archerNameController.text = ref.read(badgeTraditionalArcherNameProvider);
          _kudumNameController.text = ref.read(badgeTraditionalKudumNameProvider);
          _kherwalNameController.text = ref.read(badgeTraditionalKherwalNameProvider);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadOnboardingVideo() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'webm'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isUploading = true);

        final file = result.files.first;
        final uploadedUrl = await ref
            .read(uploadServiceProvider)
            .uploadMedia(file, 'onboarding');

        if (uploadedUrl != null) {
          await _saveSetting('onboarding_video_url', uploadedUrl);
          setState(() {
            _currentVideoUrl = uploadedUrl;
            _isUploading = false;
          });
          ref.invalidate(appSettingsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Onboarding video updated! ✨'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    try {
      await _saveSetting('onboarding_video_url', '');
      setState(() => _currentVideoUrl = null);
      ref.invalidate(appSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset to default bundled video'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reset failed: $e')));
      }
    }
  }

  Future<void> _saveBadgeNames() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final archer = _archerNameController.text.trim();
    final kudum = _kudumNameController.text.trim();
    final kherwal = _kherwalNameController.text.trim();

    if (archer.isEmpty || kudum.isEmpty || kherwal.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badge names cannot be empty!'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await prefs.setString('badge_traditional_archer_name', archer);
    await prefs.setString('badge_traditional_kudum_name', kudum);
    await prefs.setString('badge_traditional_kherwal_name', kherwal);

    ref.read(badgeTraditionalArcherNameProvider.notifier).state = archer;
    ref.read(badgeTraditionalKudumNameProvider.notifier).state = kudum;
    ref.read(badgeTraditionalKherwalNameProvider.notifier).state = kherwal;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Traditional badge names updated! 🎯'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
    // Try to update existing setting, or create new one
    try {
      // Use key as document ID for easy lookup
      await db.updateDocument('app_settings', key, {
        'settingKey': key,
        'settingValue': value,
      });
    } catch (_) {
      // If not found, create it
      await db.createDocument('app_settings', key, {
        'settingKey': key,
        'settingValue': value,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      subtitle: 'Manage onboarding, defaults, and app configuration',
                      eyebrow: 'SYSTEM · SETTINGS',
                    ),
                    const SizedBox(height: 40),

                    // Onboarding Video Section
                    _buildSectionCard(
                      isDark: isDark,
                      icon: Icons.ondemand_video_rounded,
                      title: 'Onboarding Video',
                      subtitle:
                          'Upload a custom onboarding video or use the default bundled asset. Disabled on desktop/web.',
                      child: _buildVideoSection(isDark),
                    ),

                    const SizedBox(height: 24),

                    // Desktop Behavior Section
                    _buildSectionCard(
                      isDark: isDark,
                      icon: Icons.desktop_windows_rounded,
                      title: 'Desktop / Web Behavior',
                      subtitle:
                          'Onboarding video is automatically skipped on desktop screens (width > 900px). Users are redirected directly to the welcome or home screen.',
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AdminTokens.radiusMd,
                                ),
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.28),
                                ),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Desktop skip is active. No user action needed.',
                                style: AdminTokens.bodyStrong(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Mastery Badge Section
                    _buildSectionCard(
                      isDark: isDark,
                      icon: Icons.emoji_events_rounded,
                      title: 'Traditional Mastery Badges',
                      subtitle:
                          'Customize the names of the Santali traditional badges (Folk & Culture) displayed on user profiles.',
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdminTextField(
                              controller: _archerNameController,
                              label: 'Archer Badge (Folk Craft / Mastery)',
                              hint: 'Santali Archer',
                              prefixIcon: Icons.insights_rounded,
                            ),
                            const SizedBox(height: 16),
                            AdminTextField(
                              controller: _kudumNameController,
                              label: 'Kudum Badge (Folk Proverbs / Riddles)',
                              hint: 'Kudum Master',
                              prefixIcon: Icons.menu_book_rounded,
                            ),
                            const SizedBox(height: 16),
                            AdminTextField(
                              controller: _kherwalNameController,
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
                                    onTap: _saveBadgeNames,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AdminSecondaryButton(
                                  label: 'Reset Defaults',
                                  icon: Icons.restore_rounded,
                                  onTap: _resetBadgeNamesToDefault,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Danger Zone Section
                    _buildSectionCard(
                      isDark: isDark,
                      isDanger: true,
                      icon: Icons.dangerous_rounded,
                      title: 'Danger Zone',
                      subtitle:
                          'Perform system destructive actions. This will erase the database collections entirely.',
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reset Database & Seeding',
                                    style: AdminTokens.bodyStrong(isDark).copyWith(
                                      color: isDark ? AppColors.error : AppColors.duoRedDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This will wipe all documents from categories, lessons, letters, numbers, words, sentences, and quizzes, clear the local Hive cache, and run a fresh seeder.',
                                    style: AdminTokens.body(isDark),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            AdminSecondaryButton(
                              label: 'Wipe & Re-seed',
                              icon: Icons.delete_forever_rounded,
                              destructive: true,
                              onTap: () => _showWipeConfirmationDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _showWipeConfirmationDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final confirmText = textController.text.trim();
            final isEnabled = confirmText == 'WIPE ALL';

            // Add controller listener to trigger modal redraw when typed value changes
            textController.addListener(() {
              if (dialogContext.mounted) {
                setDialogState(() {});
              }
            });

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: AdminTokens.overlay(isDark),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                  ),
                  boxShadow: AdminTokens.overlayShadow(isDark),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.28),
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Are you absolutely sure?',
                                style: AdminTokens.cardTitle(isDark).copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Destructive Action',
                                style: AdminTokens.eyebrow(
                                  isDark,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'This action will permanently delete all categorized content, lessons, words, sentences, and quizzes across all database collections, clear all client local storage content caches, and trigger a complete fresh seeding procedure.',
                      style: AdminTokens.body(isDark),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please type "WIPE ALL" in the box below to authorize this procedure:',
                      style: AdminTokens.bodyStrong(isDark),
                    ),
                    const SizedBox(height: 12),
                    AdminTextField(
                      controller: textController,
                      label: 'Authorization Key',
                      hint: 'WIPE ALL',
                      prefixIcon: Icons.vpn_key_rounded,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AdminSecondaryButton(
                          label: 'Cancel',
                          onTap: () => Navigator.of(dialogContext).pop(),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isEnabled
                                ? () {
                                    Navigator.of(dialogContext).pop();
                                    _executeWipeAndSeed();
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                            child: Opacity(
                              opacity: isEnabled ? 1.0 : 0.45,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(
                                    AdminTokens.radiusMd,
                                  ),
                                  boxShadow: isEnabled
                                      ? AdminTokens.brandGlow(
                                          AppColors.error,
                                          strength: 0.7,
                                        )
                                      : null,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_forever_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'WIPE ALL & RE-SEED',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _executeWipeAndSeed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = ref.read(appwriteDbServiceProvider);
      
      // 1. Wipe all Appwrite data
      await db.wipeAllData();
      
      // 2. Clear local Hive content cache
      await CacheService.clear();

      // 3. Re-seed the database
      await seedAppContent(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Database successfully wiped and seeded! ✨'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wipe & Seeding failed: $e ❌'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _loadSettings();
      }
    }
  }

  Widget _buildVideoSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentVideoUrl != null
                            ? AppColors.success
                            : AdminTokens.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _currentVideoUrl != null
                          ? 'Custom Video Active'
                          : 'Using Default Bundled Video',
                      style: AdminTokens.bodyStrong(isDark),
                    ),
                  ],
                ),
                if (_currentVideoUrl != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AdminTokens.base(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusXs),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Text(
                      _currentVideoUrl!,
                      style: AdminTokens.label(
                        isDark,
                      ).copyWith(fontFamily: 'monospace'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AdminPrimaryButton(
                  label: _isUploading ? 'Uploading…' : 'Upload Video',
                  icon: _isUploading
                      ? Icons.hourglass_top_rounded
                      : Icons.cloud_upload_rounded,
                  onTap: _isUploading ? () {} : _uploadOnboardingVideo,
                ),
              ),
              if (_currentVideoUrl != null) ...[
                const SizedBox(width: 12),
                AdminSecondaryButton(
                  label: 'Reset',
                  icon: Icons.restore_rounded,
                  onTap: _resetToDefault,
                ),
              ],
            ],
          ),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(
                backgroundColor: AdminTokens.accentSoft(isDark),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AdminTokens.accent,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    bool isDanger = false,
  }) {
    final borderCol = isDanger
        ? AppColors.error.withValues(alpha: 0.35)
        : AdminTokens.border(isDark);
    final accentCol = isDanger ? AppColors.error : AdminTokens.accent;
    final accentSoftCol = isDanger
        ? AppColors.error.withValues(alpha: isDark ? 0.14 : 0.10)
        : AdminTokens.accentSoft(isDark);
    final accentBorderCol = isDanger
        ? AppColors.error.withValues(alpha: isDark ? 0.34 : 0.28)
        : AdminTokens.accentBorder(isDark);

    return Container(
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
        border: Border.all(color: borderCol),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentSoftCol,
                    borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                    border: Border.all(color: accentBorderCol),
                  ),
                  child: Icon(icon, color: accentCol, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AdminTokens.sectionTitle(isDark)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AdminTokens.body(isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDanger ? borderCol : AdminTokens.divider(isDark),
          ),
          child,
        ],
      ),
    );
  }
}
