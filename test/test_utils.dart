import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

/// Helper to wrap widgets with necessary providers and localizations for testing.
Widget createTestableWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// Turns a fixed [AsyncValue] into an `AsyncNotifier.build` result so test
/// fakes can pin a provider to data, loading or error synchronously.
FutureOr<T> asyncValueBuild<T>(AsyncValue<T> value) => value.when(
  data: (data) => data,
  loading: () => Completer<T>().future,
  error: Future<T>.error,
);
