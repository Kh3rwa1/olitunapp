// Conditional export: reads the Appwrite SDK's cookie jar on mobile/desktop.
// The web build has no readable Appwrite cookie (it is httpOnly on the
// Appwrite domain), so web users simply sign in again.
export 'legacy_appwrite_session_stub.dart'
    if (dart.library.io) 'legacy_appwrite_session_io.dart';
