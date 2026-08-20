const String adminHostName = 'admin.olitun.in';

/// Web-only global variable that captures the hash fragment at the very start of main()
/// before any URL strategy or routing initialization can modify or strip it.
String? initialWebHash;

String? adminHostRedirectFor(String host, String path) {
  if (host.toLowerCase() != adminHostName) return null;
  if (path == '/admin' || path.startsWith('/admin/')) return null;
  return '/admin';
}

String? fragmentRedirectFor({
  required bool isWeb,
  required String path,
  required String fragment,
  String? initialHash,
}) {
  if (!isWeb || path != '/') return null;
  final hash = (initialHash != null && initialHash.isNotEmpty)
      ? initialHash
      : fragment;
  if (hash.isNotEmpty &&
      hash.startsWith('/') &&
      !hash.startsWith('//') &&
      !hash.startsWith('/\\')) {
    return hash;
  }
  return null;
}

String? adminAccessRedirectFor({required bool isAdmin, required String path}) {
  if (!path.startsWith('/admin') || path == '/admin/login') return null;
  return isAdmin ? null : '/admin/login';
}
