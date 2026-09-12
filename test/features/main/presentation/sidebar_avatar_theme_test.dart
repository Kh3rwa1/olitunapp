import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/main/presentation/main_shell/widgets/sidebar_avatar_icon.dart';
import 'package:itun/features/main/presentation/main_shell/widgets/theme_toggle_switch.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _toggleHarness({required bool isDark}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => AnimatedThemeToggle(
            isDark: isDark,
            targetLabel: isDark ? 'Light' : 'Dark',
            onToggle: (toDark) =>
                updateThemeMode(ref, toDark ? 'dark' : 'light'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
  });

  testWidgets('toggle renders the animation and flips light to dark', (
    tester,
  ) async {
    await tester.pumpWidget(await _toggleHarness(isDark: false));
    await tester.pump();

    expect(find.byType(LottieBuilder), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('animated-theme-toggle')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AnimatedThemeToggle)),
    );
    expect(container.read(themeModeProvider), 'dark');
    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggle starting dark flips back to light', (tester) async {
    await tester.pumpWidget(await _toggleHarness(isDark: true));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('animated-theme-toggle')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AnimatedThemeToggle)),
    );
    expect(container.read(themeModeProvider), 'light');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar shows the stored animated avatar', (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_avatar_id': 'owl',
      'user_name': 'Dular',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: Scaffold(body: SidebarAvatarIcon())),
      ),
    );
    await tester.pump();

    expect(find.byType(LottieBuilder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar falls back to the name initial', (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_avatar_id': kInitialAvatarId,
      'user_name': 'Dular',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: Scaffold(body: SidebarAvatarIcon())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('D'), findsOneWidget);
    expect(find.byType(LottieBuilder), findsNothing);
  });
}
