sealed class DataValidationResult<T> {
  const DataValidationResult();
}

class ValidationSuccess<T> extends DataValidationResult<T> {
  final T value;
  const ValidationSuccess(this.value);
}

class ValidationFailure<T> extends DataValidationResult<T> {
  final String documentId;
  final String reason;
  final Map<String, dynamic>? rawData;

  const ValidationFailure({
    required this.documentId,
    required this.reason,
    this.rawData,
  });
}
