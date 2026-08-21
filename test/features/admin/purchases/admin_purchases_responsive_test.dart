import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/admin/presentation/purchases/admin_purchases_screen.dart';
import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

class MockPurchaseRepository extends Mock implements PurchaseRepository {}

void main() {
  late MockAppwriteDbService mockDb;
  late MockPurchaseRepository mockRepo;

  setUp(() {
    mockDb = MockAppwriteDbService();
    mockRepo = MockPurchaseRepository();
  });

  const testUser = UserEntity(
    id: 'admin_usr_1',
    email: 'admin@olitun.com',
    name: 'Admin',
    isEmailVerified: true,
  );

  final sampleDocs = [
    {
      '\$id': 'p1',
      'userId': 'user_abc123',
      'categoryId': 'santali_basics',
      'unlockMethod': 'razorpay',
      'amountPaidInr': 299,
      'status': 'verified',
      'razorpayPaymentId': 'pay_123',
      'purchasedAt': '2026-08-21T10:00:00Z',
    },
    {
      '\$id': 'p2',
      'userId': 'user_def456',
      'categoryId': 'santali_advanced',
      'unlockMethod': 'play_store_review',
      'amountPaidInr': 0,
      'status': 'verified',
      'purchasedAt': '2026-08-21T11:00:00Z',
    },
  ];

  Widget buildTestScreen({
    required double width,
    double textScale = 1.0,
    bool isDark = false,
  }) {
    return ProviderScope(
      overrides: [
        appwriteDbServiceProvider.overrideWithValue(mockDb),
        purchaseRepositoryProvider.overrideWithValue(mockRepo),
        isAuthenticatedProvider.overrideWith((ref) async => true),
        currentUserProvider.overrideWith((ref) async => testUser),
      ],
      child: MaterialApp(
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(body: AdminPurchasesScreen()),
        ),
      ),
    );
  }

  group('AdminPurchasesScreen - Responsive & Viewport Tests (320px - 1920px)', () {
    final viewports = [
      320.0,
      360.0,
      390.0,
      600.0,
      768.0,
      1024.0,
      1280.0,
      1440.0,
      1920.0,
    ];

    for (final width in viewports) {
      testWidgets(
        'renders cleanly without overflow at ${width.toInt()}px width (textScale: 1.0)',
        (tester) async {
          when(
            () => mockDb.listDocuments(
              'course_purchases',
              queries: any(named: 'queries'),
            ),
          ).thenAnswer((_) async => sampleDocs);

          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(buildTestScreen(width: width));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull); // Zero RenderFlex overflow!
          expect(find.text('Purchases & Revenue'), findsOneWidget);
          expect(find.text('Search Category...'), findsOneWidget);
        },
      );

      testWidgets(
        'renders cleanly without overflow at ${width.toInt()}px width (textScale: 1.5)',
        (tester) async {
          when(
            () => mockDb.listDocuments(
              'course_purchases',
              queries: any(named: 'queries'),
            ),
          ).thenAnswer((_) async => sampleDocs);

          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildTestScreen(width: width, textScale: 1.5),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('critical controls scale cleanly at 320px with textScale 2.0', (
      tester,
    ) async {
      when(
        () => mockDb.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer((_) async => sampleDocs);

      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen(width: 320, textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Search Category...'), findsOneWidget);
    });
  });
}
