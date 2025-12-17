import '../services/firebase_service.dart';
import '../models/content_models.dart';

/// Repository for content operations (categories, banners, letters, lessons, quizzes)
class ContentRepository {
  final FirebaseService _firebase = FirebaseService.instance;

  // ============== CATEGORIES ==============
  /// Stream of active categories ordered by order field
  Stream<List<CategoryModel>> watchCategories() {
    return _firebase.categoriesCollection
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all categories (including inactive, for admin)
  Future<List<CategoryModel>> getAllCategories() async {
    final snapshot = await _firebase.categoriesCollection.orderBy('order').get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get single category
  Future<CategoryModel?> getCategory(String id) async {
    final doc = await _firebase.categoriesCollection.doc(id).get();
    if (!doc.exists) return null;
    return CategoryModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Create/update category
  Future<void> saveCategory(CategoryModel category) async {
    if (category.id.isEmpty) {
      await _firebase.categoriesCollection.add(category.toFirestore());
    } else {
      await _firebase.categoriesCollection.doc(category.id).set(category.toFirestore());
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    await _firebase.categoriesCollection.doc(id).delete();
  }

  // ============== FEATURED BANNERS ==============
  /// Stream of active banners
  Stream<List<FeaturedBannerModel>> watchFeaturedBanners() {
    return _firebase.featuredBannersCollection
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeaturedBannerModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all banners (for admin)
  Future<List<FeaturedBannerModel>> getAllBanners() async {
    final snapshot = await _firebase.featuredBannersCollection.orderBy('order').get();
    return snapshot.docs
        .map((doc) => FeaturedBannerModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Save banner
  Future<void> saveBanner(FeaturedBannerModel banner) async {
    if (banner.id.isEmpty) {
      await _firebase.featuredBannersCollection.add(banner.toFirestore());
    } else {
      await _firebase.featuredBannersCollection.doc(banner.id).set(banner.toFirestore());
    }
  }

  /// Delete banner
  Future<void> deleteBanner(String id) async {
    await _firebase.featuredBannersCollection.doc(id).delete();
  }

  // ============== LETTERS ==============
  /// Stream of active letters
  Stream<List<LetterModel>> watchLetters() {
    return _firebase.lettersCollection
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LetterModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all letters
  Future<List<LetterModel>> getAllLetters() async {
    final snapshot = await _firebase.lettersCollection.orderBy('order').get();
    return snapshot.docs
        .map((doc) => LetterModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get single letter
  Future<LetterModel?> getLetter(String id) async {
    final doc = await _firebase.lettersCollection.doc(id).get();
    if (!doc.exists) return null;
    return LetterModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Save letter
  Future<void> saveLetter(LetterModel letter) async {
    if (letter.id.isEmpty) {
      await _firebase.lettersCollection.add(letter.toFirestore());
    } else {
      await _firebase.lettersCollection.doc(letter.id).set(letter.toFirestore());
    }
  }

  /// Delete letter
  Future<void> deleteLetter(String id) async {
    await _firebase.lettersCollection.doc(id).delete();
  }

  // ============== LESSONS ==============
  /// Stream of active lessons for a category
  Stream<List<LessonModel>> watchLessons(String categoryId) {
    return _firebase.lessonsCollection
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LessonModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get all lessons (for admin)
  Future<List<LessonModel>> getAllLessons() async {
    final snapshot = await _firebase.lessonsCollection.orderBy('order').get();
    return snapshot.docs
        .map((doc) => LessonModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get lessons by category
  Future<List<LessonModel>> getLessonsByCategory(String categoryId) async {
    final snapshot = await _firebase.lessonsCollection
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => LessonModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get single lesson
  Future<LessonModel?> getLesson(String id) async {
    final doc = await _firebase.lessonsCollection.doc(id).get();
    if (!doc.exists) return null;
    return LessonModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Save lesson
  Future<void> saveLesson(LessonModel lesson) async {
    if (lesson.id.isEmpty) {
      await _firebase.lessonsCollection.add(lesson.toFirestore());
    } else {
      await _firebase.lessonsCollection.doc(lesson.id).set(lesson.toFirestore());
    }
  }

  /// Delete lesson
  Future<void> deleteLesson(String id) async {
    await _firebase.lessonsCollection.doc(id).delete();
  }

  // ============== QUIZZES ==============
  /// Get quiz by ID
  Future<QuizModel?> getQuiz(String id) async {
    final doc = await _firebase.quizzesCollection.doc(id).get();
    if (!doc.exists) return null;
    return QuizModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Get quizzes by category
  Future<List<QuizModel>> getQuizzesByCategory(String categoryId) async {
    final snapshot = await _firebase.quizzesCollection
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => QuizModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get all quizzes (for admin)
  Future<List<QuizModel>> getAllQuizzes() async {
    final snapshot = await _firebase.quizzesCollection.orderBy('order').get();
    return snapshot.docs
        .map((doc) => QuizModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Save quiz
  Future<void> saveQuiz(QuizModel quiz) async {
    if (quiz.id.isEmpty) {
      await _firebase.quizzesCollection.add(quiz.toFirestore());
    } else {
      await _firebase.quizzesCollection.doc(quiz.id).set(quiz.toFirestore());
    }
  }

  /// Delete quiz
  Future<void> deleteQuiz(String id) async {
    await _firebase.quizzesCollection.doc(id).delete();
  }

  // ============== STICKERS ==============
  /// Stream of active stickers
  Stream<List<StickerModel>> watchStickers() {
    return _firebase.stickersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StickerModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Save sticker
  Future<void> saveSticker(StickerModel sticker) async {
    if (sticker.id.isEmpty) {
      await _firebase.stickersCollection.add(sticker.toFirestore());
    } else {
      await _firebase.stickersCollection.doc(sticker.id).set(sticker.toFirestore());
    }
  }

  /// Delete sticker
  Future<void> deleteSticker(String id) async {
    await _firebase.stickersCollection.doc(id).delete();
  }
}
