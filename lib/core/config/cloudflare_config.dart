/// Centralized Cloudflare Edge API configuration.
///
/// Serves curriculum content from Cloudflare Workers + D1 with Edge Caching.
class CloudflareConfig {
  CloudflareConfig._();

  static const String baseUrl = String.fromEnvironment(
    'CLOUDFLARE_API_URL',
    defaultValue: 'https://olitun-api.dulalkisku0.workers.dev',
  );

  static const String categoriesEndpoint = '$baseUrl/api/v1/categories';
  static const String wordsEndpoint = '$baseUrl/api/v1/words';
  static const String lettersEndpoint = '$baseUrl/api/v1/letters';
  static const String numbersEndpoint = '$baseUrl/api/v1/numbers';
  static const String sentencesEndpoint = '$baseUrl/api/v1/sentences';
  static const String lessonsEndpoint = '$baseUrl/api/v1/lessons';
}
