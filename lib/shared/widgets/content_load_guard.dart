import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_widgets.dart';

/// Keeps dependency failures distinct from genuine empty content.
Widget? buildContentLoadGuard(
  List<AsyncValue<Object?>> dependencies, {
  required VoidCallback onRetry,
}) {
  if (dependencies.any((value) => value.hasError)) {
    return AppErrorState(
      message: 'Content could not be loaded. Please try again.',
      onRetry: onRetry,
    );
  }
  if (dependencies.any((value) => value.isLoading)) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  return null;
}
