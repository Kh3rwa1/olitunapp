class ServerException implements Exception {
  final String message;
  final int? code;
  ServerException({required this.message, this.code});
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});
}

class AuthException implements Exception {
  final String message;
  AuthException({required this.message});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
}
