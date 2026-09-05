import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_empty_view.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

Widget _host({required bool isNotFound}) {
  final router = GoRouter(
    initialLocation: '/quiz/missing',
    routes: [
      GoRoute(
        path: '/quiz/missing',
        builder: (context, state) => QuizEmptyView(isNotFound: isNotFound),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Center(child: Text('Home Screen')),
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  testWidgets('empty quiz state explains there are no questions yet', (
    tester,
  ) async {
    await tester.pumpWidget(_host(isNotFound: false));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
    expect(find.text('No questions yet'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets('not-found state distinguishes a missing quiz', (tester) async {
    await tester.pumpWidget(_host(isNotFound: true));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Something went wrong!'), findsOneWidget);
    expect(find.text('No questions yet'), findsNothing);
  });

  testWidgets('go back button routes home', (tester) async {
    await tester.pumpWidget(_host(isNotFound: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go Back'));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
  });
}
