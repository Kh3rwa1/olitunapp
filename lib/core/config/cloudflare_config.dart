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
  static const String rhymesEndpoint = '$baseUrl/api/v1/rhymes';
  static const String bannersEndpoint = '$baseUrl/api/v1/banners';
  static const String quizzesEndpoint = '$baseUrl/api/v1/quizzes';
  static const String settingsEndpoint = '$baseUrl/api/v1/settings';
  static const String translateEndpoint = '$baseUrl/api/v1/translate';

  // Gamification, Mistakes & Progress
  static const String mistakesEndpoint = '$baseUrl/api/v1/mistakes';
  static const String mistakesRecordEndpoint =
      '$baseUrl/api/v1/mistakes/record';
  static const String mistakesMasterEndpoint =
      '$baseUrl/api/v1/mistakes/master';
  static const String mistakesReviewCompleteEndpoint =
      '$baseUrl/api/v1/mistakes/review/complete';
  static const String bakhedProgressEndpoint =
      '$baseUrl/api/v1/bakhed/progress';
  static const String bakhedContentEndpoint = '$baseUrl/api/v1/bakhed/content';
  static const String gamificationSummaryEndpoint =
      '$baseUrl/api/v1/gamification/summary';
  static const String gamificationContentEndpoint =
      '$baseUrl/api/v1/gamification/content';

  // Waitlist & Authorization
  static const String waitlistEndpoint = '$baseUrl/api/v1/waitlist/join';
  static const String lessonsAuthorizeEndpoint =
      '$baseUrl/api/v1/lessons/authorize';

  // Payments & Voice
  static const String paymentsOrderEndpoint = '$baseUrl/api/v1/payments/order';
  static const String paymentsVerifyEndpoint =
      '$baseUrl/api/v1/payments/verify';
  static const String paymentsEntitlementsEndpoint =
      '$baseUrl/api/v1/payments/entitlements';
  static const String voiceSynthesizeEndpoint =
      '$baseUrl/api/v1/voice/synthesize';
  static const String audioGenerateEndpoint = '$baseUrl/api/v1/audio/generate';

  // Account
  static const String deleteAccountEndpoint = '$baseUrl/api/v1/user/delete';
}
