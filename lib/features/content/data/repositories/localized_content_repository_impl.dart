import 'package:fpdart/fpdart.dart';
import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/core/observability/crash_reporting.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';
import 'package:itun/features/content/domain/repositories/localized_content_repository.dart';

import '../datasources/localized_content_remote_datasource.dart';

/// Offline-first [LocalizedContentRepository] (spec §11).
///
/// Approved localizations are memoized per (item, language) and per
/// (batch, language) so lesson/vocabulary screens can resolve meanings
/// after network loss. Only approved rows ever surface from read
/// methods; drafts stay for admin tooling (Phase 5).
class LocalizedContentRepositoryImpl implements LocalizedContentRepository {
  final LocalizedContentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  /// item key -> language -> approved localization (or null = fetched,
  /// none exists — cached to avoid refetching known-missing overlays).
  final Map<String, Map<String, LocalizedContent?>> _cache = {};

  /// In-flight request dedup so concurrent resolvers share one fetch.
  final Map<String, Future<List<LocalizedContent>>> _inFlight = {};

  static const int _maxCachedItems = 300;

  LocalizedContentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  static String _itemKey(String contentKind, String contentId) =>
      '$contentKind:$contentId';

  ServerFailure _recordedServerFailure(ServerException e, [StackTrace? st]) {
    final failure = ServerFailure(message: e.message, code: e.code);
    CrashReporting.recordFailure(failure, st);
    return failure;
  }

  List<LocalizedContent> _validated(List<LocalizedContent> items) {
    return items.where((item) {
      final isValid =
          item.contentId.trim().isNotEmpty &&
          item.languageCode.trim().isNotEmpty;
      if (!isValid) {
        AppLogger.warning(
          'LocalizedContentRepositoryImpl: dropped invalid row ${item.id}',
        );
      }
      return isValid;
    }).toList();
  }

  void _trimCache() {
    while (_cache.length > _maxCachedItems) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<List<LocalizedContent>> _fetchForLanguage({
    required String contentKind,
    required String contentId,
    required String languageCode,
  }) {
    final key = '${_itemKey(contentKind, contentId)}@$languageCode';
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = () async {
      final rows = await remoteDataSource.getLocalizationsForLanguage(
        contentKind: contentKind,
        contentId: contentId,
        languageCode: languageCode,
      );
      final entities = rows
          .map((row) => row.toEntity())
          .whereType<LocalizedContent>()
          .toList();
      final valid = _validated(entities);
      final approved = valid.where((item) => item.isApproved).toList();
      _cacheApprovedSingle(contentKind, contentId, languageCode, approved);
      return approved;
    }();
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  void _cacheApprovedSingle(
    String contentKind,
    String contentId,
    String languageCode,
    List<LocalizedContent> approved,
  ) {
    final itemKey = _itemKey(contentKind, contentId);
    final languages = _cache.putIfAbsent(itemKey, () => {});
    _trimCache();
    // One row per (item, language) is enforced by a unique index.
    languages[languageCode] = approved.isEmpty ? null : approved.first;
  }

  void _cacheApprovedBatch(
    String contentKind,
    String languageCode,
    List<LocalizedContent> approved,
  ) {
    for (final item in approved) {
      _cacheApprovedSingle(item.contentKind, item.contentId, languageCode, [
        item,
      ]);
    }
    _trimCache();
  }

  @override
  Future<Either<Failure, List<LocalizedContent>>> getLocalizations({
    required String contentKind,
    required String contentId,
  }) async {
    try {
      final rows = await remoteDataSource.getLocalizations(
        contentKind: contentKind,
        contentId: contentId,
      );
      final entities = rows
          .map((row) => row.toEntity())
          .whereType<LocalizedContent>()
          .toList();
      return Right(_validated(entities).where((i) => i.isApproved).toList());
    } on ServerException catch (e, st) {
      return Left(_recordedServerFailure(e, st));
    }
  }

  @override
  Future<Either<Failure, LocalizedContent?>> getLocalization({
    required String contentKind,
    required String contentId,
    required String languageCode,
  }) async {
    final itemKey = _itemKey(contentKind, contentId);
    final cachedLanguages = _cache[itemKey];
    if (cachedLanguages != null && cachedLanguages.containsKey(languageCode)) {
      return Right(cachedLanguages[languageCode]);
    }

    try {
      final approved = await _fetchForLanguage(
        contentKind: contentKind,
        contentId: contentId,
        languageCode: languageCode,
      );
      return Right(approved.isEmpty ? null : approved.first);
    } on ServerException catch (e, st) {
      return Left(_recordedServerFailure(e, st));
    }
  }

  @override
  Future<Either<Failure, List<LocalizedContent>>> getLocalizationsForIds({
    required String contentKind,
    required List<String> contentIds,
    required String languageCode,
  }) async {
    if (contentIds.isEmpty) return const Right(<LocalizedContent>[]);

    // Serve whatever is cached, then fetch only the missing items.
    final missing = <String>[];
    final result = <LocalizedContent>[];
    for (final id in contentIds) {
      final cached = _cache[_itemKey(contentKind, id)]?[languageCode];
      if (cached != null) {
        result.add(cached);
      } else {
        missing.add(id);
      }
    }

    if (missing.isNotEmpty) {
      try {
        final isConnected = await networkInfo.isConnected;
        if (isConnected) {
          final rows = await remoteDataSource.getLocalizationsForIds(
            contentKind: contentKind,
            contentIds: missing,
            languageCode: languageCode,
          );
          final approved = rows
              .map((row) => row.toEntity())
              .whereType<LocalizedContent>()
              .where((item) => item.isApproved)
              .toList();
          _cacheApprovedBatch(contentKind, languageCode, approved);
          result.addAll(approved);
        }
      } on ServerException catch (e, st) {
        // Offline / server failure must not break lesson screens — serve
        // whatever was cached and continue (spec §11: no crash when
        // translation is unavailable).
        _recordedServerFailure(e, st);
      }
    }

    return Right(result);
  }

  // ── Write operations ──────────────────────────────────────────────
  // Mobile clients never create or approve localizations (spec §7):
  // approval happens in the admin CMS by a reviewer with team membership.
  // These exist to satisfy the Phase 2 interface for admin tooling; the
  // app only reads.

  @override
  Future<Either<Failure, void>> saveLocalization(
    LocalizedContent content,
  ) async {
    AppLogger.warning(
      'LocalizedContentRepositoryImpl.saveLocalization rejected: mobile '
      'clients cannot write localizations',
    );
    return const Left(
      AuthFailure(message: 'Localizations are managed via the admin CMS'),
    );
  }

  @override
  Future<Either<Failure, void>> deleteLocalization(String id) async {
    AppLogger.warning(
      'LocalizedContentRepositoryImpl.deleteLocalization rejected: mobile '
      'clients cannot delete localizations',
    );
    return const Left(
      AuthFailure(message: 'Localizations are managed via the admin CMS'),
    );
  }
}
