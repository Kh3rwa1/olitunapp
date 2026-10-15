/// Barrel file — re-exports all split providers for zero import breakage.
library;

///
/// Existing `import 'providers.dart'` statements across the app
/// continue to work because this file re-exports everything.

export '../../core/config/app_settings_provider.dart';
export 'language_settings_providers.dart';
export '../../core/auth/auth_providers.dart';

export 'local_settings_provider.dart';
export 'banners_provider.dart';
export 'letters_provider.dart';
export 'numbers_provider.dart';
export 'words_provider.dart';
export 'sentences_provider.dart';
export 'dashboard_metrics_provider.dart';
export 'gamification_content_provider.dart';
export 'bakhed_content_provider.dart';
export '../../core/payments/purchased_categories_provider.dart';
export 'waitlist_provider.dart';
export '../models/content_item.dart';
export '../models/content_item_extensions.dart';
export '../repositories/content_repository.dart';
export 'content_providers.dart';
export 'learner_content_providers.dart';
export 'notification_providers.dart';
