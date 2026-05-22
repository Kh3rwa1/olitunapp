import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/appwrite_db_service.dart';
import '../../core/auth/appwrite_auth_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/storage/cache_service.dart';

class GamificationContent {
  const GamificationContent({
    required this.bravoMessages,
    required this.badges,
    required this.missionTemplates,
    required this.rewardMessages,
    required this.quizFeedbackMessages,
    required this.config,
    required this.loadedFromFallback,
  });

  final List<Map<String, dynamic>> bravoMessages;
  final List<Map<String, dynamic>> badges;
  final List<Map<String, dynamic>> missionTemplates;
  final List<Map<String, dynamic>> rewardMessages;
  final List<Map<String, dynamic>> quizFeedbackMessages;
  final Map<String, dynamic> config;
  final bool loadedFromFallback;

  Map<String, dynamic> toJson() => {
    'bravoMessages': bravoMessages,
    'badges': badges,
    'missionTemplates': missionTemplates,
    'rewardMessages': rewardMessages,
    'quizFeedbackMessages': quizFeedbackMessages,
    'config': config,
    'loadedFromFallback': loadedFromFallback,
  };

  factory GamificationContent.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> readList(String key) {
      final value = json[key];
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false);
    }

    final config = json['config'];
    return GamificationContent(
      bravoMessages: readList('bravoMessages'),
      badges: readList('badges'),
      missionTemplates: readList('missionTemplates'),
      rewardMessages: readList('rewardMessages'),
      quizFeedbackMessages: readList('quizFeedbackMessages'),
      config: config is Map ? Map<String, dynamic>.from(config) : const {},
      loadedFromFallback: json['loadedFromFallback'] == true,
    );
  }

  static GamificationContent fallback() => const GamificationContent(
    bravoMessages: [
      {
        'messageId': 'fallback_lesson_completed',
        'trigger': 'lesson_completed',
        'title': 'Nice learning step',
        'body': 'You gave Santali practice real attention today.',
        'language': 'en',
        'scriptMode': 'both',
        'learnerLevel': 'all',
        'weight': 1,
        'status': 'published',
        'isActive': true,
      },
      {
        'messageId': 'fallback_mistake_mastered',
        'trigger': 'mistake_mastered',
        'title': 'Second chance, stronger memory',
        'body': 'Mistakes are just lessons asking for a second chance.',
        'language': 'en',
        'scriptMode': 'both',
        'learnerLevel': 'all',
        'weight': 1,
        'status': 'published',
        'isActive': true,
      },
    ],
    badges: [
      {
        'badgeId': 'first_lesson',
        'name': 'First Lesson',
        'description': 'Complete your first Santali learning step.',
        'category': 'learning',
        'icon': '🏆',
        'target': 1,
        'rewardStars': 10,
        'status': 'published',
        'isActive': true,
      },
      {
        'badgeId': 'first_bakhed',
        'name': 'First Bakhed',
        'description': 'Listen to a Bakhed and connect learning with culture.',
        'category': 'culture',
        'icon': '🌱',
        'target': 1,
        'rewardStars': 10,
        'status': 'published',
        'isActive': true,
      },
    ],
    missionTemplates: [
      {
        'missionId': 'complete_1_lesson',
        'title': 'Complete 1 lesson',
        'description': 'Take one focused step in your learning path.',
        'type': 'lesson_completed',
        'targetCount': 1,
        'rewardStars': 25,
        'status': 'published',
        'isActive': true,
      },
      {
        'missionId': 'listen_1_bakhed',
        'title': 'Listen to 1 Bakhed',
        'description': 'Listen to 80% or more to count it for today.',
        'type': 'bakhed_completed_80_percent',
        'targetCount': 1,
        'rewardStars': 20,
        'status': 'published',
        'isActive': true,
      },
    ],
    rewardMessages: [
      {
        'messageId': 'fallback_stars',
        'trigger': 'stars_awarded',
        'title': 'Stars earned',
        'body': 'Your practice was counted.',
        'rewardLabel': 'Stars',
        'icon': '⭐',
        'status': 'published',
        'isActive': true,
      },
    ],
    quizFeedbackMessages: [
      {
        'messageId': 'fallback_correct',
        'type': 'correct',
        'title': 'Correct',
        'body': 'Good recognition. Keep the sound and meaning together.',
        'status': 'published',
        'isActive': true,
      },
      {
        'messageId': 'fallback_review_needed',
        'type': 'review_needed',
        'title': 'Worth reviewing',
        'body': 'Save this for mistake review and try it again soon.',
        'status': 'published',
        'isActive': true,
      },
    ],
    config: {
      'configId': 'default',
      'bakhedCompletionThreshold': 80,
      'streakShieldMax': 2,
      'quickWinEnabled': true,
      'badgesEnabled': true,
      'mistakeReviewEnabled': true,
    },
    loadedFromFallback: true,
  );
}

final gamificationContentProvider = FutureProvider<GamificationContent>((
  ref,
) async {
  const cacheKey = 'gamification_content_v1';
  GamificationContent? cached;
  if (CacheService.isOpen) {
    try {
      cached = await CacheService.get(cacheKey, GamificationContent.fromJson);
    } catch (e) {
      AppLogger.debug('GamificationContent: cache read skipped: $e');
    }
  }

  try {
    final db = ref.read(appwriteDbServiceProvider);
    final publishedActive = [
      Query.equal('status', 'published'),
      Query.equal('isActive', true),
      Query.limit(500),
    ];

    final results = await Future.wait([
      db.listDocuments('bravo_messages', queries: publishedActive),
      db.listDocuments(
        'badges',
        queries: [
          Query.equal('status', 'published'),
          Query.equal('isActive', true),
          Query.orderAsc('sortOrder'),
          Query.limit(500),
        ],
      ),
      db.listDocuments(
        'mission_templates',
        queries: [
          Query.equal('status', 'published'),
          Query.equal('isActive', true),
          Query.orderAsc('sortOrder'),
          Query.limit(500),
        ],
      ),
      db.listDocuments('reward_messages', queries: publishedActive),
      db.listDocuments('quiz_feedback_messages', queries: publishedActive),
      db.listDocuments(
        'gamification_config',
        queries: [Query.equal('configId', 'default'), Query.limit(1)],
      ),
    ]);

    final remote = GamificationContent(
      bravoMessages: results[0],
      badges: results[1],
      missionTemplates: results[2],
      rewardMessages: results[3],
      quizFeedbackMessages: results[4],
      config: results[5].isNotEmpty
          ? results[5].first
          : GamificationContent.fallback().config,
      loadedFromFallback: false,
    );
    if (CacheService.isOpen) {
      await CacheService.set(cacheKey, remote.toJson());
    }
    return remote;
  } catch (e) {
    AppLogger.debug('GamificationContent: remote load failed: $e');
    return cached ?? GamificationContent.fallback();
  }
});

class UserGamificationBadge {
  final String badgeId;
  final String name;
  final String description;
  final String category;
  final String icon;
  final int progress;
  final int target;
  final int rewardStars;
  final bool isUnlocked;
  final String unlockedAt;

  const UserGamificationBadge({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.progress,
    required this.target,
    required this.rewardStars,
    required this.isUnlocked,
    required this.unlockedAt,
  });

  factory UserGamificationBadge.fromJson(Map<String, dynamic> json) {
    return UserGamificationBadge(
      badgeId: _readString(json['badgeId']),
      name: _readString(json['name'], fallback: 'Learning badge'),
      description: _readString(
        json['description'],
        fallback: 'Keep learning to unlock this badge.',
      ),
      category: _readString(json['category'], fallback: 'learning'),
      icon: _readString(json['icon'], fallback: '🏆'),
      progress: _readInt(json['progress']),
      target: _readInt(json['target'], fallback: 1),
      rewardStars: _readInt(json['rewardStars']),
      isUnlocked: json['isUnlocked'] == true,
      unlockedAt: _readString(json['unlockedAt']),
    );
  }
}

class UserStreakShieldSummary {
  final int availableShields;
  final int maxShields;
  final String earnedAt;
  final String usedAt;

  const UserStreakShieldSummary({
    this.availableShields = 0,
    this.maxShields = 2,
    this.earnedAt = '',
    this.usedAt = '',
  });

  factory UserStreakShieldSummary.fromJson(Map<String, dynamic> json) {
    return UserStreakShieldSummary(
      availableShields: _readInt(json['availableShields']),
      maxShields: _readInt(json['maxShields'], fallback: 2),
      earnedAt: _readString(json['earnedAt']),
      usedAt: _readString(json['usedAt']),
    );
  }
}

class UserGamificationSummary {
  final List<UserGamificationBadge> badges;
  final UserStreakShieldSummary streakShields;
  final List<Map<String, dynamic>> recentRewards;

  const UserGamificationSummary({
    this.badges = const [],
    this.streakShields = const UserStreakShieldSummary(),
    this.recentRewards = const [],
  });

  factory UserGamificationSummary.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['badges'];
    final rawShields = json['streakShields'];
    final rawRewards = json['recentRewards'];
    return UserGamificationSummary(
      badges: rawBadges is List
          ? rawBadges
                .whereType<Map>()
                .map(
                  (item) => UserGamificationBadge.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      streakShields: rawShields is Map
          ? UserStreakShieldSummary.fromJson(
              Map<String, dynamic>.from(rawShields),
            )
          : const UserStreakShieldSummary(),
      recentRewards: rawRewards is List
          ? rawRewards
                .whereType<Map>()
                .map(Map<String, dynamic>.from)
                .toList(growable: false)
          : const [],
    );
  }

  static const empty = UserGamificationSummary();
}

final userGamificationSummaryProvider = FutureProvider<UserGamificationSummary>(
  (ref) async {
    try {
      final functions = Functions(ref.read(appwriteAuthServiceProvider).client);
      final response = await functions.createExecution(
        functionId: 'getUserGamificationSummary',
        body: jsonEncode({}),
      );
      if (response.status.name != 'completed') {
        return UserGamificationSummary.empty;
      }
      final decoded = jsonDecode(response.responseBody);
      if (decoded is! Map || decoded['ok'] != true) {
        return UserGamificationSummary.empty;
      }
      return UserGamificationSummary.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      AppLogger.debug('UserGamificationSummary fallback: $e');
      return UserGamificationSummary.empty;
    }
  },
);

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
