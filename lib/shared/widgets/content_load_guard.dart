import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_widgets.dart';
import '../../l10n/generated/app_localizations.dart';

/// Keeps dependency failures distinct from genuine empty content.
Widget? buildContentLoadGuard(
  List<AsyncValue<Object?>> dependencies, {
  required VoidCallback onRetry,
}) {
  if (dependencies.any((value) => value.hasError)) {
    return _ContentLoadError(onRetry: onRetry);
  }
  if (dependencies.any((value) => value.isLoading)) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  return null;
}

class _ContentLoadError extends StatelessWidget {
  const _ContentLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      message: AppLocalizations.of(context)!.contentLoadFailed,
      onRetry: onRetry,
    );
  }
}
