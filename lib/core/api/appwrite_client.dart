import 'package:appwrite/appwrite.dart';

import '../auth/appwrite_auth_service.dart';

/// Global Appwrite SDK client.
///
/// This is a thin top-level accessor over the single [Client] instance owned
/// by [AppwriteAuthService]. It is the recommended entry point whenever you
/// need to call low-level Appwrite SDK methods (e.g. [Client.ping]) outside
/// of an existing service or repository.
///
/// Endpoint and project ID are configured once, at construction time, from
/// the `APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID` build-time flags via
/// [AppwriteConfig]. Reusing the singleton (rather than constructing a new
/// [Client]) guarantees that authenticated sessions, cookies, headers and
/// any future client-level interceptors stay consistent across the app.
///
/// Example:
///
/// ```dart
/// import 'package:itun/core/api/appwrite_client.dart';
///
/// await client.ping(); // verify connectivity to Appwrite
/// ```
final Client client = AppwriteAuthService().client;
