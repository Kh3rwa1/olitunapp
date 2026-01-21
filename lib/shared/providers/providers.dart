import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../../main.dart';

// ============== LOCAL USER DATA ==============
/// User's display name (stored locally)
final userNameProvider = StateProvider<String>((ref) {
  return prefs.getString('user_name') ?? 'Learner';
});

/// Update user name and persist
void updateUserName(WidgetRef ref, String name) {
  prefs.setString('user_name', name);
  ref.read(userNameProvider.notifier).state = name;
}

// ============== USER STATS (Local Storage) ==============
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

/// Update streak and persist
void updateStreak(WidgetRef ref, int streak) {
  prefs.setInt('user_streak', streak);
  ref.read(userStreakProvider.notifier).state = streak;
}

/// Add stars and persist
void addStars(WidgetRef ref, int amount) {
  final current = ref.read(userStarsProvider);
  final newValue = current + amount;
  prefs.setInt('user_stars', newValue);
  ref.read(userStarsProvider.notifier).state = newValue;
}

/// Increment lessons completed
void incrementLessonsCompleted(WidgetRef ref) {
  final current = ref.read(lessonsCompletedProvider);
  final newValue = current + 1;
  prefs.setInt('lessons_completed', newValue);
  ref.read(lessonsCompletedProvider.notifier).state = newValue;
}

/// Increment quizzes completed
void incrementQuizzesCompleted(WidgetRef ref) {
  final current = ref.read(quizzesCompletedProvider);
  final newValue = current + 1;
  prefs.setInt('quizzes_completed', newValue);
  ref.read(quizzesCompletedProvider.notifier).state = newValue;
}

// ============== CATEGORY PROGRESS (Local Storage) ==============
final categoryProgressProvider = StateProvider.family<double, String>((ref, categoryId) {
  return prefs.getDouble('progress_$categoryId') ?? 0.0;
});

/// Update category progress
void updateCategoryProgress(WidgetRef ref, String categoryId, double progress) {
  prefs.setDouble('progress_$categoryId', progress);
  ref.invalidate(categoryProgressProvider(categoryId));
}

// ============== CONTENT PROVIDERS (Local Storage + StateNotifier) ==============

// Categories Provider with persistence
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, List<CategoryModel>>((ref) {
  return CategoriesNotifier();
});

class CategoriesNotifier extends StateNotifier<List<CategoryModel>> {
  CategoriesNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final stored = prefs.getString('categories_data');
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        state = decoded.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _loadDefaults();
      }
    } else {
      _loadDefaults();
    }
  }

  void _loadDefaults() {
    state = [
      CategoryModel(
        id: 'alphabets',
        titleLatin: 'Alphabets',
        titleOlChiki: 'ᱚᱠᱷᱚᱨ',
        description: 'Learn Ol Chiki letters',
        iconName: 'alphabet',
        gradientPreset: 'skyBlue',
        order: 1,
        isActive: true,
      ),
      CategoryModel(
        id: 'numbers',
        titleLatin: 'Numbers',
        titleOlChiki: 'ᱮᱞ',
        description: 'Learn to count in Santali',
        iconName: 'numbers',
        gradientPreset: 'peach',
        order: 2,
        isActive: true,
      ),
      CategoryModel(
        id: 'words',
        titleLatin: 'Words',
        titleOlChiki: 'ᱨᱚᱲ',
        description: 'Common words and vocabulary',
        iconName: 'words',
        gradientPreset: 'mint',
        order: 3,
        isActive: true,
      ),
      CategoryModel(
        id: 'phrases',
        titleLatin: 'Phrases',
        titleOlChiki: 'ᱵᱟᱠᱭᱟ',
        description: 'Daily phrases and sentences',
        iconName: 'stories',
        gradientPreset: 'purple',
        order: 4,
        isActive: true,
      ),
    ];
    _saveToStorage();
  }

  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('categories_data', encoded);
  }

  void addCategory(CategoryModel category) {
    state = [...state, category];
    _saveToStorage();
  }

  void updateCategory(CategoryModel category) {
    state = state.map((c) => c.id == category.id ? category : c).toList();
    _saveToStorage();
  }

  void deleteCategory(String id) {
    state = state.where((c) => c.id != id).toList();
    _saveToStorage();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    final item = state[oldIndex];
    final newList = List<CategoryModel>.from(state);
    newList.removeAt(oldIndex);
    newList.insert(newIndex < oldIndex ? newIndex : newIndex - 1, item);
    state = newList.asMap().entries.map((e) => e.value.copyWith(order: e.key)).toList();
    _saveToStorage();
  }
}

// Featured Banners Provider with persistence
final featuredBannersProvider = StateNotifierProvider<BannersNotifier, List<FeaturedBannerModel>>((ref) {
  return BannersNotifier();
});

class BannersNotifier extends StateNotifier<List<FeaturedBannerModel>> {
  BannersNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final stored = prefs.getString('banners_data');
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        state = decoded.map((e) => FeaturedBannerModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _loadDefaults();
      }
    } else {
      _loadDefaults();
    }
  }

  void _loadDefaults() {
    state = [
      FeaturedBannerModel(
        id: '1',
        title: 'Start Your Journey',
        subtitle: 'Learn Ol Chiki alphabet today',
        gradientPreset: 'skyBlue',
        targetRoute: '/lessons/category/alphabets',
        order: 1,
        isActive: true,
      ),
    ];
    _saveToStorage();
  }

  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('banners_data', encoded);
  }

  void addBanner(FeaturedBannerModel banner) {
    state = [...state, banner];
    _saveToStorage();
  }

  void updateBanner(FeaturedBannerModel banner) {
    state = state.map((b) => b.id == banner.id ? banner : b).toList();
    _saveToStorage();
  }

  void deleteBanner(String id) {
    state = state.where((b) => b.id != id).toList();
    _saveToStorage();
  }
}

// Letters Provider with persistence
final lettersProvider = StateNotifierProvider<LettersNotifier, List<LetterModel>>((ref) {
  return LettersNotifier();
});

class LettersNotifier extends StateNotifier<List<LetterModel>> {
  LettersNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final stored = prefs.getString('letters_data');
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        state = decoded.map((e) => LetterModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _loadDefaults();
      }
    } else {
      _loadDefaults();
    }
  }

  void _loadDefaults() {
    // Complete Ol Chiki alphabet
    state = [
      LetterModel(id: '1', charOlChiki: 'ᱚ', transliterationLatin: 'a', order: 1, isActive: true),
      LetterModel(id: '2', charOlChiki: 'ᱛ', transliterationLatin: 'at', order: 2, isActive: true),
      LetterModel(id: '3', charOlChiki: 'ᱜ', transliterationLatin: 'ag', order: 3, isActive: true),
      LetterModel(id: '4', charOlChiki: 'ᱝ', transliterationLatin: 'ang', order: 4, isActive: true),
      LetterModel(id: '5', charOlChiki: 'ᱞ', transliterationLatin: 'al', order: 5, isActive: true),
      LetterModel(id: '6', charOlChiki: 'ᱟ', transliterationLatin: 'la', order: 6, isActive: true),
      LetterModel(id: '7', charOlChiki: 'ᱠ', transliterationLatin: 'ak', order: 7, isActive: true),
      LetterModel(id: '8', charOlChiki: 'ᱡ', transliterationLatin: 'aj', order: 8, isActive: true),
      LetterModel(id: '9', charOlChiki: 'ᱢ', transliterationLatin: 'am', order: 9, isActive: true),
      LetterModel(id: '10', charOlChiki: 'ᱣ', transliterationLatin: 'aw', order: 10, isActive: true),
      LetterModel(id: '11', charOlChiki: 'ᱤ', transliterationLatin: 'i', order: 11, isActive: true),
      LetterModel(id: '12', charOlChiki: 'ᱥ', transliterationLatin: 'is', order: 12, isActive: true),
    ];
    _saveToStorage();
  }

  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('letters_data', encoded);
  }

  void addLetter(LetterModel letter) {
    state = [...state, letter];
    _saveToStorage();
  }

  void updateLetter(LetterModel letter) {
    state = state.map((l) => l.id == letter.id ? letter : l).toList();
    _saveToStorage();
  }

  void deleteLetter(String id) {
    state = state.where((l) => l.id != id).toList();
    _saveToStorage();
  }
}

// Lessons Provider with persistence
final lessonsProvider = StateNotifierProvider<LessonsNotifier, List<LessonModel>>((ref) {
  return LessonsNotifier();
});

class LessonsNotifier extends StateNotifier<List<LessonModel>> {
  LessonsNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final stored = prefs.getString('lessons_data');
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        state = decoded.map((e) => LessonModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _loadDefaults();
      }
    } else {
      _loadDefaults();
    }
  }

  void _loadDefaults() {
    state = [
      LessonModel(
        id: 'alphabets_1',
        categoryId: 'alphabets',
        titleLatin: 'Introduction to Ol Chiki',
        titleOlChiki: 'ᱮᱱᱮᱡ',
        description: 'Get started with basics',
        order: 1,
        isActive: true,
        isPremium: false,
      ),
      LessonModel(
        id: 'alphabets_2',
        categoryId: 'alphabets',
        titleLatin: 'First Letters',
        titleOlChiki: 'ᱚᱵᱷᱭᱟᱥ',
        description: 'Learn the first 5 letters',
        order: 2,
        isActive: true,
        isPremium: false,
      ),
      LessonModel(
        id: 'numbers_1',
        categoryId: 'numbers',
        titleLatin: 'Counting Basics',
        titleOlChiki: 'ᱮᱞ',
        description: 'Learn numbers 1-10',
        order: 1,
        isActive: true,
        isPremium: false,
      ),
    ];
    _saveToStorage();
  }

  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('lessons_data', encoded);
  }

  List<LessonModel> getLessonsByCategory(String categoryId) {
    return state.where((l) => l.categoryId == categoryId).toList();
  }

  void addLesson(LessonModel lesson) {
    state = [...state, lesson];
    _saveToStorage();
  }

  void updateLesson(LessonModel lesson) {
    state = state.map((l) => l.id == lesson.id ? lesson : l).toList();
    _saveToStorage();
  }

  void deleteLesson(String id) {
    state = state.where((l) => l.id != id).toList();
    _saveToStorage();
  }
}

// Helper provider to get lessons by category
final lessonsByCategoryProvider = Provider.family<List<LessonModel>, String>((ref, categoryId) {
  final lessons = ref.watch(lessonsProvider);
  return lessons.where((l) => l.categoryId == categoryId).toList();
});

// Quizzes Provider with persistence
final quizzesProvider = StateNotifierProvider<QuizzesNotifier, List<QuizModel>>((ref) {
  return QuizzesNotifier();
});

class QuizzesNotifier extends StateNotifier<List<QuizModel>> {
  QuizzesNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final stored = prefs.getString('quizzes_data');
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        state = decoded.map((e) => QuizModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _loadDefaults();
      }
    } else {
      _loadDefaults();
    }
  }

  void _loadDefaults() {
    state = [
      QuizModel(
        id: 'quiz_1',
        categoryId: 'alphabets',
        title: 'Alphabet Quiz',
        level: 'beginner',
        order: 1,
        isActive: true,
        passingScore: 70,
        questions: [
          QuizQuestion(
            promptOlChiki: 'ᱚ',
            promptLatin: 'What letter is this?',
            optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'],
            optionsLatin: ['a', 'at', 'ag', 'ang'],
            correctIndex: 0,
          ),
        ],
      ),
    ];
    _saveToStorage();
  }

  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('quizzes_data', encoded);
  }

  void addQuiz(QuizModel quiz) {
    state = [...state, quiz];
    _saveToStorage();
  }

  void updateQuiz(QuizModel quiz) {
    state = state.map((q) => q.id == quiz.id ? quiz : q).toList();
    _saveToStorage();
  }

  void deleteQuiz(String id) {
    state = state.where((q) => q.id != id).toList();
    _saveToStorage();
  }
}

// Media Files Provider with persistence
final mediaFilesProvider = StateNotifierProvider<MediaFilesNotifier, List<MediaFileModel>>((ref) {
  return MediaFilesNotifier();
});

class MediaFilesNotifier extends StateNotifier<List<MediaFileModel>> {
  MediaFilesNotifier() : super([]) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final stored = prefs.getString('media_files_data');
    if (stored != null) {
      try {
        final List<dynamic> decoded = jsonDecode(stored);
        state = decoded.map((e) => MediaFileModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  void _saveToStorage() {
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    prefs.setString('media_files_data', encoded);
  }

  void addMediaFile(MediaFileModel file) {
    state = [...state, file];
    _saveToStorage();
  }

  void deleteMediaFile(String id) {
    state = state.where((f) => f.id != id).toList();
    _saveToStorage();
  }

  List<MediaFileModel> getByType(String type) {
    if (type == 'all') return state;
    return state.where((f) => f.type == type).toList();
  }
}

final stickersProvider = StateProvider<List<StickerModel>>((ref) {
  return [];
});

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

/// Update theme mode
void updateThemeMode(WidgetRef ref, String mode) {
  prefs.setString('theme_mode', mode);
  ref.read(themeModeProvider.notifier).state = mode;
}

/// Update script mode
void updateScriptMode(WidgetRef ref, String mode) {
  prefs.setString('script_mode', mode);
  ref.read(scriptModeProvider.notifier).state = mode;
}

/// Toggle sound
void toggleSound(WidgetRef ref) {
  final current = ref.read(soundEnabledProvider);
  prefs.setBool('sound_enabled', !current);
  ref.read(soundEnabledProvider.notifier).state = !current;
}

// ============== ONBOARDING ==============
final onboardingCompleteProvider = StateProvider<bool>((ref) {
  return prefs.getBool('onboarding_complete') ?? false;
});

void completeOnboarding(WidgetRef ref) {
  prefs.setBool('onboarding_complete', true);
  ref.read(onboardingCompleteProvider.notifier).state = true;
}
