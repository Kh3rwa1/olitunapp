import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/presentation/widgets/category_lessons/locked_lesson_overlay.dart';
import 'package:lottie/lottie.dart';

void main() {
  Widget host({String? title, required VoidCallback onStart}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LockedLessonOverlay(
            blockingLessonTitle: title,
            onStartBlockingLesson: onStart,
            isDark: false,
          ),
        ),
      ),
    );
  }

  testWidgets('overlay shows playful copy with the blocking lesson', (
    tester,
  ) async {
    await tester.pumpWidget(host(title: 'Time & Weather', onStart: () {}));
    await tester.pump();

    expect(find.text('HOLD ON • LOCKED FOR NOW'), findsOneWidget);
    expect(find.text('Take me there'), findsOneWidget);
    expect(
      find.text('Complete “Time & Weather” first to crack it open.'),
      findsOneWidget,
    );
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(find.text('Take me there'), findsOneWidget);
    expect(find.text('Back to learning path'), findsOneWidget);
  });

  testWidgets('overlay falls back when no blocking title is known', (
    tester,
  ) async {
    await tester.pumpWidget(host(onStart: () {}));
    await tester.pump();

    expect(
      find.text('Complete “the previous lesson” first to crack it open.'),
      findsOneWidget,
    );
  });

  testWidgets('start button fires the navigation callback', (tester) async {
    var started = 0;
    await tester.pumpWidget(
      host(title: 'Time & Weather', onStart: () => started++),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('locked-overlay-start')));
    await tester.pump();

    expect(started, 1);
  });
}
