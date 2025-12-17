import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/content_models.dart';
import '../../core/constants/app_constants.dart';

/// Repository for user data and preferences
class UserRepository {
  final FirebaseService _firebase = FirebaseService.instance;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============== USER DATA ==============
  /// Get current user data from Firestore
  Future<UserModel?> getCurrentUser() async {
    final userId = _firebase.currentUserId;
    if (userId == null) return null;
    return getUser(userId);
  }

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firebase.usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Stream current user data
  Stream<UserModel?> watchCurrentUser() {
    final userId = _firebase.currentUserId;
    if (userId == null) return Stream.value(null);
    return watchUser(userId);
  }

  /// Stream user data
  Stream<UserModel?> watchUser(String userId) {
    return _firebase.usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc.data()!, doc.id);
        });
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firebase.usersCollection.doc(userId).update(updates);
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(UserPreferences preferences) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    await _firebase.usersCollection.doc(userId).update({
      'preferences': preferences.toMap(),
    });

    // Also save to local storage for fast access
    final p = await prefs;
    await p.setString(AppConstants.prefThemeMode, preferences.themeMode);
    await p.setString(AppConstants.prefScriptMode, preferences.scriptMode);
    await p.setBool(AppConstants.prefSoundEnabled, preferences.soundEnabled);
    await p.setBool(AppConstants.prefNotificationsEnabled, preferences.notificationsEnabled);
    await p.setString(AppConstants.prefUserLevel, preferences.level);
  }

  /// Update user stats
  Future<void> updateStats(UserStats stats) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    await _firebase.usersCollection.doc(userId).update({
      'stats': stats.toMap(),
    });
  }

  /// Add stars to user
  Future<void> addStars(int amount) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    await _firebase.usersCollection.doc(userId).update({
      'stats.stars': FieldValue.increment(amount),
    });
  }

  /// Update streak
  Future<void> updateStreak() async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    final user = await getUser(userId);
    if (user == null) return;

    final now = DateTime.now();
    final lastActive = user.stats.lastActiveDate;
    
    int newStreak = user.stats.streak;
    
    if (lastActive != null) {
      final daysSinceActive = now.difference(lastActive).inDays;
      if (daysSinceActive == 1) {
        // Consecutive day - increment streak
        newStreak++;
      } else if (daysSinceActive > 1) {
        // Streak broken - reset
        newStreak = 1;
      }
      // Same day - no change
    } else {
      // First activity
      newStreak = 1;
    }

    await _firebase.usersCollection.doc(userId).update({
      'stats.streak': newStreak,
      'stats.lastActiveDate': Timestamp.now(),
      'lastActiveAt': Timestamp.now(),
    });
  }

  /// Record quiz answer
  Future<void> recordQuizAnswer(bool isCorrect) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    final updates = {
      'stats.totalAnswers': FieldValue.increment(1),
    };
    
    if (isCorrect) {
      updates['stats.correctAnswers'] = FieldValue.increment(1);
    }

    await _firebase.usersCollection.doc(userId).update(updates);
  }

  /// Record completed lesson
  Future<void> recordLessonCompleted() async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    await _firebase.usersCollection.doc(userId).update({
      'stats.totalLessonsCompleted': FieldValue.increment(1),
    });
  }

  /// Record completed quiz
  Future<void> recordQuizCompleted() async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    await _firebase.usersCollection.doc(userId).update({
      'stats.totalQuizzesCompleted': FieldValue.increment(1),
    });
  }

  // ============== USER PROGRESS ==============
  /// Get progress for a category
  Future<UserProgressModel?> getCategoryProgress(String categoryId) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return null;

    final doc = await _firebase.userProgressCollection(userId).doc(categoryId).get();
    if (!doc.exists) return null;
    return UserProgressModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Stream all progress
  Stream<List<UserProgressModel>> watchAllProgress() {
    final userId = _firebase.currentUserId;
    if (userId == null) return Stream.value([]);

    return _firebase.userProgressCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProgressModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Update category progress
  Future<void> updateCategoryProgress(
    String categoryId, {
    required double percent,
    required int completedLessons,
    required int totalLessons,
  }) async {
    final userId = _firebase.currentUserId;
    if (userId == null) return;

    final progress = UserProgressModel(
      categoryId: categoryId,
      percent: percent,
      updatedAt: DateTime.now(),
      completedLessons: completedLessons,
      totalLessons: totalLessons,
    );

    await _firebase.userProgressCollection(userId)
        .doc(categoryId)
        .set(progress.toFirestore());
  }

  // ============== LOCAL PREFERENCES ==============
  /// Get theme mode from local storage
  Future<String> getLocalThemeMode() async {
    final p = await prefs;
    return p.getString(AppConstants.prefThemeMode) ?? 'system';
  }

  /// Set theme mode locally
  Future<void> setLocalThemeMode(String mode) async {
    final p = await prefs;
    await p.setString(AppConstants.prefThemeMode, mode);
  }

  /// Get script mode from local storage
  Future<String> getLocalScriptMode() async {
    final p = await prefs;
    return p.getString(AppConstants.prefScriptMode) ?? 'both';
  }

  /// Set script mode locally
  Future<void> setLocalScriptMode(String mode) async {
    final p = await prefs;
    await p.setString(AppConstants.prefScriptMode, mode);
  }

  /// Get sound enabled from local storage
  Future<bool> getLocalSoundEnabled() async {
    final p = await prefs;
    return p.getBool(AppConstants.prefSoundEnabled) ?? true;
  }

  /// Set sound enabled locally
  Future<void> setLocalSoundEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool(AppConstants.prefSoundEnabled, enabled);
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    final p = await prefs;
    return p.getBool(AppConstants.prefOnboardingComplete) ?? false;
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    final p = await prefs;
    await p.setBool(AppConstants.prefOnboardingComplete, true);
  }

  /// Clear local preferences (for logout)
  Future<void> clearLocalPreferences() async {
    final p = await prefs;
    await p.clear();
  }
}
