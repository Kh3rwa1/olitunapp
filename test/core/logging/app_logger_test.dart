import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class _FakeHub extends Fake implements Hub {
  _FakeHub({this.enabled = true});

  final bool enabled;
  final breadcrumbs = <Breadcrumb>[];
  final exceptions = <({Object error, Object? stackTrace, String? message})>[];
  final messages = <({String? message, SentryLevel? level})>[];

  @override
  bool get isEnabled => enabled;

  @override
  Future<void> addBreadcrumb(Breadcrumb crumb, {Hint? hint}) async {
    breadcrumbs.add(crumb);
  }

  @override
  Future<SentryId> captureException(
    dynamic throwable, {
    dynamic stackTrace,
    Hint? hint,
    SentryMessage? message,
    ScopeCallback? withScope,
  }) async {
    exceptions.add((
      error: throwable as Object,
      stackTrace: stackTrace,
      message: message?.formatted,
    ));
    return const SentryId.empty();
  }

  @override
  Future<SentryId> captureMessage(
    String? message, {
    SentryLevel? level,
    String? template,
    List<dynamic>? params,
    Hint? hint,
    ScopeCallback? withScope,
  }) async {
    messages.add((message: message, level: level));
    return const SentryId.empty();
  }
}

void main() {
  group('AppLogger', () {
    test('keeps simple debug output human-readable', () {
      expect(AppLogger.formatForTesting('loaded'), 'loaded');
      expect(
        AppLogger.formatForTesting('loaded', name: 'Cache'),
        '[Cache] loaded',
      );
    });

    test('emits structured JSON when fields are supplied', () {
      final encoded = AppLogger.formatForTesting(
        'load failed',
        name: 'Cache',
        fields: {'key': 'lessons', 'attempt': 2},
      );

      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      expect(decoded['level'], 'debug');
      expect(decoded['message'], '[Cache] load failed');
      expect(decoded['fields'], {'key': 'lessons', 'attempt': 2});
    });
  });

  group('AppLogger Sentry forwarding', () {
    late _FakeHub hub;

    setUp(() => AppLogger.hubForTesting = hub = _FakeHub());
    tearDown(() => AppLogger.hubForTesting = null);

    test('debug never reaches Sentry', () {
      AppLogger.debug('cache miss', name: 'Cache');
      expect(hub.breadcrumbs, isEmpty);
      expect(hub.exceptions, isEmpty);
      expect(hub.messages, isEmpty);
    });

    test('warning records a redacted breadcrumb', () {
      AppLogger.warning(
        'sync failed for jane.doe@example.com',
        name: 'Sync',
        fields: {'attempt': 2, 'token': 'Bearer abc.def.ghi'},
        error: const FormatException('bad payload password=hunter2'),
      );

      expect(hub.exceptions, isEmpty);
      expect(hub.breadcrumbs, hasLength(1));
      final crumb = hub.breadcrumbs.single;
      expect(crumb.level, SentryLevel.warning);
      expect(crumb.category, 'app.log.Sync');
      expect(
        crumb.message,
        contains('[Sync] sync failed for j***@example.com'),
      );
      expect(crumb.message, isNot(contains('jane.doe')));
      expect(crumb.data?['attempt'], 2);
      expect(crumb.data?['token'], 'Bearer [REDACTED_TOKEN]');
      expect(crumb.data?['errorType'], 'FormatException');
      expect(crumb.data?['error'], isNot(contains('hunter2')));
    });

    test('error captures the exception with its stack trace', () {
      final stack = StackTrace.current;
      final failure = StateError('boom');

      AppLogger.error(
        'upload failed for ann@b.co',
        name: 'Upload',
        error: failure,
        stackTrace: stack,
      );

      expect(hub.breadcrumbs, isEmpty);
      expect(hub.exceptions, hasLength(1));
      final captured = hub.exceptions.single;
      expect(captured.error, same(failure));
      expect(captured.stackTrace, same(stack));
      expect(captured.message, '[Upload] upload failed for a***@b.co');
    });

    test('error without an exception captures an error-level message', () {
      AppLogger.error('invariant violated', name: 'Outbox');

      expect(hub.exceptions, isEmpty);
      expect(hub.messages, hasLength(1));
      expect(hub.messages.single.message, '[Outbox] invariant violated');
      expect(hub.messages.single.level, SentryLevel.error);
    });

    test('nothing is forwarded while Sentry is not initialized', () {
      AppLogger.hubForTesting = hub = _FakeHub(enabled: false);

      AppLogger.warning('w', error: Exception('x'));
      AppLogger.error('e', error: Exception('y'), stackTrace: StackTrace.empty);

      expect(hub.breadcrumbs, isEmpty);
      expect(hub.exceptions, isEmpty);
      expect(hub.messages, isEmpty);
    });

    test('a throwing hub never breaks the caller', () {
      AppLogger.hubForTesting = _ThrowingHub();
      expect(
        () => AppLogger.error('e', error: Exception('x')),
        returnsNormally,
      );
      expect(() => AppLogger.warning('w'), returnsNormally);
    });
  });
}

class _ThrowingHub extends Fake implements Hub {
  @override
  bool get isEnabled => true;

  @override
  Future<void> addBreadcrumb(Breadcrumb crumb, {Hint? hint}) =>
      throw StateError('hub down');

  @override
  Future<SentryId> captureException(
    dynamic throwable, {
    dynamic stackTrace,
    Hint? hint,
    SentryMessage? message,
    ScopeCallback? withScope,
  }) => throw StateError('hub down');
}
