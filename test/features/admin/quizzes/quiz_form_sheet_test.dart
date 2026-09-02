import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/quizzes/widgets/quiz_form_sheet.dart';
import 'package:itun/features/admin/presentation/quizzes/widgets/quiz_form_sheet/quiz_form_state.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/shared/models/content/quiz_model.dart';
import 'package:itun/shared/providers/quizzes_provider.dart';

class _FakeCategoryNotifier extends CategoryNotifier {
  @override
  AsyncValue<List<CategoryEntity>> build() => const AsyncValue.data([
    CategoryEntity(
      id: 'cat_1',
      titleOlChiki: 'ᱛᱚᱨᱡᱚᱢᱟ',
      titleLatin: 'Greetings',
    ),
  ]);
}

class _NoopQuizzesNotifier extends QuizzesNotifier {
  @override
  AsyncValue<List<QuizModel>> build() => const AsyncValue.data([]);
}

QuizModel _quiz() => QuizModel(
  id: 'quiz_1',
  categoryId: 'cat_1',
  title: 'Animals',
  order: 3,
  passingScore: 80,
);

void main() {
  Future<void> pumpSheet(WidgetTester tester, {QuizModel? quiz}) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryNotifierProvider.overrideWith(_FakeCategoryNotifier.new),
          quizzesProvider.overrideWith(_NoopQuizzesNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: QuizFormSheet(quiz: quiz),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('new quiz sheet shows Create Quiz header and empty section', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.text('Create Quiz'), findsNWidgets(2));
    expect(find.text('Questions (0)'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
  });

  testWidgets('edit quiz sheet pre-fills stored values', (tester) async {
    await pumpSheet(tester, quiz: _quiz());

    expect(find.text('Edit Quiz'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Animals'), findsOneWidget);
  });

  testWidgets('adding a question through the editor increments the count', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Add Question'), findsOneWidget);

    await tester.tap(find.text('Save Question'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Questions (1)'), findsOneWidget);
  });

  testWidgets('QuizFormState dispose releases its controllers', (tester) async {
    final state = QuizFormState(
      formKey: GlobalKey<FormState>(),
      titleCtrl: TextEditingController(text: 't'),
      orderCtrl: TextEditingController(),
      passingScoreCtrl: TextEditingController(),
      questions: const [],
    );
    expect(state.titleCtrl.text, 't');
    expect(state.level, 'beginner');
    expect(state.isActive, isTrue);
    expect(state.dispose, returnsNormally);
  });
}
