import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../analytics/analytics_service.dart';
import '../config/app_update_config.dart';
import '../logging/app_logger.dart';
import '../theme/app_colors.dart';

/// How the screen opens a store URL (injectable for tests).
typedef StoreLauncher = Future<bool> Function(Uri uri);

Future<bool> _defaultLauncher(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Full-screen stop for builds older than `min_supported_build`. The only
/// action is the Play Store; nothing else in the app is reachable.
class UpdateRequiredScreen extends ConsumerStatefulWidget {
  const UpdateRequiredScreen({super.key, this.launcher});

  final StoreLauncher? launcher;

  /// Reset between tests so `update_required_shown` logs again.
  @visibleForTesting
  static void resetShownLog() => _loggedThisRun = false;

  static bool _loggedThisRun = false;

  @override
  ConsumerState<UpdateRequiredScreen> createState() =>
      _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends ConsumerState<UpdateRequiredScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (UpdateRequiredScreen._loggedThisRun) return;
    UpdateRequiredScreen._loggedThisRun = true;
    try {
      final current = ref.read(currentBuildNumberProvider).valueOrNull;
      final minimum = ref.read(minSupportedBuildProvider);
      ref
          .read(learningAnalyticsServiceProvider)
          .track(
            LearningAnalyticsEvents.updateRequiredShown,
            source: 'update_gate',
            metadata: {
              'current_build': ?current,
              'min_supported_build': ?minimum,
            },
          );
    } catch (e) {
      AppLogger.debug('UpdateRequiredScreen: analytics unavailable: $e');
    }
  }

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() => _opening = true);
    final launch = widget.launcher ?? _defaultLauncher;
    try {
      var opened = false;
      try {
        opened = await launch(AppUpdatePolicy.playMarketUri);
      } catch (e) {
        AppLogger.debug('UpdateRequiredScreen: market:// failed: $e');
      }
      if (!opened) {
        try {
          await launch(AppUpdatePolicy.playWebUri);
        } catch (e) {
          AppLogger.debug('UpdateRequiredScreen: web store failed: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.updateRequiredTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.updateRequiredBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('update_required_store_button'),
                    onPressed: _opening ? null : _openStore,
                    icon: const Icon(Icons.shop_rounded),
                    label: Text(l10n.updateRequiredButton),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.elevatedButtonFg,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
