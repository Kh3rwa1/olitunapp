import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../repositories/content_repository.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../models/content_models.dart';

// ============== REPOSITORIES ==============
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// ============== AUTH STATE ==============
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.uid;
});

// ============== USER DATA ==============
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return userRepo.watchUser(userId);
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return authRepo.isUserAdmin(userId);
});

// ============== USER PROGRESS ==============
final userProgressProvider = StreamProvider<List<UserProgressModel>>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchAllProgress();
});

final categoryProgressProvider = Provider.family<double, String>((ref, categoryId) {
  final progress = ref.watch(userProgressProvider);
  return progress.when(
    data: (list) {
      final categoryProgress = list.where((p) => p.categoryId == categoryId).firstOrNull;
      return categoryProgress?.percent ?? 0;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// ============== CONTENT ==============
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final contentRepo = ref.watch(contentRepositoryProvider);
  return contentRepo.watchCategories();
});

final featuredBannersProvider = StreamProvider<List<FeaturedBannerModel>>((ref) {
  final contentRepo = ref.watch(contentRepositoryProvider);
  return contentRepo.watchFeaturedBanners();
});

final lettersProvider = StreamProvider<List<LetterModel>>((ref) {
  final contentRepo = ref.watch(contentRepositoryProvider);
  return contentRepo.watchLetters();
});

final lessonsByCategoryProvider = StreamProvider.family<List<LessonModel>, String>((ref, categoryId) {
  final contentRepo = ref.watch(contentRepositoryProvider);
  return contentRepo.watchLessons(categoryId);
});

final stickersProvider = StreamProvider<List<StickerModel>>((ref) {
  final contentRepo = ref.watch(contentRepositoryProvider);
  return contentRepo.watchStickers();
});

// ============== SETTINGS ==============
final themeModeProvider = StateProvider<String>((ref) => 'system');
final scriptModeProvider = StateProvider<String>((ref) => 'both');
final soundEnabledProvider = StateProvider<bool>((ref) => true);

// Initialize settings from local storage
final settingsInitProvider = FutureProvider<void>((ref) async {
  final userRepo = ref.read(userRepositoryProvider);
  
  final themeMode = await userRepo.getLocalThemeMode();
  final scriptMode = await userRepo.getLocalScriptMode();
  final soundEnabled = await userRepo.getLocalSoundEnabled();
  
  ref.read(themeModeProvider.notifier).state = themeMode;
  ref.read(scriptModeProvider.notifier).state = scriptMode;
  ref.read(soundEnabledProvider.notifier).state = soundEnabled;
});

// ============== ONBOARDING ==============
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final userRepo = ref.read(userRepositoryProvider);
  return userRepo.isOnboardingComplete();
});

// ============== GUEST MODE ==============
/// Tracks if user is in guest/exploration mode (can access limited features without login)
final guestModeProvider = StateProvider<bool>((ref) => false);

/// Check if user can access content (either authenticated or guest mode)
final canAccessContentProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isGuest = ref.watch(guestModeProvider);
  return isAuthenticated || isGuest;
});
