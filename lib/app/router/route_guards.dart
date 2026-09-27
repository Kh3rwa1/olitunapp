const String adminHostName = 'admin.olitun.in';

/// Web-only global variable that captures the hash fragment at the very start of main()
/// before any URL strategy or routing initialization can modify or strip it.
String? initialWebHash;

String? adminHostRedirectFor(String host, String path, {bool isWeb = true}) {
  if (!isWeb) return null;
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
  if (!isWeb || (path != '/' && path != '/splash' && path != '/welcome')) {
    return null;
  }
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

String? adminAccessRedirectFor({
  required bool isAdmin,
  required String path,
  bool isWeb = true,
}) {
  if (!path.startsWith('/admin')) return null;
  if (!isWeb) return '/';
  if (path == '/admin/login') return null;
  return isAdmin ? null : '/admin/login';
}

/// Pure routing decision function that coordinates mandatory auth gating,
/// onboarding completion requirements, and public routes.
String? authAndOnboardingRedirectFor({
  required String path,
  required bool? isAuth,
  required bool showOnboarding,
  bool isWeb = true,
}) {
  // On non-web (mobile) devices, the admin portal is completely disabled.
  if (!isWeb && (path == '/admin' || path.startsWith('/admin/'))) {
    return '/';
  }

  final isPublicAuthPath =
      path == '/welcome' ||
      path == '/splash' ||
      path == '/login' ||
      path == '/privacy' ||
      path == '/terms' ||
      (isWeb && path.startsWith('/admin'));

  // Authenticated users should not stay on login or welcome screens
  if (isAuth == true && (path == '/welcome' || path == '/login')) {
    return showOnboarding ? '/onboarding' : '/';
  }

  // Enforce mandatory authentication: confirmed logged-out users cannot access protected routes
  if (isAuth == false && !isPublicAuthPath) {
    return '/welcome';
  }

  // Check onboarding: if onboarding not completed and user attempts to access protected content, redirect to onboarding
  if (showOnboarding &&
      isAuth == true &&
      path != '/onboarding' &&
      !isPublicAuthPath) {
    return '/onboarding';
  }

  return null;
}
