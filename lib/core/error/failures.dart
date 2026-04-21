sealed class Failure {
  final String message;
  final int? code;
  const Failure({required this.message, this.code});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
  });
}
