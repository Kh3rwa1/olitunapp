import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_update_config.dart';
import '../logging/app_logger.dart';
import 'update_required_screen.dart';

/// Replaces the whole app with [UpdateRequiredScreen] while the running
/// build is below `min_supported_build`. Any failure to evaluate the policy
/// shows the app: the gate must never be the thing that breaks it.
class UpdateGate extends ConsumerWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) return child;
    var required = false;
    try {
      required = ref.watch(updateRequiredProvider);
    } catch (e) {
      AppLogger.debug('UpdateGate: policy unavailable, showing app: $e');
    }
    if (!required) return child;
    return const UpdateRequiredScreen();
  }
}
