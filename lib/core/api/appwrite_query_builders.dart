import 'package:appwrite/appwrite.dart';

/// Presentation-friendly query builders that delegate to the Appwrite SDK's
/// static helpers without exposing `package:appwrite` to presentation/domain
/// layers.
///
/// Values produced by [DbQuery] are plain query strings consumed by
/// [AppwriteDbService] methods.
abstract final class DbQuery {
  static String equal(String attribute, dynamic value) =>
      Query.equal(attribute, value);

  static String notEqual(String attribute, dynamic value) =>
      Query.notEqual(attribute, value);

  static String greaterThan(String attribute, dynamic value) =>
      Query.greaterThan(attribute, value);

  static String greaterThanEqual(String attribute, dynamic value) =>
      Query.greaterThanEqual(attribute, value);

  static String lessThan(String attribute, dynamic value) =>
      Query.lessThan(attribute, value);

  static String lessThanEqual(String attribute, dynamic value) =>
      Query.lessThanEqual(attribute, value);

  static String limit(int value) => Query.limit(value);

  static String orderAsc(String attribute) => Query.orderAsc(attribute);

  static String orderDesc(String attribute) => Query.orderDesc(attribute);

  static String search(String attribute, String value) =>
      Query.search(attribute, value);
}

/// Presentation-friendly document ID generator, mirroring [ID.unique].
abstract final class DbId {
  static String unique() => ID.unique();
}
