import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role;
  final UserPreferences preferences;
  final UserStats stats;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = 'user',
    required this.preferences,
    required this.stats,
    required this.createdAt,
    this.lastActiveAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserModel(
      uid: docId,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Learner',
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String? ?? 'user',
      preferences: UserPreferences.fromMap(
        data['preferences'] as Map<String, dynamic>? ?? {},
      ),
      stats: UserStats.fromMap(
        data['stats'] as Map<String, dynamic>? ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'preferences': preferences.toMap(),
      'stats': stats.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? role,
    UserPreferences? preferences,
    UserStats? stats,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  bool get isAdmin => role == 'admin';
}

class UserPreferences {
  final String themeMode;
  final String scriptMode;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final String level;

  UserPreferences({
    this.themeMode = 'system',
    this.scriptMode = 'both',
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.level = 'beginner',
  });

  factory UserPreferences.fromMap(Map<String, dynamic> data) {
    return UserPreferences(
      themeMode: data['themeMode'] as String? ?? 'system',
      scriptMode: data['scriptMode'] as String? ?? 'both',
      soundEnabled: data['soundEnabled'] as bool? ?? true,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      level: data['level'] as String? ?? 'beginner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'scriptMode': scriptMode,
      'soundEnabled': soundEnabled,
      'notificationsEnabled': notificationsEnabled,
      'level': level,
    };
  }

  UserPreferences copyWith({
    String? themeMode,
    String? scriptMode,
    bool? soundEnabled,
    bool? notificationsEnabled,
    String? level,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      scriptMode: scriptMode ?? this.scriptMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      level: level ?? this.level,
    );
  }
}

class UserStats {
  final int stars;
  final int streak;
  final DateTime? lastActiveDate;
  final int totalLessonsCompleted;
  final int totalQuizzesCompleted;
  final int correctAnswers;
  final int totalAnswers;

  UserStats({
    this.stars = 0,
    this.streak = 0,
    this.lastActiveDate,
    this.totalLessonsCompleted = 0,
    this.totalQuizzesCompleted = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> data) {
    return UserStats(
      stars: data['stars'] as int? ?? 0,
      streak: data['streak'] as int? ?? 0,
      lastActiveDate: (data['lastActiveDate'] as Timestamp?)?.toDate(),
      totalLessonsCompleted: data['totalLessonsCompleted'] as int? ?? 0,
      totalQuizzesCompleted: data['totalQuizzesCompleted'] as int? ?? 0,
      correctAnswers: data['correctAnswers'] as int? ?? 0,
      totalAnswers: data['totalAnswers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stars': stars,
      'streak': streak,
      'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalQuizzesCompleted': totalQuizzesCompleted,
      'correctAnswers': correctAnswers,
      'totalAnswers': totalAnswers,
    };
  }

  double get accuracy => totalAnswers > 0 ? (correctAnswers / totalAnswers) * 100 : 0;

  UserStats copyWith({
    int? stars,
    int? streak,
    DateTime? lastActiveDate,
    int? totalLessonsCompleted,
    int? totalQuizzesCompleted,
    int? correctAnswers,
    int? totalAnswers,
  }) {
    return UserStats(
      stars: stars ?? this.stars,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalLessonsCompleted: totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalQuizzesCompleted: totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswers: totalAnswers ?? this.totalAnswers,
    );
  }
}
