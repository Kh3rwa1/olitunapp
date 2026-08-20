/// Centralized utility for redacting PII, credentials, session secrets,
/// IP addresses, and raw database/remote payloads before emission to logs or telemetry.
class RedactionHelper {
  RedactionHelper._();

  static final RegExp _emailRegExp = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  static final RegExp _sessionSecretRegExp = RegExp(
    r'\b(a_session_[a-zA-Z0-9_-]+|key_secret\s*=\s*[a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  static final RegExp _bearerTokenRegExp = RegExp(
    r'\bBearer\s+[a-zA-Z0-9._-]+',
    caseSensitive: false,
  );

  static final RegExp _jwtRegExp = RegExp(
    r'\beyJ[a-zA-Z0-9_-]{8,}\.[a-zA-Z0-9_-]{8,}\.[a-zA-Z0-9_-]{8,}\b',
  );

  static final RegExp _passwordRegExp = RegExp(
    r'''\b(password|pass|secret|apiKey|api_key)\s*[:=]\s*["']?([^"'\s,;{}]+)["']?''',
    caseSensitive: false,
  );

  static final RegExp _razorpayKeyRegExp = RegExp(
    r'(rzp_live_[a-zA-Z0-9]{10,}|rzp_test_[a-zA-Z0-9]{10,})',
  );

  static final RegExp _ipv4RegExp = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b',
  );

  /// Redact email address (e.g. `user@example.com` -> `u***@example.com`).
  static String redactEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return '[REDACTED_EMAIL]';
    final name = parts[0];
    final domain = parts[1];
    final redactedName = name.length > 1 ? '${name[0]}***' : '***';
    return '$redactedName@$domain';
  }

  /// Redact session secrets or API keys.
  static String redactSecret(String secret) {
    if (secret.isEmpty) return '';
    if (secret.length <= 4) return '***';
    return '${secret.substring(0, 2)}***${secret.substring(secret.length - 2)}';
  }

  /// Sanitize arbitrary text log messages by stripping emails, bearer tokens, JWTs, passwords, and IP addresses.
  static String sanitize(String message) {
    if (message.isEmpty) return message;
    var result = message;

    result = result.replaceAllMapped(_emailRegExp, (match) {
      return redactEmail(match.group(0)!);
    });

    result = result.replaceAllMapped(_jwtRegExp, (_) {
      return '[REDACTED_JWT]';
    });

    result = result.replaceAllMapped(_sessionSecretRegExp, (_) {
      return '[REDACTED_SESSION_SECRET]';
    });

    result = result.replaceAllMapped(_bearerTokenRegExp, (_) {
      return 'Bearer [REDACTED_TOKEN]';
    });

    result = result.replaceAllMapped(_razorpayKeyRegExp, (_) {
      return '[REDACTED_PAYMENT_KEY]';
    });

    result = result.replaceAllMapped(_passwordRegExp, (match) {
      final key = match.group(1);
      return '$key=[REDACTED]';
    });

    result = result.replaceAllMapped(_ipv4RegExp, (_) {
      return '[REDACTED_IP]';
    });

    return result;
  }
}
