/// Centralized utility for redacting PII, credentials, session secrets,
/// and raw database/remote payloads before emission to logs or telemetry.
class RedactionHelper {
  RedactionHelper._();

  static final RegExp _emailRegExp = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _sessionSecretRegExp = RegExp(
    r'(a_session_[a-zA-Z0-9_-]+|secret=[a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );

  static final RegExp _bearerTokenRegExp = RegExp(
    r'Bearer\s+[a-zA-Z0-9._-]+',
    caseSensitive: false,
  );

  /// Redact email address (e.g. `user@example.com` -> `u***@example.com`).
  static String redactEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return '[REDACTED_EMAIL]';
    final name = parts[0];
    final domain = parts[1];
    final redactedName = name.length > 1
        ? '${name[0]}***'
        : '***';
    return '$redactedName@$domain';
  }

  /// Redact session secrets or API keys.
  static String redactSecret(String secret) {
    if (secret.isEmpty) return '';
    if (secret.length <= 4) return '***';
    return '${secret.substring(0, 2)}***${secret.substring(secret.length - 2)}';
  }

  /// Sanitize arbitrary text log messages by stripping emails, bearer tokens, and secrets.
  static String sanitize(String message) {
    if (message.isEmpty) return message;
    var result = message;

    result = result.replaceAllMapped(_emailRegExp, (match) {
      return redactEmail(match.group(0)!);
    });

    result = result.replaceAllMapped(_sessionSecretRegExp, (_) {
      return '[REDACTED_SESSION_SECRET]';
    });

    result = result.replaceAllMapped(_bearerTokenRegExp, (_) {
      return 'Bearer [REDACTED_TOKEN]';
    });

    return result;
  }
}
