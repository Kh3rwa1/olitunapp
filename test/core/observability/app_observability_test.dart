import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/observability/app_observability.dart';
import 'package:itun/core/observability/breadcrumb_tracker.dart';

void main() {
  group('AppObservability & AppProviderObserver Tests', () {
    setUp(AppObservability.tracker.clear);

    test(
      'records navigation and interaction events into breadcrumb ring buffer',
      () {
        AppObservability.recordNavigation('/home', '/quiz');
        AppObservability.recordInteraction('AnswerButton', 'tap');
        AppObservability.recordAudioEvent(
          'playback_start',
          trackId: 'letter_1',
        );

        final recent = AppObservability.tracker.getRecent();
        expect(recent.length, equals(3));
        expect(recent[0].category, equals('navigation'));
        expect(recent[1].category, equals('interaction'));
        expect(recent[2].category, equals('audio'));
      },
    );

    test('generates valid JSON diagnostics payload with redacted metadata', () {
      AppObservability.recordNavigation('/home', '/profile');
      final payloadJson = AppObservability.generateDiagnosticsPayload(
        extraInfo: {'offline_cache': 'ready', 'access_token': 'secret_123'},
      );

      final decoded = jsonDecode(payloadJson) as Map<String, dynamic>;
      expect(decoded['app'], equals('Olitun'));
      expect(decoded['systemInfo']['offline_cache'], equals('ready'));
      expect(decoded['systemInfo']['access_token'], equals('[REDACTED]'));
      expect(decoded['recentBreadcrumbs'], isNotEmpty);
    });

    test('AppProviderObserver intercepts unhandled provider errors', () async {
      final failingProvider = FutureProvider<String>((ref) async {
        throw StateError('Provider test failure');
      });

      final container = ProviderContainer(
        observers: const [AppProviderObserver()],
      );
      addTearDown(container.dispose);

      container.read(failingProvider);
      await pumpEventQueue();

      final recent = AppObservability.tracker.getRecent();
      final hasError = recent.any((b) => b.level == BreadcrumbLevel.error);
      expect(hasError, isTrue);
    });
  });
}
