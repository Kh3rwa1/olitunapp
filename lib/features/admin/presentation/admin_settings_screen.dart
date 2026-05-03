import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/admin_page_header.dart';
import 'widgets/admin_form_widgets.dart';
import '../../../core/storage/upload_service.dart';
import '../../../core/api/appwrite_db_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
        child: SingleChildScrollView(
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
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: AdminLoadingState(label: 'Loading settings…'),
                      )
                    : _buildVideoSection(isDark),
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
                          borderRadius:
                              BorderRadius.circular(AdminTokens.radiusMd),
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
            ],
          ),
        ),
      ),
    );
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
                      borderRadius:
                          BorderRadius.circular(AdminTokens.radiusXs),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Text(
                      _currentVideoUrl!,
                      style: AdminTokens.label(isDark).copyWith(
                        fontFamily: 'monospace',
                      ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusXl),
        border: Border.all(color: AdminTokens.border(isDark)),
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
                    color: AdminTokens.accentSoft(isDark),
                    borderRadius:
                        BorderRadius.circular(AdminTokens.radiusMd),
                    border: Border.all(
                      color: AdminTokens.accentBorder(isDark),
                    ),
                  ),
                  child: Icon(icon, color: AdminTokens.accent, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AdminTokens.sectionTitle(isDark)),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AdminTokens.body(isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AdminTokens.divider(isDark)),
          child,
        ],
      ),
    );
  }
}
