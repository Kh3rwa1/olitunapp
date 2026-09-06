import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../api/appwrite_functions_service.dart';
import '../config/appwrite_config.dart';
import 'authorized_media.dart';

final authorizedMediaServiceProvider = Provider<AuthorizedMediaService>((ref) {
  ref.watch(currentUserProvider.select((state) => state.value?.id));
  final functions = ref.watch(appwriteFunctionsServiceProvider);
  return AuthorizedMediaService(
    endpoint: AppwriteConfig.endpoint,
    projectId: AppwriteConfig.projectId,
    execute: (body) async {
      final result = await functions.execute(
        'getAuthorizedLesson',
        body: body,
        usePost: true,
      );
      if (!result.isCompleted || result.statusCode != 200) {
        throw const MediaAccessException();
      }
      return result.bodyJson ?? (throw const MediaAccessException());
    },
  );
});
