import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content_models.dart';
import '../models/user_model.dart';
import '../../core/config/supabase_config.dart';
import '../../features/auth/data/auth_repository.dart';

// Keep main import if needed for global prefs, but usually we use the instance below
import '../../main.dart';

// ============== AUTH & USER ==============

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(SupabaseConfig.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value?.session?.user;
});

/// Real-time stream of the user's profile
final userProfileProvider = StreamProvider<UserModel?>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final stream = SupabaseConfig.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map(
        (event) => event.isNotEmpty ? UserModel.fromJson(event.first) : null,
      );

  yield* stream;
});

// --- Legacy Provider Adapters (Read-Only) ---
// These allow existing UI to read values (handling nulls gracefully)

final userNameProvider = Provider<String>((ref) {
  return ref.watch(userProfileProvider).value?.displayName ?? 'Learner';
});

final userStreakProvider = Provider<int>((ref) {
  return ref.watch(userProfileProvider).value?.stats.streak ?? 0;
});

final userStarsProvider = Provider<int>((ref) {
  return ref.watch(userProfileProvider).value?.stats.stars ?? 0;
});

final lessonsCompletedProvider = Provider<int>((ref) {
  return ref.watch(userProfileProvider).value?.stats.totalLessonsCompleted ?? 0;
});

final quizzesCompletedProvider = Provider<int>((ref) {
  return ref.watch(userProfileProvider).value?.stats.totalQuizzesCompleted ?? 0;
});

// --- Write Actions ---
// These replace the StateProvider.notifier updates

Future<void> updateUserName(WidgetRef ref, String name) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  await SupabaseConfig.client
      .from('profiles')
      .update({'display_name': name})
      .eq('id', user.id);
}

Future<void> updateStreak(WidgetRef ref, int streak) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  // We need to merge with existing stats, but for now simple update
  // Ideally this should be a stored procedure or careful update
  // Fetch current stats first or use jsonb_set in SQL.
  // Simple approach: READ -> MODIFY -> WRITE
  // Note: better to do this in backend, but client-side for now:
  final currentProfile = ref.read(userProfileProvider).value;
  if (currentProfile != null) {
    final newStats = currentProfile.stats.copyWith(streak: streak).toJson();
    await SupabaseConfig.client
        .from('profiles')
        .update({'stats': newStats})
        .eq('id', user.id);
  }
}

Future<void> addStars(WidgetRef ref, int amount) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final currentProfile = ref.read(userProfileProvider).value;
  if (currentProfile != null) {
    final newStars = currentProfile.stats.stars + amount;
    final newStats = currentProfile.stats.copyWith(stars: newStars).toJson();
    await SupabaseConfig.client
        .from('profiles')
        .update({'stats': newStats})
        .eq('id', user.id);
  }
}

Future<void> incrementLessonsCompleted(WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final currentProfile = ref.read(userProfileProvider).value;
  if (currentProfile != null) {
    final newVal = currentProfile.stats.totalLessonsCompleted + 1;
    final newStats = currentProfile.stats
        .copyWith(totalLessonsCompleted: newVal)
        .toJson();
    await SupabaseConfig.client
        .from('profiles')
        .update({'stats': newStats})
        .eq('id', user.id);
  }
}

Future<void> incrementQuizzesCompleted(WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final currentProfile = ref.read(userProfileProvider).value;
  if (currentProfile != null) {
    final newVal = currentProfile.stats.totalQuizzesCompleted + 1;
    final newStats = currentProfile.stats
        .copyWith(totalQuizzesCompleted: newVal)
        .toJson();
    await SupabaseConfig.client
        .from('profiles')
        .update({'stats': newStats})
        .eq('id', user.id);
  }
}

// ============== SETTINGS (Local Storage) ==============
// These can remain local for now as they are device specific often

final themeModeProvider = StateProvider<String>((ref) {
  return prefs.getString('theme_mode') ?? 'system';
});

final scriptModeProvider = StateProvider<String>((ref) {
  return prefs.getString('script_mode') ?? 'both';
});

final soundEnabledProvider = StateProvider<bool>((ref) {
  return prefs.getBool('sound_enabled') ?? true;
});

void updateThemeMode(WidgetRef ref, String mode) {
  prefs.setString('theme_mode', mode);
  ref.read(themeModeProvider.notifier).state = mode;
}

void updateScriptMode(WidgetRef ref, String mode) {
  prefs.setString('script_mode', mode);
  ref.read(scriptModeProvider.notifier).state = mode;
}

void toggleSound(WidgetRef ref) {
  final current = ref.read(soundEnabledProvider);
  prefs.setBool('sound_enabled', !current);
  ref.read(soundEnabledProvider.notifier).state = !current;
}

// ============== CONTENT PROVIDERS (Supabase) ==============
// All content providers are now AsyncValue

// 1. Categories
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((
      ref,
    ) {
      return CategoriesNotifier();
    });

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  CategoriesNotifier() : super(const AsyncValue.loading()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription = SupabaseConfig.client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('order')
        .listen(
          (data) {
            final list = data.map((e) => CategoryModel.fromJson(e)).toList();
            state = AsyncValue.data(list);
          },
          onError: (error, stack) {
            state = AsyncValue.error(error, stack);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addCategory(CategoryModel item) async {
    await SupabaseConfig.client.from('categories').insert(item.toJson());
  }

  Future<void> updateCategory(CategoryModel item) async {
    await SupabaseConfig.client
        .from('categories')
        .update(item.toJson())
        .eq('id', item.id);
  }

  Future<void> deleteCategory(String id) async {
    await SupabaseConfig.client.from('categories').delete().eq('id', id);
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final current = state.value;
    if (current == null || current.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= current.length) return;
    if (newIndex < 0 || newIndex > current.length) return;

    final reordered = [...current];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);

    final normalized = [
      for (var i = 0; i < reordered.length; i++) reordered[i].copyWith(order: i),
    ];

    state = AsyncValue.data(normalized);

    try {
      final updates = [
        for (final category in normalized)
          {'id': category.id, 'order': category.order},
      ];

      await SupabaseConfig.client.from('categories').upsert(updates);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

// 2. Banners
final featuredBannersProvider =
    StateNotifierProvider<
      BannersNotifier,
      AsyncValue<List<FeaturedBannerModel>>
    >((ref) {
      return BannersNotifier();
    });

class BannersNotifier
    extends StateNotifier<AsyncValue<List<FeaturedBannerModel>>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  BannersNotifier() : super(const AsyncValue.loading()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription = SupabaseConfig.client
        .from('banners')
        .stream(primaryKey: ['id'])
        .order('order')
        .listen(
          (data) {
            final list = data
                .map((e) => FeaturedBannerModel.fromJson(e))
                .toList();
            state = AsyncValue.data(list);
          },
          onError: (error, stack) {
            state = AsyncValue.error(error, stack);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addBanner(FeaturedBannerModel item) async {
    await SupabaseConfig.client.from('banners').insert(item.toJson());
  }

  Future<void> updateBanner(FeaturedBannerModel item) async {
    await SupabaseConfig.client
        .from('banners')
        .update(item.toJson())
        .eq('id', item.id);
  }

  Future<void> deleteBanner(String id) async {
    await SupabaseConfig.client.from('banners').delete().eq('id', id);
  }
}

// 3. Letters
final lettersProvider =
    StateNotifierProvider<LettersNotifier, AsyncValue<List<LetterModel>>>((
      ref,
    ) {
      return LettersNotifier();
    });

class LettersNotifier extends StateNotifier<AsyncValue<List<LetterModel>>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  LettersNotifier() : super(const AsyncValue.loading()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription = SupabaseConfig.client
        .from('letters')
        .stream(primaryKey: ['id'])
        .order('order')
        .listen(
          (data) {
            final list = data.map((e) => LetterModel.fromJson(e)).toList();
            state = AsyncValue.data(list);
          },
          onError: (error, stack) {
            state = AsyncValue.error(error, stack);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addLetter(LetterModel item) async {
    await SupabaseConfig.client.from('letters').insert(item.toJson());
  }

  Future<void> updateLetter(LetterModel item) async {
    await SupabaseConfig.client
        .from('letters')
        .update(item.toJson())
        .eq('id', item.id);
  }

  Future<void> deleteLetter(String id) async {
    await SupabaseConfig.client.from('letters').delete().eq('id', id);
  }
}

// 4. Lessons
final lessonsProvider =
    StateNotifierProvider<LessonsNotifier, AsyncValue<List<LessonModel>>>((
      ref,
    ) {
      return LessonsNotifier();
    });

class LessonsNotifier extends StateNotifier<AsyncValue<List<LessonModel>>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  LessonsNotifier() : super(const AsyncValue.loading()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription = SupabaseConfig.client
        .from('lessons')
        .stream(primaryKey: ['id'])
        .order('order')
        .listen(
          (data) {
            final list = data.map((e) => LessonModel.fromJson(e)).toList();
            state = AsyncValue.data(list);
          },
          onError: (error, stack) {
            state = AsyncValue.error(error, stack);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addLesson(LessonModel item) async {
    await SupabaseConfig.client.from('lessons').insert(item.toJson());
  }

  Future<void> updateLesson(LessonModel item) async {
    await SupabaseConfig.client
        .from('lessons')
        .update(item.toJson())
        .eq('id', item.id);
  }

  Future<void> deleteLesson(String id) async {
    await SupabaseConfig.client.from('lessons').delete().eq('id', id);
  }
}

final lessonsByCategoryProvider =
    Provider.family<AsyncValue<List<LessonModel>>, String>((ref, categoryId) {
      final lessonsAsync = ref.watch(lessonsProvider);
      return lessonsAsync.whenData(
        (lessons) => lessons.where((l) => l.categoryId == categoryId).toList(),
      );
    });

// 5. Quizzes
final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, AsyncValue<List<QuizModel>>>((ref) {
      return QuizzesNotifier();
    });

class QuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  QuizzesNotifier() : super(const AsyncValue.loading()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription = SupabaseConfig.client
        .from('quizzes')
        .stream(primaryKey: ['id'])
        .order('order')
        .listen(
          (data) {
            final list = data.map((e) => QuizModel.fromJson(e)).toList();
            state = AsyncValue.data(list);
          },
          onError: (error, stack) {
            state = AsyncValue.error(error, stack);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> addQuiz(QuizModel item) async {
    await SupabaseConfig.client.from('quizzes').insert(item.toJson());
  }

  Future<void> updateQuiz(QuizModel item) async {
    await SupabaseConfig.client
        .from('quizzes')
        .update(item.toJson())
        .eq('id', item.id);
  }

  Future<void> deleteQuiz(String id) async {
    await SupabaseConfig.client.from('quizzes').delete().eq('id', id);
  }
}

// 6. Media
final mediaFilesProvider =
    StateNotifierProvider<MediaFilesNotifier, AsyncValue<List<MediaFileModel>>>(
      (ref) {
        return MediaFilesNotifier();
      },
    );

class MediaFilesNotifier
    extends StateNotifier<AsyncValue<List<MediaFileModel>>> {
  MediaFilesNotifier() : super(const AsyncValue.data([])); // Mock for now

  // TODO: Implement Storage
  Future<void> addMediaFile(MediaFileModel file) async {}
  Future<void> deleteMediaFile(String id) async {}
}
