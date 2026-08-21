import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/admin/presentation/shell/widgets/admin_sidebar.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCategoryNotifier
    extends StateNotifier<AsyncValue<List<CategoryEntity>>>
    with Mock
    implements CategoryNotifier {
  MockCategoryNotifier() : super(const AsyncValue.data([]));
}

void main() {
  late SharedPreferences prefs;
  late MockCategoryNotifier mockCategoryNotifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockCategoryNotifier = MockCategoryNotifier();
  });

  Widget buildTestWidget({bool isCompact = false}) {
    final router = GoRouter(
      initialLocation: '/admin',
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) =>
              Scaffold(body: AdminSidebar(isCompact: isCompact)),
        ),
        GoRoute(
          path: '/admin/purchases',
          builder: (context, state) => const Scaffold(body: Text('Purchases')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        categoryNotifierProvider.overrideWith((ref) => mockCategoryNotifier),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AdminSidebar', () {
    testWidgets('renders all major collapsible groups and expands/collapses', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('OVERVIEW'), findsOneWidget);
      expect(find.text('CONTENT'), findsOneWidget);
      expect(find.text('MONETIZATION'), findsOneWidget);
      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(find.text('Purchases & Revenue'), findsOneWidget);

      // Tap to collapse MONETIZATION group
      await tester.tap(find.text('MONETIZATION'));
      await tester.pumpAndSettle();

      // Tap to expand MONETIZATION group
      await tester.tap(find.text('MONETIZATION'));
      await tester.pumpAndSettle();

      expect(find.text('Purchases & Revenue'), findsOneWidget);
    });

    testWidgets('renders compact mode with tooltips without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(isCompact: true));
      await tester.pumpAndSettle();

      expect(find.byType(AdminSidebar), findsOneWidget);
    });
  });
}
