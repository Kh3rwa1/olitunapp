import 'package:http/http.dart' as http;
import 'package:itun/core/api/edge_json_client.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/error/exceptions.dart';

import '../models/story_segment_model.dart';

/// Read-only access to story segments via the Cloudflare Worker
/// (`GET /api/v1/story-segments`, backed by D1 `story_segments`, spec §13).
///
/// Segments are authored in the admin CMS; the learner app only reads
/// them. One story's segments are fetched together so the story player
/// can highlight and step through them without extra queries.
abstract class StorySegmentRemoteDataSource {
  /// All segments of [storyId] ordered by `order`. Returns an empty
  /// list for an empty id so degenerate calls never hit the network.
  Future<List<StorySegmentModel>> getSegmentsForStory(String storyId);
}

class StorySegmentRemoteDataSourceImpl implements StorySegmentRemoteDataSource {
  final http.Client _client;

  StorySegmentRemoteDataSourceImpl(this._client);

  @override
  Future<List<StorySegmentModel>> getSegmentsForStory(String storyId) async {
    final trimmed = storyId.trim();
    if (trimmed.isEmpty) return const <StorySegmentModel>[];
    try {
      final uri = Uri.parse(
        CloudflareConfig.storySegmentsEndpoint,
      ).replace(queryParameters: {'storyId': trimmed});
      final rows = await EdgeJsonClient.getList(_client, uri, 'segments');
      final segments = rows
          .map((row) => StorySegmentModel.fromJson(row, '${row['id'] ?? ''}'))
          .where((segment) => segment.storyId == trimmed)
          .toList();
      segments.sort((a, b) => a.order.compareTo(b.order));
      return segments;
    } on EdgeApiException catch (e) {
      throw ServerException(
        message: 'Failed to load story segments: ${e.message}',
        code: e.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
