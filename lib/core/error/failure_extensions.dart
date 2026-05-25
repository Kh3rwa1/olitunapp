import 'failures.dart';

extension FailureToUiMessage on Failure {
  String toUiMessage() {
    final m = message;
    if (m.isEmpty) return 'Something went wrong. Please try again.';
    if (m.contains('SocketException') || m.contains('No internet')) {
      return 'No internet connection. Check your network and retry.';
    }
    if (m.contains('401') || m.contains('Unauthorized')) {
      return 'Please sign in again to continue.';
    }
    if (m.contains('404')) return 'This content was not found.';
    if (m.contains('TracingRequired')) {
      return 'Tracing data is required for letters and numbers.';
    }
    return m.length > 140 ? '${m.substring(0, 140)}…' : m;
  }
}
