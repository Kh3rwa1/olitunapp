import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/domain/entities/profile_avatar.dart';

void main() {
  test('avatar catalog ids are unique and resolve to asset paths', () {
    final ids = kProfileAvatars.map((avatar) => avatar.id).toList();
    expect(ids.toSet().length, ids.length);

    for (final avatar in kProfileAvatars) {
      expect(avatar.assetPath, '$avatarsAssetDir/${avatar.assetFileName}');
      expect(avatarAssetPath(avatar.id), avatar.assetPath);
    }
  });

  test('unknown and legacy emoji ids normalize to the default avatar', () {
    expect(normalizeAvatarId(null), kDefaultAvatarId);
    expect(normalizeAvatarId(''), kDefaultAvatarId);
    expect(normalizeAvatarId('👶'), kDefaultAvatarId);
    expect(normalizeAvatarId('nope'), kDefaultAvatarId);
    expect(normalizeAvatarId('girl_02'), 'girl_02');
    expect(avatarAssetPath('nope'), '$avatarsAssetDir/avatar_default.json');
  });

  test('default avatar animation file is bundled valid Lottie JSON', () {
    final file = File('$avatarsAssetDir/avatar_default.json');
    expect(file.existsSync(), isTrue);

    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<Map<String, dynamic>>());
    expect(decoded['v'], isNotNull);
    expect(decoded['layers'], isA<List>());
    expect((decoded['layers'] as List).isNotEmpty, isTrue);
  });
}
