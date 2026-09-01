import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/languages/providers/target_language_provider.dart';
import '../../../../core/observability/app_observability.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/providers/local_settings_provider.dart';

class DiagnosticsSheet extends ConsumerStatefulWidget {
  const DiagnosticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => const DiagnosticsSheet(),
    );
  }

  @override
  ConsumerState<DiagnosticsSheet> createState() => _DiagnosticsSheetState();
}

class _DiagnosticsSheetState extends ConsumerState<DiagnosticsSheet> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeLanguage = ref.watch(targetLanguageCodeProvider);
    final scriptMode = ref.watch(effectiveScriptModeProvider);
    final themeMode = ref.watch(themeModeProvider);

    final diagnosticInfo = <String, dynamic>{
      'targetLanguage': activeLanguage,
      'scriptMode': scriptMode,
      'themeMode': themeMode,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'breadcrumbCount': AppObservability.tracker.count,
    };

    final payload = AppObservability.generateDiagnosticsPayload(
      extraInfo: diagnosticInfo,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: AppRadius.topXxl,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'System Diagnostics & Health',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Anonymized runtime performance & diagnostic telemetry',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Status Bento Cards
              Row(
                children: [
                  Expanded(
                    child: _StatusCard(
                      label: 'Target Script',
                      value: activeLanguage.toUpperCase(),
                      icon: Icons.translate_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatusCard(
                      label: 'Runtime Mode',
                      value: kDebugMode ? 'DEBUG' : 'RELEASE',
                      icon: Icons.shield_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatusCard(
                      label: 'Telemetry Events',
                      value: '${AppObservability.tracker.count}',
                      icon: Icons.analytics_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Logs Preview Box
              Text(
                'Diagnostic Payload Preview',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: double.infinity,
                height: 140,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    payload,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Copy Logs Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await Clipboard.setData(ClipboardData(text: payload));
                    setState(() => _copied = true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Diagnostic payload copied to clipboard!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _copied
                        ? 'Copied to Clipboard'
                        : 'Copy Anonymized Diagnostics',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderLg,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 9,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
