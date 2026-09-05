import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/startup/startup_tasks.dart';

void main() {
  test('successful optional task reports success', () async {
    final runner = StartupTaskRunner();
    final result = await runner.run('healthy', () async {});
    expect(result.status, StartupTaskStatus.succeeded);
    expect(result.name, 'healthy');
    expect(result.error, isNull);
  });

  test('synchronous failure is isolated from other tasks', () async {
    final runner = StartupTaskRunner();
    final results = await runner.runAll({
      'broken': () => throw StateError('SDK failed'),
      'healthy': () async {},
    });
    expect(results[0].status, StartupTaskStatus.failed);
    expect(results[1].status, StartupTaskStatus.succeeded);
  });

  test('asynchronous failure is reported without escaping', () async {
    final runner = StartupTaskRunner();
    final result = await runner.run('broken', () async {
      throw StateError('SDK failed');
    });
    expect(result.status, StartupTaskStatus.failed);
    expect(result.error, isA<StateError>());
  });

  testWidgets('hung optional task times out while another finishes', (
    tester,
  ) async {
    final runner = StartupTaskRunner();
    final stuck = Completer<void>();
    var healthyRan = false;
    final work = runner.runAll({
      'stuck': () => stuck.future,
      'healthy': () async {
        healthyRan = true;
      },
    }, timeout: const Duration(seconds: 1));
    await tester.pump();
    expect(healthyRan, isTrue);
    await tester.pump(const Duration(seconds: 2));
    final results = await work;
    expect(results[0].status, StartupTaskStatus.timedOut);
    expect(results[1].status, StartupTaskStatus.succeeded);
    stuck.completeError(StateError('late SDK error'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry does not duplicate a timed-out SDK initialization', (
    tester,
  ) async {
    final runner = StartupTaskRunner();
    final stuck = Completer<void>();
    var calls = 0;
    Future<void> initialize() {
      calls++;
      return stuck.future;
    }

    final first = runner.run(
      'sdk',
      initialize,
      timeout: const Duration(seconds: 1),
    );
    await tester.pump(const Duration(seconds: 2));
    expect((await first).status, StartupTaskStatus.timedOut);
    final second = runner.run('sdk', initialize);
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    stuck.complete();
    await tester.pump();
  });

  test('required initialization caches success', () async {
    var calls = 0;
    final required = RequiredStartupTask<int>(() async => ++calls);
    expect(await required.run(), 1);
    expect(await required.run(), 1);
    expect(calls, 1);
  });

  test('required initialization retries a real synchronous failure', () async {
    var calls = 0;
    final required = RequiredStartupTask<int>(() {
      calls++;
      if (calls == 1) throw StateError('storage unavailable');
      return Future.value(42);
    });
    await expectLater(required.run(), throwsStateError);
    expect(await required.run(), 42);
    expect(calls, 2);
  });

  testWidgets('storage timeout retains the in-flight operation for retry', (
    tester,
  ) async {
    var calls = 0;
    final storage = Completer<int>();
    final required = RequiredStartupTask<int>(() {
      calls++;
      return storage.future;
    });
    final first = required.run(timeout: const Duration(seconds: 1));
    final expectation = expectLater(first, throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 2));
    await expectation;
    final retry = required.run(timeout: const Duration(seconds: 1));
    expect(calls, 1);
    storage.complete(42);
    await tester.pump();
    expect(await retry, 42);
  });
}
