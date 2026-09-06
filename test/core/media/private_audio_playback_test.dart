import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/audio/private_audio_playback.dart';
import 'package:itun/core/media/authorized_media.dart';

class _Player extends Mock implements AudioPlayer {}

class _Source extends Fake implements AudioSource {}

void main() {
  setUpAll(() => registerFallbackValue(_Source()));

  testWidgets(
    'private audio renews URI, preserves position, and stops on denial',
    (tester) async {
      final player = _Player();
      when(player.pause).thenAnswer((_) async {});
      when(player.stop).thenAnswer((_) async {});
      when(player.play).thenAnswer((_) async {});
      when(() => player.position).thenReturn(const Duration(seconds: 12));
      when(() => player.playing).thenReturn(true);
      final loaded = <AudioSource>[];
      final positions = <Duration?>[];
      when(
        () => player.setAudioSource(
          any(),
          initialPosition: any(named: 'initialPosition'),
        ),
      ).thenAnswer((invocation) async {
        loaded.add(invocation.positionalArguments.first as AudioSource);
        positions.add(invocation.namedArguments[#initialPosition] as Duration?);
        return const Duration(minutes: 10);
      });
      var now = DateTime.utc(2026, 9, 6);
      var requests = 0;
      var denied = false;
      final media = AuthorizedMediaService(
        endpoint: 'https://media.example.test/v1',
        projectId: 'test',
        clock: () => now,
        execute: (_) async {
          requests++;
          if (denied) throw const MediaAccessException();
          return {
            'ok': true,
            'protocolVersion': 2,
            'transport': 'appwrite-file-token',
            'bucketId': 'paid_media',
            'fileId': 'file',
            'url':
                'https://media.example.test/v1/storage/buckets/paid_media/files/file/view?project=test&token=lease$requests',
            'expiresAt': now.add(const Duration(minutes: 5)).toIso8601String(),
            'mimeType': 'audio/mpeg',
          };
        },
      );
      final playback = PrivateAudioPlayback(player, media);
      expect(
        await playback.play(
          'appwrite-storage://paid_media/file?lessonId=lesson',
        ),
        true,
      );
      expect(requests, 1);
      now = now.add(const Duration(minutes: 4, seconds: 30));
      await tester.pump(const Duration(minutes: 4, seconds: 30));
      expect(requests, 2);
      expect(loaded.length, 2);
      expect(positions.last, const Duration(seconds: 12));
      expect(
        (loaded.last as UriAudioSource).uri.queryParameters['token'],
        'lease2',
      );
      denied = true;
      await playback.resume();
      expect(playback.active, false);
      expect(
        loaded.length,
        2,
        reason: 'No stale source fallback after revocation',
      );
      verify(player.stop).called(1);
      playback.cancel();
    },
  );

  test('failed stop cleanup cannot leak a private resolution error', () async {
    final player = _Player();
    when(player.pause).thenAnswer((_) async {});
    when(player.stop).thenThrow(StateError('native player already disposed'));
    final media = AuthorizedMediaService(
      endpoint: 'https://media.example.test/v1',
      projectId: 'test',
      execute: (_) async => throw const MediaAccessException(),
    );
    final playback = PrivateAudioPlayback(player, media);
    expect(
      await playback.play('appwrite-storage://paid_media/file?lessonId=lesson'),
      false,
    );
    expect(playback.active, false);
    verify(player.stop).called(1);
    playback.cancel();
  });
}
