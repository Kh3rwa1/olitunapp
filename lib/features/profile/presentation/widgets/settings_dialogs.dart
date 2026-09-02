import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import 'settings_widgets.dart';

void showThemeDialog(BuildContext context, WidgetRef ref, String current) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.chooseTheme,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ThemeOption(
            label: AppLocalizations.of(context)!.systemDefault,
            value: 'system',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          ThemeOption(
            label: AppLocalizations.of(context)!.light,
            value: 'light',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          ThemeOption(
            label: AppLocalizations.of(context)!.dark,
            value: 'dark',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

void showScriptDialog(BuildContext context, WidgetRef ref, String current) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.scriptDisplay,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ScriptOption(
            label: AppLocalizations.of(context)!.bothScripts,
            value: 'both',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          ScriptOption(
            label: AppLocalizations.of(context)!.olChikiOnly,
            value: 'olchiki',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          ScriptOption(
            label: AppLocalizations.of(context)!.latinOnly,
            value: 'latin',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

void showLanguageDialog(
  BuildContext context,
  WidgetRef ref,
  String current,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.chooseLanguage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          LanguageOption(
            label: AppLocalizations.of(context)!.english,
            value: 'en',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          LanguageOption(
            label: AppLocalizations.of(context)!.hindi,
            value: 'hi',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          LanguageOption(
            label: AppLocalizations.of(context)!.bengali,
            value: 'bn',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          LanguageOption(
            label: AppLocalizations.of(context)!.odia,
            value: 'or',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          LanguageOption(
            label: AppLocalizations.of(context)!.santali,
            value: 'sat',
            current: current,
            ref: ref,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

void showResetDialog(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_rounded, color: AppColors.error),
          ),
          const SizedBox(width: 14),
          Text(AppLocalizations.of(context)!.resetProgress),
        ],
      ),
      content: Text(AppLocalizations.of(context)!.resetProgressWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
            // Reset progress by clearing the stored data
            ref.read(userStatsProvider.notifier).resetProgress();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context)!.reset),
        ),
      ],
    ),
  );
}

void showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delete_forever_rounded,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(l10n.deleteAccount)),
        ],
      ),
      content: Text(l10n.deleteAccountWarning),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            HapticFeedback.mediumImpact();
            try {
              // Show loading
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final authRepo = ref.read(authRepositoryProvider);
              final result = await authRepo.deleteAccount();

              result.fold(
                (failure) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete account: ${failure.message}',
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                (_) async {
                  // Clear all local data
                  await ref.read(sharedPreferencesProvider).clear();
                  ref.invalidate(isAuthenticatedProvider);
                  ref.invalidate(userStatsProvider);
                  ref.invalidate(userNameProvider);
                  ref.invalidate(userAvatarEmojiProvider);
                  ref.invalidate(userAvatarColorIndexProvider);
                  ref.invalidate(memberSinceProvider);

                  // Navigate to welcome screen
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    context.go('/welcome');
                  }
                },
              );
            } catch (e) {
              // Handle error
              if (context.mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete account: ${e.toString()}',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.deletePermanently),
        ),
      ],
    ),
  );
}
