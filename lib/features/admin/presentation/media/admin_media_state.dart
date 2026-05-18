import 'package:flutter_riverpod/flutter_riverpod.dart';

// Media type enum
enum MediaType { all, image, audio, video }

// Sample media item model
class MediaItem {
  final String id;
  final String name;
  final String url;
  final MediaType type;
  final int size;
  final DateTime uploadedAt;

  MediaItem({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });
}

// Provider for media items (mock data for preview)
final mediaItemsProvider = StateProvider<List<MediaItem>>(
  (ref) => [
    MediaItem(
      id: '1',
      name: 'alphabet_a.png',
      url: 'https://via.placeholder.com/200',
      type: MediaType.image,
      size: 45000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MediaItem(
      id: '2',
      name: 'lesson_intro.mp3',
      url: 'https://example.com/audio.mp3',
      type: MediaType.audio,
      size: 2500000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MediaItem(
      id: '3',
      name: 'welcome_video.mp4',
      url: 'https://example.com/video.mp4',
      type: MediaType.video,
      size: 15000000,
      uploadedAt: DateTime.now(),
    ),
  ],
);

final selectedMediaTypeProvider = StateProvider<MediaType>(
  (ref) => MediaType.all,
);
