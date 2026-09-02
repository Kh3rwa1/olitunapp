import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/lessons/presentation/widgets/blocks/quiz_block_cta_widget.dart';
import 'package:itun/shared/models/content/quiz_model.dart';

Widget _glassCard({
  required Color themeColor,
  required bool isDark,
  required double radius,
  required double padding,
  required Widget child,
}) => Container(
  padding: EdgeInsets.all(padding),
  decoration: BoxDecoration(
    color: themeColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(radius),
  ),
  child: child,
);

Widget _tactileButton({
  required Color color,
  required VoidCallback onPressed,
  required Widget child,
}) => ElevatedButton(onPressed: onPressed, child: child);

Future<void> pumpCta(
  WidgetTester tester, {
  required ValueChanged<String> onAction,
  QuizModel? quiz,
}) async {
  final router = GoRouter(
    initialLocation: '/lesson/lesson_1',
    routes: [
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (context, state) => Scaffold(
          body: QuizBlockCTAWidget(
            quizId: 'quiz_42',
            quiz: quiz ?? QuizModel(id: 'quiz_42', title: 'Letter Quiz'),
            accentColor: const Color(0xFF22C55E),
            isDark: false,
            maxHeight: 480,
            index: 3,
            onDismiss: () => onAction('dismiss'),
            buildGlassCard: _glassCard,
            buildTactileButton: _tactileButton,
          ),
        ),
      ),
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) =>
            Text('quiz:${state.pathParameters['quizId']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(child: MaterialApp.router(routerConfig: router)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the trophy, copy and action buttons', (tester) async {
    await pumpCta(tester, onAction: (_) {});

    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    expect(find.text('Ready to test yourself?'), findsOneWidget);
    expect(
      find.text('Great job! Take "Letter Quiz" now to test your knowledge.'),
      findsOneWidget,
    );
    expect(find.text('TAKE THE QUIZ'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('uses a generic phrase when the quiz has no title', (
    tester,
  ) async {
    await pumpCta(
      tester,
      onAction: (_) {},
      quiz: QuizModel(id: 'quiz_42'),
    );

    expect(
      find.text('Great job! Take "the quiz" now to test your knowledge.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the CTA pushes the quiz route', (tester) async {
    await pumpCta(tester, onAction: (_) {});

    await tester.tap(find.text('TAKE THE QUIZ'));
    await tester.pumpAndSettle();

    expect(find.text('quiz:quiz_42'), findsOneWidget);
  });

  testWidgets('skip button triggers the dismiss callback', (tester) async {
    final actions = <String>[];
    await pumpCta(tester, onAction: actions.add);

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(actions, ['dismiss']);
  });
}
