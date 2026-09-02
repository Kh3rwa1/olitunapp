import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/profile/presentation/providers/profile_account_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  Future<ProviderContainer> containerFor(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isAuthenticatedProvider.overrideWith((ref) async => false),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('account defaults to Learner, baby emoji and April 2024', () async {
    final container = await containerFor({});

    expect(container.read(userNameProvider), 'Learner');
    expect(container.read(userAvatarEmojiProvider), '👶');
    expect(container.read(userAvatarColorIndexProvider), 0);
    expect(container.read(memberSinceProvider), 'April 2024');
  });

  test('account providers read stored preference values', () async {
    final container = await containerFor({
      'user_name': 'Somi',
      'user_avatar_emoji': '🦊',
      'user_avatar_color': 3,
      'member_since': 'June 2025',
      'badge_traditional_archer_name': 'Custom Archer',
      'badge_traditional_kudum_name': 'Custom Kudum',
      'badge_traditional_kherwal_name': 'Custom Kherwal',
    });

    expect(container.read(userNameProvider), 'Somi');
    expect(container.read(userAvatarEmojiProvider), '🦊');
    expect(container.read(userAvatarColorIndexProvider), 3);
    expect(container.read(memberSinceProvider), 'June 2025');
    expect(container.read(badgeTraditionalArcherNameProvider), 'Custom Archer');
    expect(container.read(badgeTraditionalKudumNameProvider), 'Custom Kudum');
    expect(
      container.read(badgeTraditionalKherwalNameProvider),
      'Custom Kherwal',
    );
  });

  test('badge providers fall back to traditional Santali names', () async {
    final container = await containerFor({});

    expect(
      container.read(badgeTraditionalArcherNameProvider),
      'Santali Archer',
    );
    expect(container.read(badgeTraditionalKudumNameProvider), 'Kudum Master');
    expect(
      container.read(badgeTraditionalKherwalNameProvider),
      'Kherwal Elder',
    );
  });

  test(
    'userAvatarColorsProvider resolves the palette for the stored index',
    () async {
      final container = await containerFor({'user_avatar_color': 2});

      final colors = container.read(userAvatarColorsProvider);
      expect(colors, isNotEmpty);
      expect(colors.length, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('userAvatarColorsProvider is usable inside a widget tree', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'user_avatar_color': 1});
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    Color? resolved;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            resolved = ref.watch(userAvatarColorsProvider).first;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, isNotNull);
  });

  test(
    'accountCreatedAtProvider returns null for guests without network',
    () async {
      final container = await containerFor({});

      final createdAt = await container.read(accountCreatedAtProvider.future);

      expect(createdAt, isNull);
    },
  );
}
