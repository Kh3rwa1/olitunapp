import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/app_update_config.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/admin_form_widgets.dart';
import '../controllers/admin_settings_controller.dart';

/// Minimum supported build and latest build (Android versionCodes). Builds
/// below the minimum show only the update screen; builds below the latest
/// see a dismissible update hint on Home.
class AdminBuildGateSection extends ConsumerStatefulWidget {
  const AdminBuildGateSection({super.key});

  @override
  ConsumerState<AdminBuildGateSection> createState() =>
      _AdminBuildGateSectionState();
}

class _AdminBuildGateSectionState extends ConsumerState<AdminBuildGateSection> {
  late final TextEditingController _minController;
  late final TextEditingController _latestController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(adminSettingsControllerProvider);
    _minController = TextEditingController(
      text: state.minSupportedBuild?.toString() ?? '',
    );
    _latestController = TextEditingController(
      text: state.latestBuild?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _latestController.dispose();
    super.dispose();
  }

  String? _validate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (AppUpdatePolicy.parseBuild(text) == null) {
      return 'Build numbers must be positive integers (YYMMDDHH).';
    }
    return null;
  }

  Future<void> _save() async {
    final minText = _minController.text.trim();
    final latestText = _latestController.text.trim();
    final error = _validate(minText) ?? _validate(latestText);
    if (error != null) {
      _showSnackBar(error, AppColors.error);
      return;
    }
    final minBuild = AppUpdatePolicy.parseBuild(minText);
    final latestBuild = AppUpdatePolicy.parseBuild(latestText);
    if (minBuild != null && latestBuild != null && minBuild > latestBuild) {
      _showSnackBar(
        'Minimum supported build cannot be above the latest build.',
        AppColors.error,
      );
      return;
    }
    final controller = ref.read(adminSettingsControllerProvider.notifier);
    final results = await Future.wait([
      controller.saveSetting(AppUpdatePolicy.minSupportedBuildKey, minText),
      controller.saveSetting(AppUpdatePolicy.latestBuildKey, latestText),
    ]);
    if (!mounted) return;
    if (results.every((ok) => ok)) {
      _showSnackBar(
        minBuild == null
            ? 'Build gate cleared: every build can sign in.'
            : 'Build gate saved: builds below $minBuild must update.',
        AppColors.success,
      );
    } else {
      _showSnackBar('Could not save the build gate.', AppColors.error);
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
    final saving =
        state.isSaving(AppUpdatePolicy.minSupportedBuildKey) ||
        state.isSaving(AppUpdatePolicy.latestBuildKey);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.minSupportedBuild == null
                ? 'No minimum set: every installed build can sign in.'
                : 'Builds below ${state.minSupportedBuild} only see the update screen.',
            style: AdminTokens.bodyStrong(isDark),
          ),
          const SizedBox(height: 16),
          AdminTextField(
            controller: _minController,
            label: 'Minimum supported build (versionCode)',
            hint: 'e.g. 26110205',
            helperText:
                'Set this to the first build that works with the current backend. Leave empty to lift the gate.',
            prefixIcon: Icons.lock_clock_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          AdminTextField(
            controller: _latestController,
            label: 'Latest published build (versionCode)',
            hint: 'e.g. 26111010',
            helperText:
                'Older builds show a dismissible "update available" hint on Home.',
            prefixIcon: Icons.new_releases_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: AdminPrimaryButton(
              label: saving ? 'Saving…' : 'Save build gate',
              icon: Icons.save_rounded,
              onTap: saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
