// Guest Flow Smoke Test - Optimized for AAA+ Premium Splash Screen and Test Isolation
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/main.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/main/presentation/main_shell/main_shell_screen.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/shared/widgets/state_widgets.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Animate.restartOnHotReload = false;
    Hive.init('test_hive_smoke');
    CacheService.resetForTesting();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Explorer',
      'user_avatar_emoji': '👶',
      'user_avatar_color': 0,
      'show_onboarding': false, // Bypass onboarding screen
    });
  });

  testWidgets(
    'Guest mode / Skip Login flow renders successfully without throwing',
    (tester) async {
      final mockAuthRepo = MockAuthRepository();
      when(mockAuthRepo.isLoggedIn).thenAnswer((_) async => const Right(false));
      when(
        mockAuthRepo.getCurrentUser,
      ).thenAnswer((_) async => const Right(null));

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            // Enforce Guest Mode (user is not logged in)
            isAuthenticatedProvider.overrideWith((ref) async => false),
            currentUserProvider.overrideWith((ref) async => null),

            // Override stats provider with empty guest stats
            userStatsProvider.overrideWith(UserStatsNotifier.new),

            // Mock connectivity to prevent continuous network listening triggers
            appConnectivityProvider.overrideWith(
              (ref) => Stream.value([ConnectivityResult.none]),
            ),

            // Override gamification to prevent pending timers from Appwrite calls
            gamificationContentProvider.overrideWith(
              (ref) async => GamificationContent.fallback(),
            ),
            userGamificationSummaryProvider.overrideWith(
              (ref) async => UserGamificationSummary.empty,
            ),
          ],
          child: const OlitunApp(),
        ),
      );

      // Pump through the router redirects and let the home screen boot
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      // Check if we can find the MainShellScreen or any error
      expect(find.byType(MainShellScreen), findsOneWidget);
      expect(find.textContaining('Johar'), findsOneWidget);
    },
  );
}
