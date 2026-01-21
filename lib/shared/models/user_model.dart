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

  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'] as String,
      email: data['email'] as String? ?? '',
      displayName: data['display_name'] as String? ?? 'Learner',
      photoUrl: data['photo_url'] as String?,
      role: data['role'] as String? ?? 'user',
      preferences: UserPreferences.fromJson(
        data['preferences'] as Map<String, dynamic>? ?? {},
      ),
      stats: UserStats.fromJson(data['stats'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.parse(data['created_at'] as String),
      lastActiveAt: data['last_active_at'] != null
          ? DateTime.parse(data['last_active_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role': role,
      'preferences': preferences.toJson(),
      'stats': stats.toJson(),
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
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

  factory UserPreferences.fromJson(Map<String, dynamic> data) {
    return UserPreferences(
      themeMode: data['theme_mode'] as String? ?? 'system',
      scriptMode: data['script_mode'] as String? ?? 'both',
      soundEnabled: data['sound_enabled'] as bool? ?? true,
      notificationsEnabled: data['notifications_enabled'] as bool? ?? true,
      level: data['level'] as String? ?? 'beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode,
      'script_mode': scriptMode,
      'sound_enabled': soundEnabled,
      'notifications_enabled': notificationsEnabled,
      'level': level,
    };
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

  factory UserStats.fromJson(Map<String, dynamic> data) {
    return UserStats(
      stars: data['stars'] as int? ?? 0,
      streak: data['streak'] as int? ?? 0,
      lastActiveDate: data['last_active_date'] != null
          ? DateTime.parse(data['last_active_date'] as String)
          : null,
      totalLessonsCompleted: data['lessons_completed'] as int? ?? 0,
      totalQuizzesCompleted: data['quizzes_completed'] as int? ?? 0,
      correctAnswers: data['correct_answers'] as int? ?? 0,
      totalAnswers: data['total_answers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stars': stars,
      'streak': streak,
      'last_active_date': lastActiveDate?.toIso8601String(),
      'lessons_completed': totalLessonsCompleted,
      'quizzes_completed': totalQuizzesCompleted,
      'correct_answers': correctAnswers,
      'total_answers': totalAnswers,
    };
  }

  double get accuracy =>
      totalAnswers > 0 ? (correctAnswers / totalAnswers) * 100 : 0;

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
      totalLessonsCompleted:
          totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalQuizzesCompleted:
          totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswers: totalAnswers ?? this.totalAnswers,
    );
  }
}
