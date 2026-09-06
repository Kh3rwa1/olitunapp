import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/startup/post_frame_startup.dart';
import 'package:itun/core/startup/startup_tasks.dart';

void main() {
  testWidgets('usable child renders before optional initialization starts', (
    tester,
  ) async {
    var childBuilt = false;
    var starts = 0;
    await tester.pumpWidget(
      PostFrameStartup(
        onStart: () {
          expect(childBuilt, isTrue);
          starts++;
        },
        child: Builder(
          builder: (context) {
            childBuilt = true;
            return const SizedBox(key: ValueKey('usable-shell'));
          },
        ),
      ),
    );
    expect(find.byKey(const ValueKey('usable-shell')), findsOneWidget);
    expect(starts, 1);
    await tester.pump();
    expect(starts, 1);
  });

  testWidgets('rebuilding the application does not repeat optional startup', (
    tester,
  ) async {
    var starts = 0;
    Widget app() => PostFrameStartup(
      onStart: () => starts++,
      child: const SizedBox(),
    );
    await tester.pumpWidget(app());
    await tester.pumpWidget(app());
    expect(starts, 1);
  });

  testWidgets('hung SDK cannot block the shell and late failure is isolated', (
    tester,
  ) async {
    final stuck = Completer<void>();
    final runner = StartupTaskRunner();
    Future<StartupTaskResult>? work;
    await tester.pumpWidget(
      PostFrameStartup(
        onStart: () {
          work = runner.run(
            'optional-sdk',
            () => stuck.future,
            timeout: const Duration(seconds: 1),
          );
        },
        child: const SizedBox(key: ValueKey('usable-shell')),
      ),
    );
    expect(find.byKey(const ValueKey('usable-shell')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect((await work!).status, StartupTaskStatus.timedOut);
    stuck.completeError(StateError('late SDK failure'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
