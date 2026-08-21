/// Safe CSV generation utilities protecting against CSV / Spreadsheet Formula Injection (CWE-1236).
class SafeCsvHelper {
  const SafeCsvHelper._();

  /// Characters that trigger spreadsheet formula execution in Excel, LibreOffice, Google Sheets.
  static final RegExp _formulaInjectionPattern = RegExp(r'^[=\+\-@\t\r]');

  /// Sanitizes a single cell value to be formula-safe and CSV-escaped.
  static String escapeCell(Object? value) {
    if (value == null) return '';
    var text = value.toString();

    // Redact accidental secrets or tokens
    if (_isSecretLike(text)) {
      text = '[REDACTED_SECRET]';
    }

    // Neutralize formula injection if the string begins with =, +, -, @, tab, or CR
    if (_formulaInjectionPattern.hasMatch(text)) {
      text = "'$text";
    }

    // If text contains comma, quote, or newline, escape quotes and wrap in quotes
    final needsQuotes =
        text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');

    if (needsQuotes) {
      final escaped = text.replaceAll('"', '""');
      return '"$escaped"';
    }

    return text;
  }

  /// Builds a complete, formula-safe CSV string from headers, rows, and optional metadata comments.
  static String buildCsv({
    required List<String> headers,
    required List<List<Object?>> rows,
    Map<String, String>? metadata,
  }) {
    final buffer = StringBuffer();

    // Optional metadata block at top of export
    if (metadata != null && metadata.isNotEmpty) {
      for (final entry in metadata.entries) {
        final keyEscaped = escapeCell('# ${entry.key}');
        final valEscaped = escapeCell(entry.value);
        buffer.writeln('$keyEscaped,$valEscaped');
      }
      buffer.writeln(); // Empty separator line
    }

    // Headers
    buffer.writeln(headers.map(escapeCell).join(','));

    // Rows
    for (final row in rows) {
      buffer.writeln(row.map(escapeCell).join(','));
    }

    return buffer.toString();
  }

  /// Checks if a string looks like a secret API key or private credential.
  static bool _isSecretLike(String value) {
    final lower = value.toLowerCase();
    if (lower.startsWith('rzp_sec_') ||
        lower.startsWith('secret_') ||
        lower.startsWith('standard_') ||
        lower.startsWith('a_session_console=')) {
      return true;
    }
    return false;
  }
}
