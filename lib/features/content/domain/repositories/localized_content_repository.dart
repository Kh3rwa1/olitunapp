import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/localized_content_entity.dart';

/// Access to teaching-language translations of Santali content items.
///
/// Reads are served from the local cache first (offline-first); writes go
/// through the admin CMS flows only — mobile clients never create or
/// approve localizations.
abstract class LocalizedContentRepository {
  /// All approved localizations for [contentKind]:[contentId].
  ///
  /// Returns only rows whose [LocalizedContent.reviewStatus] is
  /// approved — drafts and machine-generated entries stay in the CMS.
  Future<Either<Failure, List<LocalizedContent>>> getLocalizations({
    required String contentKind,
    required String contentId,
  });

  /// The localization for a single teaching language, or null when
  /// none is approved yet (callers fall back to legacy English fields).
  Future<Either<Failure, LocalizedContent?>> getLocalization({
    required String contentKind,
    required String contentId,
    required String languageCode,
  });

  /// Localizations for many content items at once (batch reads keep
  /// lesson/story screens to a single query per language).
  Future<Either<Failure, List<LocalizedContent>>> getLocalizationsForIds({
    required String contentKind,
    required List<String> contentIds,
    required String languageCode,
  });

  Future<Either<Failure, void>> saveLocalization(LocalizedContent content);

  Future<Either<Failure, void>> deleteLocalization(String id);
}
