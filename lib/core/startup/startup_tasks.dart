import 'dart:async';

enum StartupTaskStatus { succeeded, failed, timedOut }

class StartupTaskResult {
  const StartupTaskResult(this.name, this.status, this.elapsed, [this.error]);

  final String name;
  final StartupTaskStatus status;
  final Duration elapsed;
  final Object? error;
}

/// Optional SDK tasks run independently and never prevent application startup.
/// A timeout stops waiting, not the underlying SDK. Retaining each result means
/// startup retries cannot launch a second copy of a still-running SDK task.
class StartupTaskRunner {
  final Map<String, Future<StartupTaskResult>> _tasks = {};

  Future<StartupTaskResult> run(
    String name,
    Future<void> Function() action, {
    Duration timeout = const Duration(seconds: 8),
  }) {
    return _tasks.putIfAbsent(name, () => _execute(name, action, timeout));
  }

  Future<List<StartupTaskResult>> runAll(
    Map<String, Future<void> Function()> tasks, {
    Duration timeout = const Duration(seconds: 8),
  }) {
    return Future.wait(
      tasks.entries.map(
        (entry) => run(entry.key, entry.value, timeout: timeout),
      ),
    );
  }

  Future<StartupTaskResult> _execute(
    String name,
    Future<void> Function() action,
    Duration timeout,
  ) async {
    final watch = Stopwatch()..start();
    try {
      await Future<void>.sync(action).timeout(timeout);
      return StartupTaskResult(
        name,
        StartupTaskStatus.succeeded,
        watch.elapsed,
      );
    } on TimeoutException catch (error) {
      return StartupTaskResult(
        name,
        StartupTaskStatus.timedOut,
        watch.elapsed,
        error,
      );
    } catch (error) {
      return StartupTaskResult(
        name,
        StartupTaskStatus.failed,
        watch.elapsed,
        error,
      );
    } finally {
      watch.stop();
    }
  }
}

/// Cache a required initialization without duplicating it after a timeout.
/// Actual failures clear the attempt for retry; successes remain cached.
class RequiredStartupTask<T> {
  RequiredStartupTask(this.action);

  final Future<T> Function() action;
  Future<T>? _pending;

  Future<T> run({Duration timeout = const Duration(seconds: 15)}) {
    final pending = _pending ??= _start();
    return pending.timeout(timeout);
  }

  Future<T> _start() {
    return Future<T>.sync(action).onError<Object>((error, stack) {
      _pending = null;
      Error.throwWithStackTrace(error, stack);
    });
  }
}
