import 'package:flutter/material.dart';

import '../../../../../shared/widgets/ai_spark_assistant.dart';

/// Fullscreen interactive AI Spark overlay shown while Santali voice
/// audio is being synthesized.
class VoiceSparkOverlay extends StatelessWidget {
  const VoiceSparkOverlay({
    super.key,
    required this.isLoading,
    required this.dismissed,
    required this.statusText,
    required this.isDark,
    required this.onDismiss,
  });

  final bool isLoading;
  final bool dismissed;
  final String statusText;
  final bool isDark;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final active = isLoading && !dismissed;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !active,
        child: AnimatedOpacity(
          opacity: active ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: active
              ? AiSparkAssistant(
                  key: const ValueKey('voice-fullscreen-spark'),
                  statusText: statusText,
                  subheadText: 'Giving your words a Santali voice… Tap spark ✨',
                  fullscreen: true,
                  light: isDark,
                  onDismiss: onDismiss,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
