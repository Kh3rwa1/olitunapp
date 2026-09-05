import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_complete_trophy.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_empty_view.dart';
import 'package:itun/l10n/generated/app_localizations.dart';

/// True when [finder]'s widget sits under an [ExcludeSemantics] ancestor,
/// i.e. it stays visible but silent for screen readers.
bool _isExcluded(WidgetTester tester, Finder finder) {
  var excluded = false;
  tester.element(finder).visitAncestorElements((element) {
    if (element.widget is ExcludeSemantics) {
      excluded = true;
      return false;
    }
    return true;
  });
  return excluded;
}

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty-view state icon is silent; heading announces', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const QuizEmptyView()));
    await tester.pumpAndSettle();

    expect(find.text('No questions yet'), findsOneWidget);
    expect(_isExcluded(tester, find.byIcon(Icons.quiz_outlined)), isTrue);
  });

  testWidgets('not-found icon is silent; heading announces', (tester) async {
    await tester.pumpWidget(_host(const QuizEmptyView(isNotFound: true)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(
      _isExcluded(tester, find.byIcon(Icons.error_outline_rounded)),
      isTrue,
    );
  });

  testWidgets('trophy icons are silent in passing and failing states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            QuizCompleteTrophy(isPassing: true, reduceEffects: true),
            QuizCompleteTrophy(isPassing: false, reduceEffects: true),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _isExcluded(tester, find.byIcon(Icons.emoji_events_rounded)),
      isTrue,
    );
    expect(_isExcluded(tester, find.byIcon(Icons.refresh_rounded)), isTrue);
  });
}
