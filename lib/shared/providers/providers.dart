import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../../core/storage/storage_service.dart';

// ============== USER DATA (Local Storage) ==============

final userNameProvider = StateProvider<String>((ref) {
  return prefs.getString('user_name') ?? 'Learner';
});

final userStreakProvider = StateProvider<int>((ref) {
  return prefs.getInt('user_streak') ?? 0;
});

final userStarsProvider = StateProvider<int>((ref) {
  return prefs.getInt('user_stars') ?? 0;
});

final lessonsCompletedProvider = StateProvider<int>((ref) {
  return prefs.getInt('lessons_completed') ?? 0;
});

final quizzesCompletedProvider = StateProvider<int>((ref) {
  return prefs.getInt('quizzes_completed') ?? 0;
});

// User data update functions
void updateUserName(WidgetRef ref, String name) {
  prefs.setString('user_name', name);
  ref.read(userNameProvider.notifier).state = name;
}

void updateStreak(WidgetRef ref, int streak) {
  prefs.setInt('user_streak', streak);
  ref.read(userStreakProvider.notifier).state = streak;
}

void addStars(WidgetRef ref, int amount) {
  final current = ref.read(userStarsProvider);
  final newValue = current + amount;
  prefs.setInt('user_stars', newValue);
  ref.read(userStarsProvider.notifier).state = newValue;
}

void incrementLessonsCompleted(WidgetRef ref) {
  final current = ref.read(lessonsCompletedProvider);
  final newValue = current + 1;
  prefs.setInt('lessons_completed', newValue);
  ref.read(lessonsCompletedProvider.notifier).state = newValue;
}

void incrementQuizzesCompleted(WidgetRef ref) {
  final current = ref.read(quizzesCompletedProvider);
  final newValue = current + 1;
  prefs.setInt('quizzes_completed', newValue);
  ref.read(quizzesCompletedProvider.notifier).state = newValue;
}

// ============== SETTINGS (Local Storage) ==============

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

// ============== CONTENT PROVIDERS (Local Storage) ==============

// Default categories
final _defaultCategories = [
  CategoryModel(
    id: 'alphabets',
    titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
    titleLatin: 'Ol Chiki Alphabet',
    iconName: 'alphabet',
    gradientPreset: 'skyBlue',
    order: 0,
    isActive: true,
    totalLessons: 30,
  ),
  CategoryModel(
    id: 'numbers',
    titleOlChiki: 'ᱮᱞᱠᱷᱟ',
    titleLatin: 'Numbers',
    iconName: 'numbers',
    gradientPreset: 'peach',
    order: 1,
    isActive: true,
    totalLessons: 10,
  ),
  CategoryModel(
    id: 'words',
    titleOlChiki: 'ᱯᱟᱹᱨᱥᱤ',
    titleLatin: 'Common Words',
    iconName: 'words',
    gradientPreset: 'mint',
    order: 2,
    isActive: true,
    totalLessons: 20,
  ),
  CategoryModel(
    id: 'phrases',
    titleOlChiki: 'ᱛᱮᱞᱟ ᱯᱟᱹᱨᱥᱤ',
    titleLatin: 'Phrases',
    iconName: 'stories',
    gradientPreset: 'sunset',
    order: 3,
    isActive: true,
    totalLessons: 15,
  ),
];

// Categories Provider
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((
      ref,
    ) {
      return CategoriesNotifier();
    });

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  CategoriesNotifier() : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  void _loadCategories() {
    try {
      final stored = prefs.getString('categories');
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        final categories = decoded
            .map((e) => CategoryModel.fromJson(e))
            .toList();
        state = AsyncValue.data(categories);
      } else {
        state = AsyncValue.data(_defaultCategories);
        _saveCategories(_defaultCategories);
      }
    } catch (e) {
      state = AsyncValue.data(_defaultCategories);
    }
  }

  void _saveCategories(List<CategoryModel> categories) {
    final encoded = jsonEncode(categories.map((e) => e.toJson()).toList());
    prefs.setString('categories', encoded);
  }

  void add(CategoryModel item) {
    final current = state.value ?? [];
    final updated = [...current, item];
    _saveCategories(updated);
    state = AsyncValue.data(updated);
  }

  void update(CategoryModel item) {
    final current = state.value ?? [];
    final updated = current.map((e) => e.id == item.id ? item : e).toList();
    _saveCategories(updated);
    state = AsyncValue.data(updated);
  }

  void delete(String id) {
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != id).toList();
    _saveCategories(updated);
    state = AsyncValue.data(updated);
  }

  void reorder(List<CategoryModel> items) {
    _saveCategories(items);
    state = AsyncValue.data(items);
  }

  // Aliases for admin screens
  void addCategory(CategoryModel item) => add(item);
  void updateCategory(CategoryModel item) => update(item);
  void deleteCategory(String id) => delete(id);

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final current = state.value ?? [];
    final updated = [...current];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    // Update order values
    for (int i = 0; i < updated.length; i++) {
      updated[i] = CategoryModel(
        id: updated[i].id,
        titleOlChiki: updated[i].titleOlChiki,
        titleLatin: updated[i].titleLatin,
        iconName: updated[i].iconName,
        iconUrl: updated[i].iconUrl,
        gradientPreset: updated[i].gradientPreset,
        order: i,
        isActive: updated[i].isActive,
        totalLessons: updated[i].totalLessons,
        description: updated[i].description,
      );
    }
    _saveCategories(updated);
    state = AsyncValue.data(updated);
  }
}

// Banners Provider
final bannersProvider =
    StateNotifierProvider<
      BannersNotifier,
      AsyncValue<List<FeaturedBannerModel>>
    >((ref) {
      return BannersNotifier();
    });

class BannersNotifier
    extends StateNotifier<AsyncValue<List<FeaturedBannerModel>>> {
  BannersNotifier() : super(const AsyncValue.loading()) {
    _loadBanners();
  }

  void _loadBanners() {
    try {
      final stored = prefs.getString('banners');
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        final banners = decoded
            .map((e) => FeaturedBannerModel.fromJson(e))
            .toList();
        state = AsyncValue.data(banners);
      } else {
        state = AsyncValue.data([
          FeaturedBannerModel(
            id: '1',
            title: 'Start Your Journey',
            subtitle: 'Learn Ol Chiki alphabet today',
            gradientPreset: 'mint',
            order: 0,
            isActive: true,
          ),
        ]);
      }
    } catch (e) {
      state = AsyncValue.data([]);
    }
  }

  void _saveBanners(List<FeaturedBannerModel> banners) {
    final encoded = jsonEncode(banners.map((e) => e.toJson()).toList());
    prefs.setString('banners', encoded);
  }

  void add(FeaturedBannerModel item) {
    final current = state.value ?? [];
    final updated = [...current, item];
    _saveBanners(updated);
    state = AsyncValue.data(updated);
  }

  void update(FeaturedBannerModel item) {
    final current = state.value ?? [];
    final updated = current.map((e) => e.id == item.id ? item : e).toList();
    _saveBanners(updated);
    state = AsyncValue.data(updated);
  }

  void delete(String id) {
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != id).toList();
    _saveBanners(updated);
    state = AsyncValue.data(updated);
  }

  // Aliases for admin screens
  void addBanner(FeaturedBannerModel item) => add(item);
  void updateBanner(FeaturedBannerModel item) => update(item);
  void deleteBanner(String id) => delete(id);
}

// Alias for backward compatibility
final featuredBannersProvider = bannersProvider;

// Letters Provider
final lettersProvider =
    StateNotifierProvider<LettersNotifier, AsyncValue<List<LetterModel>>>((
      ref,
    ) {
      return LettersNotifier();
    });

class LettersNotifier extends StateNotifier<AsyncValue<List<LetterModel>>> {
  LettersNotifier() : super(const AsyncValue.loading()) {
    _loadLetters();
  }

  void _loadLetters() {
    try {
      final stored = prefs.getString('letters');
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        final letters = decoded.map((e) => LetterModel.fromJson(e)).toList();
        state = AsyncValue.data(letters);
      } else {
        // Default Ol Chiki letters
        state = AsyncValue.data([
          LetterModel(
            id: '1',
            charOlChiki: 'ᱚ',
            transliterationLatin: 'a',
            order: 1,
            isActive: true,
          ),
          LetterModel(
            id: '2',
            charOlChiki: 'ᱛ',
            transliterationLatin: 'at',
            order: 2,
            isActive: true,
          ),
          LetterModel(
            id: '3',
            charOlChiki: 'ᱜ',
            transliterationLatin: 'ag',
            order: 3,
            isActive: true,
          ),
          LetterModel(
            id: '4',
            charOlChiki: 'ᱝ',
            transliterationLatin: 'ang',
            order: 4,
            isActive: true,
          ),
          LetterModel(
            id: '5',
            charOlChiki: 'ᱞ',
            transliterationLatin: 'al',
            order: 5,
            isActive: true,
          ),
          LetterModel(
            id: '6',
            charOlChiki: 'ᱟ',
            transliterationLatin: 'la',
            order: 6,
            isActive: true,
          ),
          LetterModel(
            id: '7',
            charOlChiki: 'ᱠ',
            transliterationLatin: 'ak',
            order: 7,
            isActive: true,
          ),
          LetterModel(
            id: '8',
            charOlChiki: 'ᱡ',
            transliterationLatin: 'aj',
            order: 8,
            isActive: true,
          ),
        ]);
      }
    } catch (e) {
      state = AsyncValue.data([]);
    }
  }

  void _saveLetters(List<LetterModel> letters) {
    final encoded = jsonEncode(letters.map((e) => e.toJson()).toList());
    prefs.setString('letters', encoded);
  }

  void add(LetterModel item) {
    final current = state.value ?? [];
    final updated = [...current, item];
    _saveLetters(updated);
    state = AsyncValue.data(updated);
  }

  void update(LetterModel item) {
    final current = state.value ?? [];
    final updated = current.map((e) => e.id == item.id ? item : e).toList();
    _saveLetters(updated);
    state = AsyncValue.data(updated);
  }

  void delete(String id) {
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != id).toList();
    _saveLetters(updated);
    state = AsyncValue.data(updated);
  }

  // Aliases for admin screens
  void addLetter(LetterModel item) => add(item);
  void updateLetter(LetterModel item) => update(item);
  void deleteLetter(String id) => delete(id);
}

// Lessons Provider
final lessonsProvider =
    StateNotifierProvider<LessonsNotifier, AsyncValue<List<LessonModel>>>((
      ref,
    ) {
      return LessonsNotifier();
    });

class LessonsNotifier extends StateNotifier<AsyncValue<List<LessonModel>>> {
  LessonsNotifier() : super(const AsyncValue.loading()) {
    _loadLessons();
  }

  void _loadLessons() {
    try {
      final stored = prefs.getString('lessons');
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        final lessons = decoded.map((e) => LessonModel.fromJson(e)).toList();
        state = AsyncValue.data(lessons);
      } else {
        // Default lessons
        state = AsyncValue.data([
          LessonModel(
            id: 'alphabets_1',
            categoryId: 'alphabets',
            titleOlChiki: 'ᱯᱟᱹᱦᱤᱞ ᱯᱟᱹᱴ',
            titleLatin: 'First Lesson',
            level: 'beginner',
            order: 0,
            isActive: true,
            estimatedMinutes: 5,
          ),
          LessonModel(
            id: 'alphabets_2',
            categoryId: 'alphabets',
            titleOlChiki: 'ᱵᱟᱨᱭᱟ ᱯᱟᱹᱴ',
            titleLatin: 'Second Lesson',
            level: 'beginner',
            order: 1,
            isActive: true,
            estimatedMinutes: 5,
          ),
          LessonModel(
            id: 'numbers_1',
            categoryId: 'numbers',
            titleOlChiki: 'ᱮᱞᱠᱷᱟ ᱯᱟᱹᱴ',
            titleLatin: 'Numbers Intro',
            level: 'beginner',
            order: 0,
            isActive: true,
            estimatedMinutes: 5,
          ),
        ]);
      }
    } catch (e) {
      state = AsyncValue.data([]);
    }
  }

  void _saveLessons(List<LessonModel> lessons) {
    final encoded = jsonEncode(lessons.map((e) => e.toJson()).toList());
    prefs.setString('lessons', encoded);
  }

  void add(LessonModel item) {
    final current = state.value ?? [];
    final updated = [...current, item];
    _saveLessons(updated);
    state = AsyncValue.data(updated);
  }

  void update(LessonModel item) {
    final current = state.value ?? [];
    final updated = current.map((e) => e.id == item.id ? item : e).toList();
    _saveLessons(updated);
    state = AsyncValue.data(updated);
  }

  void delete(String id) {
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != id).toList();
    _saveLessons(updated);
    state = AsyncValue.data(updated);
  }

  // Aliases for admin screens (async for await compatibility)
  Future<void> addLesson(LessonModel item) async => add(item);
  Future<void> updateLesson(LessonModel item) async => update(item);
  Future<void> deleteLesson(String id) async => delete(id);
}

// Quizzes Provider
final quizzesProvider =
    StateNotifierProvider<QuizzesNotifier, AsyncValue<List<QuizModel>>>((ref) {
      return QuizzesNotifier();
    });

class QuizzesNotifier extends StateNotifier<AsyncValue<List<QuizModel>>> {
  QuizzesNotifier() : super(const AsyncValue.loading()) {
    _loadQuizzes();
  }

  void _loadQuizzes() {
    try {
      final stored = prefs.getString('quizzes');
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        final quizzes = decoded.map((e) => QuizModel.fromJson(e)).toList();
        state = AsyncValue.data(quizzes);
      } else {
        state = AsyncValue.data([]);
      }
    } catch (e) {
      state = AsyncValue.data([]);
    }
  }

  void _saveQuizzes(List<QuizModel> quizzes) {
    final encoded = jsonEncode(quizzes.map((e) => e.toJson()).toList());
    prefs.setString('quizzes', encoded);
  }

  void add(QuizModel item) {
    final current = state.value ?? [];
    final updated = [...current, item];
    _saveQuizzes(updated);
    state = AsyncValue.data(updated);
  }

  void update(QuizModel item) {
    final current = state.value ?? [];
    final updated = current.map((e) => e.id == item.id ? item : e).toList();
    _saveQuizzes(updated);
    state = AsyncValue.data(updated);
  }

  void delete(String id) {
    final current = state.value ?? [];
    final updated = current.where((e) => e.id != id).toList();
    _saveQuizzes(updated);
    state = AsyncValue.data(updated);
  }

  // Aliases for admin screens (async for await compatibility)
  Future<void> addQuiz(QuizModel item) async => add(item);
  Future<void> updateQuiz(QuizModel item) async => update(item);
  Future<void> deleteQuiz(String id) async => delete(id);
}

// Filtered lessons by category
final lessonsByCategoryProvider =
    Provider.family<AsyncValue<List<LessonModel>>, String>((ref, categoryId) {
      final lessonsAsync = ref.watch(lessonsProvider);
      return lessonsAsync.when(
        data: (lessons) => AsyncValue.data(
          lessons.where((l) => l.categoryId == categoryId).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

// ============== USER PROFILE PROVIDER (Local) ==============

final userProfileProvider = Provider<AsyncValue<UserProfileLocal?>>((ref) {
  final name = ref.watch(userNameProvider);
  final streak = ref.watch(userStreakProvider);
  final stars = ref.watch(userStarsProvider);
  final lessons = ref.watch(lessonsCompletedProvider);
  final quizzes = ref.watch(quizzesCompletedProvider);

  return AsyncValue.data(
    UserProfileLocal(
      displayName: name,
      stats: UserStatsLocal(
        streak: streak,
        stars: stars,
        totalLessonsCompleted: lessons,
        totalQuizzesCompleted: quizzes,
      ),
    ),
  );
});

class UserProfileLocal {
  final String displayName;
  final UserStatsLocal stats;

  UserProfileLocal({required this.displayName, required this.stats});
}

class UserStatsLocal {
  final int streak;
  final int stars;
  final int totalLessonsCompleted;
  final int totalQuizzesCompleted;

  UserStatsLocal({
    required this.streak,
    required this.stars,
    required this.totalLessonsCompleted,
    required this.totalQuizzesCompleted,
  });
}

// ============== CONTENT SEEDING ==============

Future<void> seedAppContent(WidgetRef ref) async {
  final categoriesNotifier = ref.read(categoriesProvider.notifier);
  final lettersNotifier = ref.read(lettersProvider.notifier);
  final lessonsNotifier = ref.read(lessonsProvider.notifier);

  // 1. Add Alphabets Category
  final alphabetsId = 'cat_alphabets_${DateTime.now().millisecondsSinceEpoch}';
  categoriesNotifier.add(
    CategoryModel(
      id: alphabetsId,
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
      titleLatin: 'Alphabets',
      iconName: 'alphabet',
      gradientPreset: 'skyBlue',
      order: 0,
      isActive: true,
      totalLessons: 5,
    ),
  );

  // 2. Add sample letters
  final letters = [
    ['ᱚ', 'a'],
    ['ᱛ', 'at'],
    ['ᱜ', 'ag'],
    ['ᱝ', 'ang'],
    ['ᱞ', 'al'],
  ];

  for (int i = 0; i < letters.length; i++) {
    lettersNotifier.add(
      LetterModel(
        id: 'letter_${i}_${DateTime.now().microsecondsSinceEpoch}',
        charOlChiki: letters[i][0],
        transliterationLatin: letters[i][1],
        order: i,
        isActive: true,
      ),
    );
  }

  // 3. Add sample lessons
  final lessonTitles = [
    'Basics of Ol Chiki',
    'Vowels I',
    'Consonants I',
    'Vowels II',
    'Consonants II',
  ];

  for (int i = 0; i < lessonTitles.length; i++) {
    await lessonsNotifier.addLesson(
      LessonModel(
        id: 'lesson_${i}_${DateTime.now().microsecondsSinceEpoch}',
        categoryId: alphabetsId,
        titleOlChiki: 'ᱯᱟᱹᱴ $i',
        titleLatin: lessonTitles[i],
        level: 'beginner',
        order: i,
        isActive: true,
        estimatedMinutes: 5,
        blocks: [],
      ),
    );
  }

  // 4. Add Numbers Category
  final numbersId = 'cat_numbers_${DateTime.now().millisecondsSinceEpoch}';
  categoriesNotifier.add(
    CategoryModel(
      id: numbersId,
      titleOlChiki: 'ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers',
      iconName: 'numbers',
      gradientPreset: 'peach',
      order: 1,
      isActive: true,
      totalLessons: 3,
    ),
  );

  // 5. Add Phrases Category
  categoriesNotifier.add(
    CategoryModel(
      id: 'cat_phrases_${DateTime.now().millisecondsSinceEpoch}',
      titleOlChiki: 'ᱛᱮᱞᱟ ᱯᱟᱹᱨᱥᱤ',
      titleLatin: 'Greetings',
      iconName: 'words',
      gradientPreset: 'mint',
      order: 2,
      isActive: true,
      totalLessons: 4,
    ),
  );
}
