import 'package:appwrite/appwrite.dart';

/// Neutral, Appwrite-free view of an SDK exception's classification fields.
class AppwriteErrorInfo {
  const AppwriteErrorInfo({
    required this.code,
    required this.type,
    required this.message,
  });

  final int code;
  final String type;
  final String message;
}

/// Anti-corruption helper that extracts classification fields from an
/// `AppwriteException` without leaking the SDK type into layers that must
/// not depend on `package:appwrite`.
abstract final class AppwriteErrorClassifier {
  /// Returns the SDK exception's classification fields, or null when [error]
  /// is not an Appwrite SDK exception.
  static AppwriteErrorInfo? infoOf(Object error) {
    if (error is AppwriteException) {
      return AppwriteErrorInfo(
        code: error.code ?? 0,
        type: error.type ?? '',
        message: error.message ?? '',
      );
    }
    return null;
  }
}
