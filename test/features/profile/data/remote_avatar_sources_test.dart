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

  test('labels use curated Ol Chiki funny nicknames', () {
    expect(remoteAvatarLabelFromId('tiger'), 'ᱨᱟᱹᱥᱠᱟᱹ ᱛᱟ.ᱨᱩᱵ');
    expect(remoteAvatarLabelFromId('paw_prints'), 'ᱡᱟᱝᱜᱟ ᱪᱤᱱᱦᱟᱹ ᱢᱟᱥᱛᱤ');
    expect(remoteAvatarLabelFromId('default'), 'ᱨᱟᱹᱥᱠᱟᱹ ᱛᱟ.ᱨᱩᱵ');
  });

  test('labels fall back to English prettified ids when uncurated', () {
    expect(remoteAvatarLabelFromId('some_new_thing'), 'Some new thing');
    expect(remoteAvatarLabelFromId('dragon'), 'Dragon');
  });
}
