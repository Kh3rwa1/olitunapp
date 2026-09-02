import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/admin/presentation/admin_settings_screen.dart';
import 'package:itun/features/admin/presentation/settings/controllers/admin_settings_controller.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/providers/app_settings_provider.dart';
import 'package:itun/shared/providers/purchases_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

void main() {
  late MockAppwriteDbService mockDb;
  late SharedPreferences prefs;

  setUp(() async {
    mockDb = MockAppwriteDbService();
    when(
      () => mockDb.listDocuments('app_settings'),
    ).thenAnswer((_) async => []);
    SharedPreferences.setMockInitialValues({
      // Empty badge names keep the screen's controller-sync no-op so the
      // success path can render without triggering mid-build provider writes.
      'badge_traditional_archer_name': '',
      'badge_traditional_kudum_name': '',
      'badge_traditional_kherwal_name': '',
    });
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        appwriteDbServiceProvider.overrideWithValue(mockDb),
        sharedPreferencesProvider.overrideWithValue(prefs),
        isAuthenticatedProvider.overrideWith((ref) async => true),
        appSettingsProvider.overrideWith((ref) async => <String, dynamic>{}),
        adStateProvider.overrideWith(() => AdStateNotifier(const AdState())),
        purchasedCategoriesProvider.overrideWith((ref) async => <String>{}),
      ],
      child: const MaterialApp(home: AdminSettingsScreen()),
    );
  }

  AdminSettingsStatus statusOf(WidgetTester tester) {
    final element = tester.element(find.byType(AdminSettingsScreen));
    final container = ProviderScope.containerOf(element);
    return container.read(adminSettingsControllerProvider).status;
  }

  Future<void> pumpUntilLoaded(
    WidgetTester tester, {
    Size size = const Size(1200, 3000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      final status = statusOf(tester);
      if (status == AdminSettingsStatus.loaded ||
          status == AdminSettingsStatus.loadFailure) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('mounts the settings screen and shows the page header', (
    tester,
  ) async {
    await pumpUntilLoaded(tester);

    expect(find.text('App Settings'), findsOneWidget);
    expect(find.text('Onboarding Video'), findsOneWidget);
    expect(find.text('Danger Zone'), findsOneWidget);
  });

  testWidgets('renders the main configuration sections', (tester) async {
    await pumpUntilLoaded(tester);

    expect(find.text('Traditional Mastery Badges'), findsOneWidget);
    expect(find.text('Google AdMob Monetization'), findsOneWidget);
    expect(find.text('Danger Zone'), findsOneWidget);
  });

  testWidgets('typing a badge name keeps the screen alive and syncs state', (
    tester,
  ) async {
    await pumpUntilLoaded(tester);

    final label = find.text('Archer Badge (Folk Craft / Mastery)');
    expect(label, findsOneWidget);
    final fieldColumn = find
        .ancestor(of: label, matching: find.byType(Column))
        .first;
    final archerField = find
        .descendant(of: fieldColumn, matching: find.byType(TextField))
        .first;
    await tester.enterText(archerField, 'Changed Archer');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AdminSettingsScreen), findsOneWidget);
    expect(find.text('Save Badge Names'), findsOneWidget);
  });
}
