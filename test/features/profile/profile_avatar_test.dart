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
    expect(normalizeAvatarId('owl'), 'owl');
    expect(usesProfileInitial(kInitialAvatarId), isTrue);
    expect(usesProfileInitial(''), isTrue);
    expect(usesProfileInitial(kDefaultAvatarId), isFalse);
  });

  test('every bundled avatar is valid non-empty Lottie JSON', () {    for (final avatar in kProfileAvatars) {
      final decoded = jsonDecode(File(avatar.assetPath).readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['v'], isNotNull, reason: avatar.id);
      expect(decoded['fr'], greaterThan(0), reason: avatar.id);
      expect(decoded['op'], greaterThan(decoded['ip']), reason: avatar.id);
      expect(decoded['layers'], isA<List>(), reason: avatar.id);
      expect((decoded['layers'] as List).isNotEmpty, isTrue, reason: avatar.id);
    }
  });

  test('merge keeps bundled order and appends new remote ids', () {
    const dragon = ProfileAvatar(
      id: 'dragon',
      assetFileName: 'avatar_dragon.json',
      label: 'Dragon',
      remoteFileId: 'file-dragon',
    );

    expect(mergeAvatarCatalog(const []), same(kProfileAvatars));

    final merged = mergeAvatarCatalog(const [dragon]);
    expect(
      merged.map((avatar) => avatar.id),
      orderedEquals([
        ...kProfileAvatars.map((avatar) => avatar.id),
        'dragon',
      ]),
    );
    expect(merged.last.isRemote, isTrue);
  });

  test('merge lets remote win on id conflicts without reshuffling', () {
    const updated = ProfileAvatar(
      id: 'owl',
      assetFileName: 'avatar_owl_v2.json',
      label: 'Owl v2',
      remoteFileId: 'file-owl',
    );

    final merged = mergeAvatarCatalog(const [updated]);
    expect(
      merged.map((avatar) => avatar.id),
      orderedEquals(kProfileAvatars.map((avatar) => avatar.id)),
    );
    expect(merged.firstWhere((avatar) => avatar.id == 'owl'), updated);
  });

  test('remote-aware normalization accepts synced ids, rejects the rest', () {
    expect(normalizeAvatarIdWithRemote('dragon', {'dragon'}), 'dragon');
    expect(normalizeAvatarIdWithRemote('dragon', {'other'}), kDefaultAvatarId);
    expect(normalizeAvatarIdWithRemote('dragon', null), kDefaultAvatarId);
    expect(normalizeAvatarIdWithRemote('owl', null), 'owl');
    expect(
      normalizeAvatarIdWithRemote(kInitialAvatarId, {'dragon'}),
      kInitialAvatarId,
    );
    expect(normalizeAvatarIdWithRemote('🦊', {'dragon'}), kDefaultAvatarId);
    expect(normalizeAvatarIdWithRemote('', {'dragon'}), kDefaultAvatarId);
  });
}
