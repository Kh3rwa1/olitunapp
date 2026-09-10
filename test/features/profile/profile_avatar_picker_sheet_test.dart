import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';
import 'package:itun/features/profile/presentation/widgets/profile_avatar_picker_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('keeps avatar and color selections across sheet rebuilds', (
    tester,
  ) async {
    final changes = <(String, int)>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileAvatarPickerSheet(
              initialAvatarId: kDefaultAvatarId,
              initialColorIndex: 0,
              avatarsForTesting: const [
                ProfileAvatar(
                  id: kDefaultAvatarId,
                  assetFileName: 'avatar_default.json',
                  label: 'Olitun',
                ),
              ],
              onChanged: (avatarId, colorIndex) async {
                changes.add((avatarId, colorIndex));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('avatar-option-$kInitialAvatarId')),
    );
    await tester.pumpAndSettle();
    expect(changes.last, (kInitialAvatarId, 0));

    await tester.tap(find.byKey(const ValueKey('avatar-color-2')));
    await tester.pumpAndSettle();
    expect(changes.last, (kInitialAvatarId, 2));

    await tester.tap(
      find.byKey(const ValueKey('avatar-option-$kDefaultAvatarId')),
    );
    await tester.pumpAndSettle();
    expect(changes.last, (kDefaultAvatarId, 2));
  });

  testWidgets('rolls back optimistic selection when persistence fails', (
    tester,
  ) async {
    final attempts = <(String, int)>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ProfileAvatarPickerSheet(
              initialAvatarId: kDefaultAvatarId,
              initialColorIndex: 0,
              avatarsForTesting: const [
                ProfileAvatar(
                  id: kDefaultAvatarId,
                  assetFileName: 'avatar_default.json',
                  label: 'Olitun',
                ),
              ],
              onChanged: (avatarId, colorIndex) async {
                attempts.add((avatarId, colorIndex));
                if (avatarId == kInitialAvatarId) {
                  throw StateError('save failed');
                }
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('avatar-option-$kInitialAvatarId')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not save avatar. Please try again.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('avatar-color-2')));
    await tester.pumpAndSettle();
    expect(attempts.last, (kDefaultAvatarId, 2));
  });
}
