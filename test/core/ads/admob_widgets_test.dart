import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/widgets/banner_ad_widget.dart';
import 'package:itun/core/ads/widgets/native_ad_widget.dart';
import 'package:itun/core/storage/hive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('AdMob Widgets Headless Tests', () {
    testWidgets('BannerAdWidget renders empty box when Ad-Free', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            adStateProvider.overrideWith(
              () => AdStateNotifier(const AdState(isAdFreeUser: true)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BannerAdWidget(placement: 'test_placement')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BannerAdWidget), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('NativeAdWidget renders empty box when Ad-Free', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            adStateProvider.overrideWith(
              () => AdStateNotifier(const AdState(isAdFreeUser: true)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: NativeAdWidget(placement: 'test_placement')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NativeAdWidget), findsOneWidget);
    });
  });
}
