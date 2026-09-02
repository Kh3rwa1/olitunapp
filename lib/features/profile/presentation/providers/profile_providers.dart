/// Barrel file - profile providers split by feature area into sibling
/// files: account/identity providers in `profile_account_providers.dart`,
/// user stats + `UserStatsNotifier` in `user_stats_provider.dart`.
///
/// All public provider names are unchanged; existing
/// `import .../profile_providers.dart` statements keep working through
/// these re-exports.
library;

export 'package:itun/features/profile/domain/entities/quiz_result_entity.dart';

export 'profile_account_providers.dart';
export 'user_stats_provider.dart';
