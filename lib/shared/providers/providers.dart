import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../../core/storage/storage_service.dart';
import '../../core/api/api_service.dart'; // Import API Service
import '../../features/rhymes/domain/rhyme_model.dart';
import '../../features/rhymes/domain/rhyme_category_model.dart';
import '../../core/auth/stack_auth_service.dart';
import '../../features/auth/data/auth_repository.dart';
import 'dart:convert';
import 'progress_provider.dart';

// ============== APP SETTINGS (from API) ==============

final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.get('/settings.php');
    if (response is Map<String, dynamic>) return response;
    return <String, dynamic>{};
  } catch (e) {
    debugPrint('Failed to load app settings: $e');
    return <String, dynamic>{};
  }
});

final onboardingVideoUrlProvider = Provider<String?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.whenOrNull(
    data: (data) => data['onboarding_video_url'] as String?,
  );
});

// ============== AUTH STATE ==============

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  try {
    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getToken();
    return token != null;
  } catch (_) {
    return false;
  }
});

// ============== USER DATA (Local Storage) ==============

final userNameProvider = StateProvider<String>((ref) {
  return prefs.getString('user_name') ?? 'Learner';
});

// Derived from progressProvider — single source of truth
final userStarsProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).totalStars;
});

final lessonsCompletedProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).lessonsCompletedCount;
});

final quizzesCompletedProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).quizzesCompletedCount;
});

// User data update functions
Future<void> updateUserName(WidgetRef ref, String name) async {
  prefs.setString('user_name', name);
  ref.read(userNameProvider.notifier).state = name;

  // Sync to cloud if logged in
  try {
    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getToken();
    if (token != null) {
      await authRepo.updateDisplayName(name);
    }
  } catch (e) {
    debugPrint('Failed to sync user name to cloud: $e');
  }
}

/// Synchronize profile name from Stack Auth to local storage
Future<void> syncProfileName(WidgetRef ref) async {
  try {
    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getToken();
    if (token == null) return;

    final profile = await authRepo.getMe();
    final cloudName = profile['display_name'] as String?;

    if (cloudName != null && cloudName.isNotEmpty) {
      final localName = prefs.getString('user_name');
      if (localName != cloudName) {
        prefs.setString('user_name', cloudName);
        ref.read(userNameProvider.notifier).state = cloudName;
      }
    } else {
      // If cloud name is empty but local name exists, push local name to cloud
      final localName = prefs.getString('user_name');
      if (localName != null && localName != 'Learner') {
        await authRepo.updateDisplayName(localName);
      }
    }
  } catch (e) {
    debugPrint('Profile sync failed: $e');
  }
}

// Member since date — set on first launch
final memberSinceProvider = StateProvider<String>((ref) {
  final stored = prefs.getString('member_since');
  if (stored != null) return stored;
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  prefs.setString('member_since', dateStr);
  return dateStr;
});

// Avatar emoji — user-selectable, persisted
final userAvatarEmojiProvider = StateProvider<String>((ref) {
  return prefs.getString('user_avatar_emoji') ?? '';
});

void updateAvatarEmoji(WidgetRef ref, String emoji) {
  prefs.setString('user_avatar_emoji', emoji);
  ref.read(userAvatarEmojiProvider.notifier).state = emoji;
}

// Avatar color index — user-selectable, persisted
final userAvatarColorIndexProvider = StateProvider<int>((ref) {
  return prefs.getInt('user_avatar_color') ?? 0;
});

void updateAvatarColorIndex(WidgetRef ref, int index) {
  prefs.setInt('user_avatar_color', index);
  ref.read(userAvatarColorIndexProvider.notifier).state = index;
}

// Avatar color palettes (available for selection)
const avatarPalettes = [
  [Color(0xFF1EE088), Color(0xFF00C767)], // Green
  [Color(0xFF1CB0F6), Color(0xFF1899D6)], // Blue
  [Color(0xFFFF9600), Color(0xFFD37D00)], // Orange
  [Color(0xFFCE82FF), Color(0xFFAF67E9)], // Purple
  [Color(0xFFFF4B4B), Color(0xFFD33131)], // Red
  [Color(0xFFFFC800), Color(0xFFE5A100)], // Yellow
  [Color(0xFF00E5FF), Color(0xFF00B8D4)], // Cyan
  [Color(0xFFFF4081), Color(0xFFF50057)], // Pink
];

// Current avatar colors (computed from index)
final userAvatarColorsProvider = Provider<List<Color>>((ref) {
  final index = ref.watch(userAvatarColorIndexProvider);
  return avatarPalettes[index.clamp(0, avatarPalettes.length - 1)];
});

// ============== SETTINGS (Local Storage) ==============

// Shell tab index — allows child screens to switch tabs
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

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

// Default categories removed - fetched from API

// ============== AUTH PROVIDERS (Stack Auth) ==============

final stackAuthServiceProvider = Provider<StackAuthService>((ref) {
  // Use environment variables or secure storage in production
  return StackAuthService(
    projectId: 'ec138b74-cdb7-4c55-a7e0-a59d68561548',
    publishableKey: 'pck_2v7xw0j8hbgj6tqec50m4mev9yhvw195v8c753y7n6nw0',
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(stackAuthServiceProvider));
});

final progressProvider =
    StateNotifierProvider<ProgressNotifier, UserProgressData>((ref) {
      final authRepo = ref.watch(authRepositoryProvider);
      return ProgressNotifier(authRepository: authRepo);
    });

// Categories Provider
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, AsyncValue<List<CategoryModel>>>((
      ref,
    ) {
      return CategoriesNotifier(ref);
    });

class CategoriesNotifier
    extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  CategoriesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadCategories();
  }

  final Ref ref;

  static final List<CategoryModel> _seedCategories = [
    CategoryModel(
      id: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
      titleLatin: 'Alphabet',
      iconName: 'abc',
      gradientPreset: 'skyBlue',
      order: 0,
      totalLessons: 6,
      description: 'Learn the Ol Chiki script letters',
    ),
    CategoryModel(
      id: 'seed_numbers',
      titleOlChiki: 'ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers',
      iconName: 'pin',
      gradientPreset: 'sunset',
      order: 1,
      totalLessons: 4,
      description: 'Learn Santali numbers and counting',
    ),
    CategoryModel(
      id: 'seed_words',
      titleOlChiki: 'ᱨᱚᱲ',
      titleLatin: 'Words',
      iconName: 'menu_book',
      gradientPreset: 'forest',
      order: 2,
      totalLessons: 5,
      description: 'Build your Santali vocabulary',
    ),
    CategoryModel(
      id: 'seed_sentences',
      titleOlChiki: 'ᱣᱟᱠᱭ',
      titleLatin: 'Sentences',
      iconName: 'chat_bubble',
      gradientPreset: 'ocean',
      order: 3,
      totalLessons: 4,
      description: 'Form sentences in Santali',
    ),
  ];

  Future<void> _loadCategories() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/categories.php');
      final list = (data as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } catch (e) {
      // Fallback to local seed data when API is unreachable
      state = AsyncValue.data(_seedCategories);
    }
  }

  Future<void> add(CategoryModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/categories.php', item.toJson());
      await _loadCategories(); // Refresh list
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(CategoryModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/categories.php', item.toJson());
      await _loadCategories();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/categories.php', params: {'id': id});
      await _loadCategories();
    } catch (e) {
      // Handle error
    }
  }

  // Aliases for admin screens
  void addCategory(CategoryModel item) => add(item);
  void updateCategory(CategoryModel item) => update(item);
  void deleteCategory(String id) => delete(id);

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final current = state.value ?? [];
    if (oldIndex < 0 ||
        oldIndex >= current.length ||
        newIndex < 0 ||
        newIndex >= current.length) {
      return;
    }

    final updated = [...current];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    // Update order values locally first
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(
        order: i,
      ); // Assuming copyWith exists, or recreate
    }
    state = AsyncValue.data(updated);

    // TODO: Implement bulk reorder API or individual updates
  }

  Future<void> seed() async {
    state = const AsyncValue.loading();
    _loadCategories();
  }
}

// Banners Provider
final bannersProvider =
    StateNotifierProvider<
      BannersNotifier,
      AsyncValue<List<FeaturedBannerModel>>
    >((ref) {
      return BannersNotifier(ref);
    });

class BannersNotifier
    extends StateNotifier<AsyncValue<List<FeaturedBannerModel>>> {
  BannersNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadBanners();
  }

  final Ref ref;

  Future<void> _loadBanners() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/banners.php');
      final list = (data as List)
          .map((e) => FeaturedBannerModel.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> add(FeaturedBannerModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/banners.php', item.toJson());
      await _loadBanners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(FeaturedBannerModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/banners.php', item.toJson());
      await _loadBanners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/banners.php', params: {'id': id});
      await _loadBanners();
    } catch (e) {
      // Handle error
    }
  }

  // Aliases for admin screens
  void addBanner(FeaturedBannerModel item) => add(item);
  void updateBanner(FeaturedBannerModel item) => update(item);
  void deleteBanner(String id) => delete(id);

  Future<void> seed() async {
    // Implement seed logic via API if needed
    _loadBanners();
  }
}

// Alias for backward compatibility
final featuredBannersProvider = bannersProvider;

// Letters Provider
final lettersProvider =
    StateNotifierProvider<LettersNotifier, AsyncValue<List<LetterModel>>>((
      ref,
    ) {
      return LettersNotifier(ref);
    });

class LettersNotifier extends StateNotifier<AsyncValue<List<LetterModel>>> {
  LettersNotifier(this.ref) : super(AsyncValue.data(_seedLetters)) {
    _loadLetters();
  }

  final Ref ref;

  static final List<LetterModel> _seedLetters = [
    LetterModel(
      id: 'ᱚ',
      charOlChiki: 'ᱚ',
      transliterationLatin: 'La',
      pronunciation: 'o',
    ),
    LetterModel(
      id: 'ᱟ',
      charOlChiki: 'ᱟ',
      transliterationLatin: 'Aah',
      pronunciation: 'aa',
    ),
    LetterModel(
      id: 'ᱤ',
      charOlChiki: 'ᱤ',
      transliterationLatin: 'Li',
      pronunciation: 'i',
    ),
    LetterModel(
      id: 'ᱩ',
      charOlChiki: 'ᱩ',
      transliterationLatin: 'Lu',
      pronunciation: 'u',
    ),
    LetterModel(
      id: 'ᱮ',
      charOlChiki: 'ᱮ',
      transliterationLatin: 'Le',
      pronunciation: 'e',
    ),
    LetterModel(
      id: 'ᱳ',
      charOlChiki: 'ᱳ',
      transliterationLatin: 'Lo',
      pronunciation: 'oh',
    ),
    LetterModel(
      id: 'ᱠ',
      charOlChiki: 'ᱠ',
      transliterationLatin: 'Ok',
      pronunciation: 'ko',
    ),
    LetterModel(
      id: 'ᱜ',
      charOlChiki: 'ᱜ',
      transliterationLatin: 'Ol',
      pronunciation: 'ga',
    ),
  ];

  Future<void> _loadLetters() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/letters.php');
      final list = (data as List).map((e) => LetterModel.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.data(_seedLetters);
    }
  }

  Future<void> add(LetterModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/letters.php', item.toJson());
      await _loadLetters();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(LetterModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/letters.php', item.toJson());
      await _loadLetters();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/letters.php', params: {'id': id});
      await _loadLetters();
    } catch (e) {
      // Handle error
    }
  }

  // Aliases for admin screens
  void addLetter(LetterModel item) => add(item);
  void updateLetter(LetterModel item) => update(item);
  void deleteLetter(String id) => delete(id);

  Future<void> seed() async {
    _loadLetters();
  }
}

// Numbers Provider
final numbersProvider =
    StateNotifierProvider<NumbersNotifier, AsyncValue<List<NumberModel>>>((
      ref,
    ) {
      return NumbersNotifier(ref);
    });

class NumbersNotifier extends StateNotifier<AsyncValue<List<NumberModel>>> {
  NumbersNotifier(this.ref) : super(AsyncValue.data(_seedNumbers)) {
    _loadNumbers();
  }

  final Ref ref;

  static final List<NumberModel> _seedNumbers = [
    NumberModel(
      id: '1',
      numeral: '᱑',
      value: 1,
      nameOlChiki: 'ᱢᱤᱫ',
      nameLatin: 'Mit',
    ),
    NumberModel(
      id: '2',
      numeral: '᱒',
      value: 2,
      nameOlChiki: 'ᱵᱟᱨ',
      nameLatin: 'Bar',
    ),
    NumberModel(
      id: '3',
      numeral: '᱓',
      value: 3,
      nameOlChiki: 'ᱯᱮ',
      nameLatin: 'Pe',
    ),
    NumberModel(
      id: '4',
      numeral: '᱔',
      value: 4,
      nameOlChiki: 'ᱯᱩᱱ',
      nameLatin: 'Pun',
    ),
    NumberModel(
      id: '5',
      numeral: '᱕',
      value: 5,
      nameOlChiki: 'ᱢᱚᱬᱮ',
      nameLatin: 'Mone',
    ),
  ];

  Future<void> _loadNumbers() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/numbers.php');
      final list = (data as List).map((e) => NumberModel.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.data(_seedNumbers);
    }
  }

  Future<void> add(NumberModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/numbers.php', item.toJson());
      await _loadNumbers();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(NumberModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/numbers.php', item.toJson());
      await _loadNumbers();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/numbers.php', params: {'id': id});
      await _loadNumbers();
    } catch (e) {
      // Handle error
    }
  }

  void addNumber(NumberModel item) => add(item);
  void updateNumber(NumberModel item) => update(item);
  void deleteNumber(String id) => delete(id);

  Future<void> seed() async {
    _loadNumbers();
  }
}

// Words Provider
final wordsProvider =
    StateNotifierProvider<WordsNotifier, AsyncValue<List<WordModel>>>((ref) {
      return WordsNotifier(ref);
    });

class WordsNotifier extends StateNotifier<AsyncValue<List<WordModel>>> {
  WordsNotifier(this.ref) : super(AsyncValue.data(_seedWords)) {
    _loadWords();
  }

  final Ref ref;

  static final List<WordModel> _seedWords = [
    WordModel(
      id: 'w1',
      wordOlChiki: 'ᱡᱚᱦᱟᱨ',
      wordLatin: 'Johar',
      meaning: 'Hello',
    ),
    WordModel(id: 'w2', wordOlChiki: 'ᱫᱟᱠ', wordLatin: 'Dak', meaning: 'Water'),
  ];

  Future<void> _loadWords() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/words.php');
      final list = (data as List).map((e) => WordModel.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.data(_seedWords);
    }
  }

  Future<void> add(WordModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/words.php', item.toJson());
      await _loadWords();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(WordModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/words.php', item.toJson());
      await _loadWords();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/words.php', params: {'id': id});
      await _loadWords();
    } catch (e) {
      // Handle error
    }
  }

  void addWord(WordModel item) => add(item);
  void updateWord(WordModel item) => update(item);
  void deleteWord(String id) => delete(id);

  Future<void> seed() async {
    _loadWords();
  }
}

// Sentences Provider
final sentencesProvider =
    StateNotifierProvider<SentencesNotifier, AsyncValue<List<SentenceModel>>>((
      ref,
    ) {
      return SentencesNotifier(ref);
    });

class SentencesNotifier extends StateNotifier<AsyncValue<List<SentenceModel>>> {
  SentencesNotifier(this.ref) : super(AsyncValue.data(_seedSentences)) {
    _loadSentences();
  }

  final Ref ref;

  static final List<SentenceModel> _seedSentences = [
    SentenceModel(
      id: 's1',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ, ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Johar, am do ced nyutum kana?',
      meaning: 'Hello, how are you?',
      pronunciation: 'Jo-har, am do ched nyu-tum ka-na?',
      category: 'Greeting',
    ),
    SentenceModel(
      id: 's2',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱵᱟᱝ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ing do bang nyutum kana',
      meaning: 'I am fine',
      pronunciation: 'Ing do bang nyu-tum ka-na',
      category: 'Greeting',
    ),
  ];

  Future<void> _loadSentences() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/sentences.php');
      final list = (data as List)
          .map((e) => SentenceModel.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.data(_seedSentences);
    }
  }

  Future<void> add(SentenceModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/sentences.php', item.toJson());
      await _loadSentences();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(SentenceModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/sentences.php', item.toJson());
      await _loadSentences();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/sentences.php', params: {'id': id});
      await _loadSentences();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> seed() async {
    _loadSentences();
  }
}

// Lessons Provider
final lessonsProvider =
    StateNotifierProvider<LessonsNotifier, AsyncValue<List<LessonModel>>>((
      ref,
    ) {
      return LessonsNotifier(ref);
    });

class LessonsNotifier extends StateNotifier<AsyncValue<List<LessonModel>>> {
  LessonsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadLessons();
  }

  final Ref ref;

  static final List<LessonModel> _seedLessons = [
    // Alphabet lessons
    LessonModel(
      id: 'seed_lesson_a1',
      categoryId: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱹᱲᱟᱝ',
      titleLatin: 'Vowels (Part 1)',
      description: 'Learn the first 3 Ol Chiki vowels',
      order: 0,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱚ',
          textLatin: 'O – as in "got"',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱟ',
          textLatin: 'A – as in "far"',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱤ',
          textLatin: 'I – as in "sit"',
        ),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_a2',
      categoryId: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱹᱲᱟᱝ',
      titleLatin: 'Vowels (Part 2)',
      description: 'Learn the next 3 Ol Chiki vowels',
      order: 1,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱩ',
          textLatin: 'U – as in "put"',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱮ',
          textLatin: 'E – as in "bed"',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱳ',
          textLatin: 'Oh – as in "go"',
        ),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_a3',
      categoryId: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱠᱚ',
      titleLatin: 'Consonants (Part 1)',
      description: 'Learn the first consonants: K, G, C',
      order: 2,
      estimatedMinutes: 7,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: 'ᱠ', textLatin: 'Ko – K sound'),
        LessonBlock(type: 'text', textOlChiki: 'ᱜ', textLatin: 'Ga – G sound'),
        LessonBlock(type: 'text', textOlChiki: 'ᱪ', textLatin: 'Ca – Ch sound'),
      ],
    ),

    // Numbers lessons
    LessonModel(
      id: 'seed_lesson_n1',
      categoryId: 'seed_numbers',
      titleOlChiki: 'ᱮᱞᱠᱷᱟ ᱑-᱕',
      titleLatin: 'Numbers 1–5',
      description: 'Count from one to five in Santali',
      order: 0,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(
          type: 'text',
          textOlChiki: '᱑ – ᱢᱤᱫ',
          textLatin: '1 – Mid (one)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱒ – ᱵᱟᱨ',
          textLatin: '2 – Bar (two)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱓ – ᱯᱮ',
          textLatin: '3 – Pe (three)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱔ – ᱯᱩᱱ',
          textLatin: '4 – Pun (four)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱕ – ᱢᱚᱬᱮ',
          textLatin: '5 – Moṇe (five)',
        ),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_n2',
      categoryId: 'seed_numbers',
      titleOlChiki: 'ᱮᱞᱠᱷᱟ ᱖-᱑᱐',
      titleLatin: 'Numbers 6–10',
      description: 'Count from six to ten in Santali',
      order: 1,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(
          type: 'text',
          textOlChiki: '᱖ – ᱛᱩᱨᱩᱭ',
          textLatin: '6 – Turuy (six)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱗ – ᱮᱭᱟᱮ',
          textLatin: '7 – Eyae (seven)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱘ – ᱤᱨᱟᱞ',
          textLatin: '8 – Iral (eight)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱙ – ᱟᱨᱮ',
          textLatin: '9 – Are (nine)',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: '᱑᱐ – ᱜᱮᱞ',
          textLatin: '10 – Gel (ten)',
        ),
      ],
    ),

    // Words lessons
    LessonModel(
      id: 'seed_lesson_w1',
      categoryId: 'seed_words',
      titleOlChiki: 'ᱡᱤᱱᱤᱥ ᱨᱚᱲ',
      titleLatin: 'Common Objects',
      description: 'Learn everyday object names in Santali',
      order: 0,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱫᱟᱠᱟ',
          textLatin: 'Daka – Rice / Food',
        ),
        LessonBlock(type: 'text', textOlChiki: 'ᱫᱟᱠ', textLatin: 'Dak – Water'),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱚᱲᱟᱜ',
          textLatin: 'Oṛak – House',
        ),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_w2',
      categoryId: 'seed_words',
      titleOlChiki: 'ᱡᱟᱱᱣᱟᱨ',
      titleLatin: 'Animals',
      description: 'Learn animal names in Santali',
      order: 1,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: 'ᱥᱮᱛᱟ', textLatin: 'Seta – Dog'),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱢᱮᱨᱚᱢ',
          textLatin: 'Merom – Goat',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱫᱟᱨᱮ',
          textLatin: 'Dare – Tree / Bird',
        ),
      ],
    ),

    // Sentences lessons
    LessonModel(
      id: 'seed_lesson_s1',
      categoryId: 'seed_sentences',
      titleOlChiki: 'ᱡᱚᱦᱟᱨ ᱣᱟᱠᱭ',
      titleLatin: 'Greetings',
      description: 'Learn basic Santali greetings',
      order: 0,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱡᱚᱦᱟᱨ!',
          textLatin: 'Johar! – Hello!',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱪᱮᱫ ᱠᱟᱱᱟ?',
          textLatin: 'Ced kana? – How are you?',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱟᱹᱰᱤ ᱵᱟᱝᱪᱟᱣ',
          textLatin: 'Aḍi bangchao – Very well',
        ),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_s2',
      categoryId: 'seed_sentences',
      titleOlChiki: 'ᱱᱟᱜᱟᱢ ᱣᱟᱠᱭ',
      titleLatin: 'Introductions',
      description: 'Introduce yourself in Santali',
      order: 1,
      estimatedMinutes: 5,
      blocks: [
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱤᱧ ᱧᱩᱛᱩᱢ ... ᱠᱟᱱᱟ',
          textLatin: 'Iñ ñutum ... kana – My name is ...',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱟᱢ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
          textLatin: 'Am ñutum ced? – What is your name?',
        ),
        LessonBlock(
          type: 'text',
          textOlChiki: 'ᱥᱮᱨᱢᱟ ᱦᱩᱭᱩᱜ ᱟ',
          textLatin: 'Serma huyug a – Nice to meet you',
        ),
      ],
    ),
  ];

  Future<void> _loadLessons() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/lessons.php');
      final list = (data as List).map((e) => LessonModel.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e) {
      state = AsyncValue.data(_seedLessons);
    }
  }

  Future<void> add(LessonModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/lessons.php', item.toJson());
      await _loadLessons();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(LessonModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/lessons.php', item.toJson());
      await _loadLessons();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/lessons.php', params: {'id': id});
      await _loadLessons();
    } catch (e) {
      // Handle error
    }
  }

  // Aliases for admin screens
  Future<void> addLesson(LessonModel item) async => add(item);
  Future<void> updateLesson(LessonModel item) async => update(item);
  Future<void> deleteLesson(String id) async => delete(id);

  Future<void> seed() async {
    state = const AsyncValue.loading();
    _loadLessons();
  }
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
        // Default quizzes with actual questions
        final defaultQuizzes = [
          QuizModel(
            id: 'quiz_alphabets_basics',
            categoryId: 'alphabets',
            title: 'Alphabet Basics',
            level: 'beginner',
            order: 0,
            isActive: true,
            passingScore: 70,
            questions: [
              QuizQuestion(
                promptOlChiki: 'ᱚ',
                promptLatin: 'Which sound does this letter make?',
                optionsOlChiki: ['a', 'i', 'u', 'o'],
                optionsLatin: ['a', 'i', 'u', 'o'],
                correctIndex: 0,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱛ',
                promptLatin: 'Identify this consonant:',
                optionsOlChiki: ['at', 'ag', 'al', 'ak'],
                optionsLatin: ['at', 'ag', 'al', 'ak'],
                correctIndex: 0,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱜ',
                promptLatin: 'What is this letter?',
                optionsOlChiki: ['ag', 'ang', 'al', 'at'],
                optionsLatin: ['ag', 'ang', 'al', 'at'],
                correctIndex: 0,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱞ',
                promptLatin: 'Which letter represents "al"?',
                optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱞ'],
                optionsLatin: ['a', 'at', 'ag', 'al'],
                correctIndex: 3,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱟ',
                promptLatin: 'This vowel sounds like:',
                optionsOlChiki: ['a', 'aa/la', 'i', 'u'],
                optionsLatin: ['a', 'aa/la', 'i', 'u'],
                correctIndex: 1,
              ),
            ],
          ),
          QuizModel(
            id: 'quiz_numbers_1to10',
            categoryId: 'numbers',
            title: 'Numbers 1-10',
            level: 'beginner',
            order: 1,
            isActive: true,
            passingScore: 70,
            questions: [
              QuizQuestion(
                promptOlChiki: '᱑',
                promptLatin: 'What number is this?',
                optionsOlChiki: ['1', '2', '3', '4'],
                optionsLatin: ['One', 'Two', 'Three', 'Four'],
                correctIndex: 0,
              ),
              QuizQuestion(
                promptOlChiki: '᱕',
                promptLatin: 'Identify this number:',
                optionsOlChiki: ['3', '4', '5', '6'],
                optionsLatin: ['Three', 'Four', 'Five', 'Six'],
                correctIndex: 2,
              ),
              QuizQuestion(
                promptOlChiki: '᱑᱐',
                promptLatin: 'What is this number?',
                optionsOlChiki: ['8', '9', '10', '11'],
                optionsLatin: ['Eight', 'Nine', 'Ten', 'Eleven'],
                correctIndex: 2,
              ),
              QuizQuestion(
                promptOlChiki: '᱓',
                promptLatin: 'Which number is shown?',
                optionsOlChiki: ['1', '2', '3', '4'],
                optionsLatin: ['One', 'Two', 'Three', 'Four'],
                correctIndex: 2,
              ),
            ],
          ),
          QuizModel(
            id: 'quiz_vowels',
            categoryId: 'alphabets',
            title: 'Master the Vowels',
            level: 'intermediate',
            order: 2,
            isActive: true,
            passingScore: 80,
            questions: [
              QuizQuestion(
                promptOlChiki: 'ᱤ',
                promptLatin: 'This is the vowel for:',
                optionsOlChiki: ['a', 'i', 'u', 'e'],
                optionsLatin: ['a', 'i', 'u', 'e'],
                correctIndex: 1,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱩ',
                promptLatin: 'Identify this vowel sound:',
                optionsOlChiki: ['a', 'i', 'u', 'o'],
                optionsLatin: ['a', 'i', 'u', 'o'],
                correctIndex: 2,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱮ',
                promptLatin: 'What vowel is this?',
                optionsOlChiki: ['a', 'i', 'e', 'o'],
                optionsLatin: ['a', 'i', 'e', 'o'],
                correctIndex: 2,
              ),
              QuizQuestion(
                promptOlChiki: 'ᱳ',
                promptLatin: 'This letter represents:',
                optionsOlChiki: ['a', 'u', 'e', 'o'],
                optionsLatin: ['a', 'u', 'e', 'o'],
                correctIndex: 3,
              ),
            ],
          ),
        ];
        state = AsyncValue.data(defaultQuizzes);
        _saveQuizzes(defaultQuizzes);
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

  Future<void> seed() async {
    state = const AsyncValue.loading();
    prefs.remove('quizzes');
    _loadQuizzes();
  }
}

// ============== RHYMES PROVIDER ==============

final rhymesProvider =
    StateNotifierProvider<RhymesNotifier, AsyncValue<List<RhymeModel>>>((ref) {
      return RhymesNotifier(ref);
    });

class RhymesNotifier extends StateNotifier<AsyncValue<List<RhymeModel>>> {
  RhymesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadRhymes();
  }

  final Ref ref;

  static final List<RhymeModel> _seedRhymes = [
    RhymeModel(
      id: 'seed_1',
      titleOlChiki: 'ᱤᱥᱤᱱ ᱥᱟᱱᱟᱢ',
      titleLatin: 'Isin Sanam',
      contentOlChiki: 'ᱤᱥᱤᱱ ᱥᱟᱱᱟᱢ ᱨᱮ\nᱵᱤᱨ ᱦᱚᱨ ᱥᱟᱱᱟᱢ\nᱫᱟᱨᱮ ᱛᱷᱟᱞᱮ\nᱡᱚᱛᱚ ᱥᱟᱱᱟᱢ',
      contentLatin: 'Isin sanam re\nBir hor sanam\nDare thale\nJoto sanam',
      category: 'Nature',
    ),
    RhymeModel(
      id: 'seed_2',
      titleOlChiki: 'ᱢᱮᱨᱟᱢ ᱯᱟᱥᱤ',
      titleLatin: 'Meram Pasi',
      contentOlChiki: 'ᱢᱮᱨᱟᱢ ᱯᱟᱥᱤ\nᱠᱟᱛᱮ ᱟᱥᱤ\nᱵᱟᱝ ᱠᱟᱛᱮ\nᱵᱟᱝ ᱟᱥᱤ',
      contentLatin: 'Meram pasi\nKate asi\nBang kate\nBang asi',
      category: 'Animal',
    ),
    RhymeModel(
      id: 'seed_3',
      titleOlChiki: 'ᱫᱟᱠᱟ ᱦᱟᱥᱟ',
      titleLatin: 'Daka Hasa',
      contentOlChiki: 'ᱫᱟᱠᱟ ᱦᱟᱥᱟ\nᱫᱟᱠᱟ ᱡᱚᱢ\nᱵᱟᱝ ᱦᱟᱥᱟ\nᱵᱟᱝ ᱡᱚᱢ',
      contentLatin: 'Daka hasa\nDaka jom\nBang hasa\nBang jom',
      category: 'General',
    ),
    RhymeModel(
      id: 'seed_4',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
      titleLatin: 'Ol Chiki',
      contentOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱞᱤᱯᱤ\nᱥᱟᱱᱛᱟᱲ ᱞᱤᱯᱤ\nᱯᱟᱱᱛᱮ ᱨᱟᱜᱷᱩ\nᱥᱟᱫᱷᱩ ᱢᱩᱨᱢᱩ',
      contentLatin: 'Ol Chiki lipi\nSantar lipi\nPante raghu\nSadhu murmu',
      category: 'Moral',
    ),
    RhymeModel(
      id: 'seed_5',
      titleOlChiki: 'ᱥᱤᱧ ᱵᱚᱝᱜᱟ',
      titleLatin: 'Sing Bonga',
      contentOlChiki: 'ᱥᱤᱧ ᱵᱚᱝᱜᱟ\nᱢᱟᱨᱟᱝ ᱵᱚᱝᱜᱟ\nᱫᱷᱟᱨᱛᱤ ᱥᱮᱨᱢᱟ\nᱡᱚᱛᱚ ᱵᱚᱝᱜᱟ',
      contentLatin: 'Sing Bonga\nMarang Bonga\nDharti Serma\nJoto Bonga',
      category: 'Nature',
    ),
    RhymeModel(
      id: 'seed_6',
      titleOlChiki: 'ᱵᱤᱨ ᱫᱟᱨᱮ',
      titleLatin: 'Bir Dare',
      contentOlChiki: 'ᱵᱤᱨ ᱫᱟᱨᱮ ᱵᱟᱦᱟ\nᱨᱟᱝ ᱥᱩᱠᱨᱤ\nᱦᱚᱲ ᱫᱩᱲᱩᱵ\nᱵᱤᱨ ᱥᱟᱱᱟᱢ',
      contentLatin: 'Bir dare baha\nRang sukri\nHor durub\nBir sanam',
      category: 'Nature',
    ),
    RhymeModel(
      id: 'seed_7',
      titleOlChiki: 'ᱟᱞᱟᱝ ᱠᱟᱛᱷᱟ',
      titleLatin: 'Alang Katha',
      contentOlChiki: 'ᱟᱞᱟᱝ ᱠᱟᱛᱷᱟ\nᱟᱛᱚ ᱨᱮ\nᱟᱵᱩᱝ ᱟᱯᱩᱝ\nᱫᱚ ᱠᱟᱛᱷᱟ',
      contentLatin: 'Alang katha\nAto re\nAbung apung\nDo katha',
      category: 'Moral',
    ),
    RhymeModel(
      id: 'seed_8',
      titleOlChiki: 'ᱥᱤᱢ ᱥᱟᱹᱠᱟᱹᱢ',
      titleLatin: 'Sim Sakam',
      contentOlChiki: 'ᱥᱤᱢ ᱥᱟᱹᱠᱟᱹᱢ\nᱫᱟᱨᱮ ᱨᱮᱱᱟᱜ\nᱥᱤᱢ ᱫᱚ ᱩᱰᱟᱹᱣ\nᱡᱟᱹᱱᱤᱡ ᱛᱟᱦᱮᱸᱱ',
      contentLatin: 'Sim sakam\nDare renag\nSim do udaw\nJanij tahen',
      category: 'Animal',
    ),
  ];

  Future<void> _loadRhymes() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.get('/rhymes.php');
      final list = (data as List).map((e) => RhymeModel.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e) {
      // Fallback to local seed data when API is unreachable
      state = AsyncValue.data(_seedRhymes);
    }
  }

  Future<void> add(RhymeModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/rhymes.php', item.toJson());
      await _loadRhymes();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> update(RhymeModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/rhymes.php', item.toJson());
      await _loadRhymes();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/rhymes.php', params: {'id': id});
      await _loadRhymes();
    } catch (e) {
      // Handle error
    }
  }

  // Aliases for admin screens
  Future<void> addRhyme(RhymeModel item) async => add(item);
  Future<void> updateRhyme(RhymeModel item) async => update(item);
  Future<void> deleteRhyme(String id) async => delete(id);

  Future<void> seed() async {
    _loadRhymes();
  }
}

// ============== RHYME CATEGORIES PROVIDER ==============

final rhymeCategoriesProvider =
    StateNotifierProvider<
      RhymeCategoriesNotifier,
      AsyncValue<List<RhymeCategoryModel>>
    >((ref) {
      return RhymeCategoriesNotifier(ref);
    });

class RhymeCategoriesNotifier
    extends StateNotifier<AsyncValue<List<RhymeCategoryModel>>> {
  RhymeCategoriesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/rhyme_categories.php');
      final List<dynamic> data = response as List<dynamic>;
      state = AsyncValue.data(
        data.map((e) => RhymeCategoryModel.fromJson(e)).toList(),
      );
    } catch (e, st) {
      debugPrint('Error loading rhyme categories: $e');
      debugPrint(st.toString());
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(RhymeCategoryModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/rhyme_categories.php', item.toJson());
      await _load();
    } catch (e) {
      debugPrint('Error adding rhyme category: $e');
      rethrow;
    }
  }

  Future<void> update(RhymeCategoryModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/rhyme_categories.php', item.toJson());
      await _load();
    } catch (e) {
      debugPrint('Error updating rhyme category: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/rhyme_categories.php', params: {'id': id});
      await _load();
    } catch (e) {
      debugPrint('Error deleting rhyme category: $e');
      rethrow;
    }
  }
}

// ============== RHYME SUBCATEGORIES PROVIDER ==============

final rhymeSubcategoriesProvider =
    StateNotifierProvider<
      RhymeSubcategoriesNotifier,
      AsyncValue<List<RhymeSubcategoryModel>>
    >((ref) {
      return RhymeSubcategoriesNotifier(ref);
    });

class RhymeSubcategoriesNotifier
    extends StateNotifier<AsyncValue<List<RhymeSubcategoryModel>>> {
  RhymeSubcategoriesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref ref;

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/rhyme_subcategories.php');
      final List<dynamic> data = response as List<dynamic>;
      state = AsyncValue.data(
        data.map((e) => RhymeSubcategoryModel.fromJson(e)).toList(),
      );
    } catch (e, st) {
      debugPrint('Error loading rhyme subcategories: $e');
      debugPrint(st.toString());
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(RhymeSubcategoryModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.post('/rhyme_subcategories.php', item.toJson());
      await _load();
    } catch (e) {
      debugPrint('Error adding rhyme subcategory: $e');
      rethrow;
    }
  }

  Future<void> update(RhymeSubcategoryModel item) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/rhyme_subcategories.php', item.toJson());
      await _load();
    } catch (e) {
      debugPrint('Error updating rhyme subcategory: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/rhyme_subcategories.php', params: {'id': id});
      await _load();
    } catch (e) {
      debugPrint('Error deleting rhyme subcategory: $e');
      rethrow;
    }
  }
}

// Filtered subcategories by category
final rhymeSubcategoriesByCategoryProvider =
    Provider.family<AsyncValue<List<RhymeSubcategoryModel>>, String>((
      ref,
      categoryId,
    ) {
      final subcatsAsync = ref.watch(rhymeSubcategoriesProvider);
      return subcatsAsync.when(
        data: (subcats) => AsyncValue.data(
          subcats.where((s) => s.categoryId == categoryId).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

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
  final progress = ref.watch(progressProvider);
  final streak = progress.currentStreak;
  final stars = progress.totalStars;
  final lessons = progress.lessonsCompletedCount;
  final quizzes = progress.quizzesCompletedCount;

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

  // 6. Add Sample Quiz
  final quizzesNotifier = ref.read(quizzesProvider.notifier);
  final quizId = 'quiz_basics_${DateTime.now().millisecondsSinceEpoch}';

  await quizzesNotifier.addQuiz(
    QuizModel(
      id: quizId,
      categoryId: alphabetsId,
      title: 'Basics Quiz',
      level: 'beginner',
      questions: [
        QuizQuestion(
          promptOlChiki: 'Which letter is "La"?',
          optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱞ'],
          optionsLatin: ['a', 'at', 'ag', 'al'],
          correctIndex: 3,
        ),
        QuizQuestion(
          promptOlChiki: 'What sound does ᱚ make?',
          optionsOlChiki: ['A', 'O', 'I', 'U'],
          optionsLatin: ['a', 'o', 'i', 'u'],
          correctIndex: 0,
        ),
      ],
    ),
  );

  // 7. update first lesson to include blocks
  // Instead, let's just add a new "Quiz Lesson"

  await lessonsNotifier.addLesson(
    LessonModel(
      id: 'lesson_quiz_demo_${DateTime.now().millisecondsSinceEpoch}',
      categoryId: alphabetsId,
      titleOlChiki: 'ᱠᱩᱤᱡᱽ',
      titleLatin: 'Quiz Demo',
      level: 'beginner',
      order: 99,
      isActive: true,
      estimatedMinutes: 2,
      blocks: [
        LessonBlock(
          type: 'text',
          textLatin: 'Ready to test your knowledge? Take the quiz below!',
          textOlChiki: 'ᱵᱤᱰᱟᱹᱣ ᱨᱮᱱᱟᱜ ᱚᱠᱛᱚ!',
        ),
        LessonBlock(type: 'quiz', quizRefId: quizId),
      ],
    ),
  );

  // 8. Add Sample Rhymes
  final rhymesNotifier = ref.read(rhymesProvider.notifier);

  await rhymesNotifier.addRhyme(
    RhymeModel(
      id: 'rhyme_hati',
      titleOlChiki: 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ',
      titleLatin: 'Hati Lagit (For Elephant)',
      contentOlChiki: 'ᱦᱟᱹᱛᱤ ᱞᱟᱹᱜᱤᱫ ᱦᱟᱹᱛᱤ...\nᱥᱮᱛᱟ ᱞᱟᱹᱜᱤᱫ ᱥᱮᱛᱟ...',
      contentLatin: 'Hati lagit hati...\nSeta lagit seta...',
      category: 'Animal',
      subcategory: 'Wild Animals',
      audioUrl: 'https://hostinger.com/audio/hati.mp3',
    ),
  );

  await rhymesNotifier.addRhyme(
    RhymeModel(
      id: 'rhyme_buru',
      titleOlChiki: 'ᱵᱩᱨᱩ ᱨᱮ',
      titleLatin: 'Buru Re (In the Hill)',
      contentOlChiki: 'ᱵᱩᱨᱩ ᱨᱮ ᱵᱩᱨᱩ...\nᱡᱷᱟᱨᱱᱟ ᱨᱮ ᱡᱷᱟᱨᱱᱟ...',
      contentLatin: 'Buru re buru...\nJharna re jharna...',
      category: 'Nature',
      subcategory: 'Mountains & Forest',
      audioUrl: 'https://hostinger.com/audio/buru.mp3',
    ),
  );
}
