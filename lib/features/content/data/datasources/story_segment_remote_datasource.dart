import 'package:appwrite/appwrite.dart';
import 'package:itun/core/api/appwrite_databases_pagination.dart';
import 'package:itun/core/config/appwrite_config.dart';
import 'package:itun/core/error/exceptions.dart';

import '../models/story_segment_model.dart';

/// Read-only access to the `story_segments` collection (spec §13).
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
  static const Duration _readTimeout = Duration(seconds: 8);

  final Databases databases;

  StorySegmentRemoteDataSourceImpl(this.databases);

  @override
  Future<List<StorySegmentModel>> getSegmentsForStory(String storyId) async {
    final trimmed = storyId.trim();
    if (trimmed.isEmpty) return const <StorySegmentModel>[];
    try {
      final documents = await AppwriteDatabasesPagination.listDocuments(
        databases,
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'story_segments',
        queries: [
          Query.equal('storyId', trimmed),
          Query.orderAsc('order'),
          Query.limit(500),
        ],
      ).timeout(_readTimeout);
      return documents
          .map((doc) => StorySegmentModel.fromJson(doc.data, doc.$id))
          .where((segment) => segment.storyId == trimmed)
          .toList();
    } on AppwriteException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to load story segments',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
