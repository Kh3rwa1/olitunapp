import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/data/gamification_cms_api.dart';
import 'package:itun/features/admin/presentation/gamification/admin_gamification_screen.dart';
import 'package:mocktail/mocktail.dart';

class _Cms extends Mock implements GamificationCmsApi {}

void main() {
  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  late _Cms cms;

  setUp(() {
    cms = _Cms();
    when(() => cms.listRows('badges')).thenAnswer(
      (_) async => [
        {
          'id': 'karam_listener',
          'badgeId': 'karam_listener',
          'name': 'Karam Listener',
          'description': 'Listen to the Karam bakhed.',
          'status': 'draft',
          'isActive': false,
        },
      ],
    );
    when(
      () => cms.upsertRow(
        any(),
        any(),
        any(),
        createOnly: any(named: 'createOnly'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [gamificationCmsApiProvider.overrideWithValue(cms)],
        child: const MaterialApp(
          home: Scaffold(body: AdminGamificationScreen(section: 'badges')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists badges from the Worker CMS', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Karam Listener'), findsOneWidget);
    verify(() => cms.listRows('badges')).called(1);

    // Typing in search filters locally without refetching.
    await tester.enterText(find.byType(TextField).first, 'karam');
    await tester.pumpAndSettle();
    verifyNever(() => cms.listRows('badges'));
  });

  testWidgets('Publish upserts status and isActive on the Worker', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    verify(
      () => cms.upsertRow('badges', 'karam_listener', {
        'status': 'published',
        'isActive': true,
      }),
    ).called(1);
  });

  testWidgets('Create sends a createOnly draft row', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
    await tester.pumpAndSettle();

    final captured = verify(
      () =>
          cms.upsertRow('badges', captureAny(), captureAny(), createOnly: true),
    ).captured;
    expect(captured[0] as String, startsWith('badges_'));
    final draft = captured[1] as Map<String, dynamic>;
    expect(draft['badgeId'], captured[0]);
    expect(draft['status'], 'draft');
  });

  testWidgets('a rejected write shows the Worker error', (tester) async {
    when(
      () => cms.upsertRow(
        any(),
        any(),
        any(),
        createOnly: any(named: 'createOnly'),
      ),
    ).thenThrow(const CmsApiException('Invalid row (400).', statusCode: 400));
    await pumpScreen(tester);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Invalid row'), findsOneWidget);
  });
}
