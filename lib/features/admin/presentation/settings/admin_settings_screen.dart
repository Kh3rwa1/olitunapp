import 'dart:convert';
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
  bool _globalReviewUnlockEnabled = true;
  List<Map<String, String>> _goalsList = [];

  late final TextEditingController _archerNameController;
  late final TextEditingController _kudumNameController;
  late final TextEditingController _kherwalNameController;
  late final TextEditingController _razorpayKeyController;

  @override
  void initState() {
    super.initState();
    _archerNameController = TextEditingController();
    _kudumNameController = TextEditingController();
    _kherwalNameController = TextEditingController();
    _razorpayKeyController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _archerNameController.dispose();
    _kudumNameController.dispose();
    _kherwalNameController.dispose();
    _razorpayKeyController.dispose();
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

      final goalsJsonStr = settings['onboarding_goals'] as String?;
      List<Map<String, String>> loadedGoals = [];
      if (goalsJsonStr != null && goalsJsonStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(goalsJsonStr);
          loadedGoals = decoded.map((e) {
            final map = e as Map<String, dynamic>;
            return {
              'id': (map['id'] as String? ?? ''),
              'title': (map['title'] as String? ?? ''),
              'icon': (map['icon'] as String? ?? 'translate_rounded'),
            };
          }).toList();
        } catch (_) {}
      }
      if (loadedGoals.isEmpty) {
        loadedGoals = [
          {
            'id': 'read_ol_chiki',
            'title': 'Read Ol Chiki script',
            'icon': 'translate_rounded',
          },
          {
            'id': 'daily_habits',
            'title': 'Build daily habits',
            'icon': 'calendar_today_rounded',
          },
          {
            'id': 'wealth_mindset',
            'title': 'Grow wealth mindset',
            'icon': 'trending_up_rounded',
          },
          {
            'id': 'binti_guru',
            'title': 'Book Binti Guru services',
            'icon': 'event_note_rounded',
          },
          {
            'id': 'business_santali',
            'title': 'Learn business Santali',
            'icon': 'business_center_rounded',
          },
        ];
      }

      setState(() {
        _currentVideoUrl = settings['onboarding_video_url'] as String?;
        _globalReviewUnlockEnabled =
            settings['global_review_unlock_enabled'] != 'false';
        _goalsList = loadedGoals;
        _archerNameController.text = ref.read(
          badgeTraditionalArcherNameProvider,
        );
        _kudumNameController.text = ref.read(badgeTraditionalKudumNameProvider);
        _kherwalNameController.text = ref.read(
          badgeTraditionalKherwalNameProvider,
        );
        _razorpayKeyController.text =
            settings['razorpay_key_id'] as String? ?? '';
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
                      icon: Icons.checklist_rounded,
                      title: 'Onboarding Goals Management',
                      subtitle:
                          'Manage the multi-select learning goals displayed during the onboarding wizard flow.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _goalsList.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 24,
                              color: Colors.white10,
                            ),
                            itemBuilder: (context, index) {
                              final goal = _goalsList[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      key: ValueKey('${goal['id']}_title'),
                                      initialValue: goal['title'],
                                      decoration: InputDecoration(
                                        labelText: 'Goal Title',
                                        labelStyle: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Colors.white24,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      onChanged: (val) {
                                        _goalsList[index]['title'] = val;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: goal['icon'],
                                      dropdownColor: const Color(0xFF1E293B),
                                      decoration: InputDecoration(
                                        labelText: 'Icon',
                                        labelStyle: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Colors.white24,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
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
                                            _goalsList[index]['icon'] = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _goalsList.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Add Goal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    final uniqueId =
                                        'goal_${DateTime.now().millisecondsSinceEpoch}';
                                    _goalsList.add({
                                      'id': uniqueId,
                                      'title': 'New Learning Goal',
                                      'icon': 'translate_rounded',
                                    });
                                  });
                                },
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _goalsList = [
                                      {
                                        'id': 'read_ol_chiki',
                                        'title': 'Read Ol Chiki script',
                                        'icon': 'translate_rounded',
                                      },
                                      {
                                        'id': 'daily_habits',
                                        'title': 'Build daily habits',
                                        'icon': 'calendar_today_rounded',
                                      },
                                      {
                                        'id': 'wealth_mindset',
                                        'title': 'Grow wealth mindset',
                                        'icon': 'trending_up_rounded',
                                      },
                                      {
                                        'id': 'binti_guru',
                                        'title': 'Book Binti Guru services',
                                        'icon': 'event_note_rounded',
                                      },
                                      {
                                        'id': 'business_santali',
                                        'title': 'Learn business Santali',
                                        'icon': 'business_center_rounded',
                                      },
                                    ];
                                  });
                                },
                                child: const Text(
                                  'Reset to Default',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  // Validate title
                                  for (final g in _goalsList) {
                                    if (g['title'] == null ||
                                        g['title']!.trim().isEmpty) {
                                      _showSnackBar(
                                        'Goal titles cannot be empty!',
                                        AppColors.error,
                                      );
                                      return;
                                    }
                                  }
                                  try {
                                    final jsonStr = jsonEncode(_goalsList);
                                    await _saveSetting(
                                      'onboarding_goals',
                                      jsonStr,
                                    );
                                    ref.invalidate(appSettingsProvider);
                                    _showSnackBar(
                                      'Onboarding goals updated successfully! 🎯',
                                      AppColors.success,
                                    );
                                  } catch (e) {
                                    _showSnackBar(
                                      'Failed to save onboarding goals: $e',
                                      AppColors.error,
                                    );
                                  }
                                },
                                child: const Text('Save Goals'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AdminSettingsSectionCard(
                      icon: Icons.monetization_on_rounded,
                      title: 'Monetization Controls',
                      subtitle:
                          'Configure pricing options, payment gateway credentials, and global course unlock methods.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Global Play Store Review Unlock',
                            ),
                            subtitle: const Text(
                              'When enabled, users can unlock eligible premium categories by leaving a Play Store review instead of paying. Note: Each user can only use the review unlock method once across all courses.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _globalReviewUnlockEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) async {
                              setState(() => _globalReviewUnlockEnabled = val);
                              try {
                                await _saveSetting(
                                  'global_review_unlock_enabled',
                                  val.toString(),
                                );
                                ref.invalidate(appSettingsProvider);
                                _showSnackBar(
                                  'Monetization settings updated! 🪙',
                                  AppColors.success,
                                );
                              } catch (e) {
                                _showSnackBar(
                                  'Failed to update monetization settings: $e',
                                  AppColors.error,
                                );
                              }
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: Colors.white10),
                          ),
                          Row(
                            children: [
                              Icon(
                                _razorpayKeyController.text.trim().isNotEmpty
                                    ? Icons.vpn_key_rounded
                                    : Icons.lock_outline_rounded,
                                color:
                                    _razorpayKeyController.text
                                        .trim()
                                        .isNotEmpty
                                    ? AppColors.success
                                    : Colors.orangeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _razorpayKeyController.text.trim().isNotEmpty
                                    ? 'Custom Gateway Key Override Active'
                                    : 'Default Build Gateway Key Active (Fallback)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _razorpayKeyController.text
                                          .trim()
                                          .isNotEmpty
                                      ? AppColors.success
                                      : Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AdminTextField(
                            controller: _razorpayKeyController,
                            label: 'Razorpay Key ID',
                            hint:
                                'rzp_live_xxxxxxxxxxxxxx or rzp_test_xxxxxxxxxxxxxx',
                            prefixIcon: Icons.vpn_key_rounded,
                            helperText:
                                'Override the default build-time Razorpay key with a dynamic database key. If left blank, the app reverts securely to the default bundled credentials.',
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AdminPrimaryButton(
                              label: 'Save Gateway Key',
                              icon: Icons.save_rounded,
                              onTap: () async {
                                final key = _razorpayKeyController.text.trim();
                                try {
                                  await _saveSetting('razorpay_key_id', key);
                                  ref.invalidate(appSettingsProvider);
                                  _showSnackBar(
                                    'Razorpay gateway key updated successfully! 💳',
                                    AppColors.success,
                                  );
                                  setState(
                                    () {},
                                  ); // refresh gateway key active status
                                } catch (e) {
                                  _showSnackBar(
                                    'Failed to save gateway key: $e',
                                    AppColors.error,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
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
