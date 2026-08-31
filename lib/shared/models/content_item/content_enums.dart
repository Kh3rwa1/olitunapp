import 'package:itun/core/error/failures.dart';

// Exceptions
class ContentValidationException implements Exception {
  final String message;
  const ContentValidationException(this.message);

  @override
  String toString() => 'ContentValidationException: $message';
}

class TracingRequiredFailure extends ValidationFailure {
  const TracingRequiredFailure({required super.message, super.fieldErrors});
}

// ContentKind
enum ContentKind {
  letter,
  number,
  word,
  sentence,
  lesson,
  rhyme;

  static ContentKind fromString(String val) {
    return ContentKind.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid ContentKind: $val'),
    );
  }
}

// ContentMediaKind
enum ContentMediaKind {
  image,
  video,
  audio,
  lottie,
  svg;

  static ContentMediaKind fromString(String val) {
    return ContentMediaKind.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid ContentMediaKind: $val'),
    );
  }
}

// CalloutVariant
enum CalloutVariant {
  tip,
  warning,
  note,
  success;

  static CalloutVariant fromString(String val) {
    return CalloutVariant.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => CalloutVariant.note,
    );
  }
}

// TracingGuide
enum TracingGuide {
  dotted,
  ghost,
  arrows,
  none;

  static TracingGuide fromString(String val) {
    return TracingGuide.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => TracingGuide.dotted,
    );
  }
}

// TracingDirection
enum TracingDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  clockwise,
  counterClockwise,
  custom;

  static TracingDirection fromString(String val) {
    return TracingDirection.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TracingDirection.custom,
    );
  }
}
