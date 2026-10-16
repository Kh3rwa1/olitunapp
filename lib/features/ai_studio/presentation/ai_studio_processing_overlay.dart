import 'package:flutter/material.dart';

import '../../../core/ads/widgets/native_ad_widget.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/ai_spark_assistant.dart';
import '../data/ai_studio_service.dart';
import 'ai_studio_session.dart';

/// Fullscreen spark shown while a studio job runs. When [showAd] is set, a
/// native ad sits at the bottom: seen while the learner waits, it never
/// delays the result.
class StudioProcessingOverlay extends StatelessWidget {
  const StudioProcessingOverlay({
    super.key,
    required this.visible,
    required this.showAd,
    required this.tool,
    required this.job,
    required this.isDark,
    required this.onDismiss,
  });

  final bool visible;
  final bool showAd;
  final StudioTool tool;
  final StudioJob? job;
  final bool isDark;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        child: visible
            ? Stack(
                children: [
                  Positioned.fill(
                    child: AiSparkAssistant(
                      key: ValueKey('studio-fullscreen-spark-$tool'),
                      statusText: studioSparkStatus(tool, l10n),
                      subheadText: studioSparkSubhead(tool, job),
                      fullscreen: true,
                      light: isDark,
                      onDismiss: onDismiss,
                    ),
                  ),
                  if (showAd)
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: NativeAdWidget(
                            placement: 'ai_studio_processing',
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
