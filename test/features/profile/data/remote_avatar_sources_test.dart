import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_sources.dart';

void main() {
  test('bucket id matches the Appwrite Storage bucket', () {
    expect(remoteAvatarBucketId, 'profile_avatars');
  });

  test('ids derive from filenames', () {
    expect(remoteAvatarIdFromFilename('avatar_tiger.json'), 'tiger');
    expect(remoteAvatarIdFromFilename('avatar_paw_prints.json'), 'paw_prints');
    expect(remoteAvatarIdFromFilename('tiger.json'), 'tiger');
    expect(remoteAvatarIdFromFilename('My Cute Avatar.JSON'), 'my_cute_avatar');
  });

  test('unusable filenames yield empty ids', () {
    expect(remoteAvatarIdFromFilename('avatar_.json'), isEmpty);
    expect(remoteAvatarIdFromFilename('.json'), isEmpty);
  });

  test('labels prettify ids', () {
    expect(remoteAvatarLabelFromId('tiger'), 'Tiger');
    expect(remoteAvatarLabelFromId('paw_prints'), 'Paw prints');
    expect(remoteAvatarLabelFromId('default'), 'Default');
  });
}
