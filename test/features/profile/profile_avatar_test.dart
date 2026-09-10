import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';

void main() {
  test('avatar catalog is unique and contains only committed assets', () {
    final ids = kProfileAvatars.map((avatar) => avatar.id).toList();
    final paths = kProfileAvatars.map((avatar) => avatar.assetPath).toList();
    expect(ids.toSet().length, ids.length);
    expect(paths.toSet().length, paths.length);
    expect(kProfileAvatars.length, greaterThan(1));

    for (final avatar in kProfileAvatars) {
      expect(avatar.assetPath, '$avatarsAssetDir/${avatar.assetFileName}');
      expect(avatarAssetPath(avatar.id), avatar.assetPath);
      expect(File(avatar.assetPath).existsSync(), isTrue);
    }
  });

  test('normalization preserves initial and valid animation choices', () {
    expect(normalizeAvatarId(null), kDefaultAvatarId);
    expect(normalizeAvatarId(''), kDefaultAvatarId);
    expect(normalizeAvatarId('👶'), kDefaultAvatarId);
    expect(normalizeAvatarId('nope'), kDefaultAvatarId);
    expect(normalizeAvatarId(kInitialAvatarId), kInitialAvatarId);
    expect(normalizeAvatarId('river'), 'river');
    expect(usesProfileInitial(kInitialAvatarId), isTrue);
    expect(usesProfileInitial(''), isTrue);
    expect(usesProfileInitial(kDefaultAvatarId), isFalse);
  });

  test('every bundled avatar is valid non-empty Lottie JSON', () {
    for (final avatar in kProfileAvatars) {
      final decoded = jsonDecode(File(avatar.assetPath).readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['v'], isNotNull, reason: avatar.id);
      expect(decoded['fr'], greaterThan(0), reason: avatar.id);
      expect(decoded['op'], greaterThan(decoded['ip']), reason: avatar.id);
      expect(decoded['layers'], isA<List>(), reason: avatar.id);
      expect((decoded['layers'] as List).isNotEmpty, isTrue, reason: avatar.id);
    }
  });
}
