/// Barrel file — re-exports all split providers for zero import breakage.
library;

///
/// Existing `import 'providers.dart'` statements across the app
/// continue to work because this file re-exports everything.

export 'app_settings_provider.dart';
export '../../features/auth/presentation/providers/auth_providers.dart';
export 'local_settings_provider.dart';
export '../../features/profile/presentation/providers/profile_providers.dart';
export '../../features/categories/presentation/providers/category_notifier.dart';
export '../../features/categories/presentation/providers/category_providers.dart';
export 'banners_provider.dart';
export 'letters_provider.dart';
export 'numbers_provider.dart';
export 'words_provider.dart';
export 'sentences_provider.dart';
export '../../features/lessons/presentation/providers/lesson_notifier.dart';
export '../../features/lessons/presentation/providers/lesson_providers.dart';
export 'quizzes_provider.dart';
export 'rhymes_providers.dart';
export 'seed_provider.dart';
export 'dashboard_metrics_provider.dart';
