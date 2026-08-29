import 'dart:async';
import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../auth/appwrite_auth_service.dart';
import '../config/appwrite_config.dart';
import '../logging/app_logger.dart';
import '../storage/hive_service.dart';

typedef AnalyticsRemoteWriter =
    Future<void> Function(String eventId, Map<String, dynamic> payload);
typedef AnalyticsUserIdProvider = Future<String?> Function();

enum AdEventType { impression, click, reward, error, loadFail, dismissed }

class AdEvent {
  final AdEventType type;
  final String adFormat; // banner, interstitial, rewarded, native
  final String
  placement; // home_bottom, lesson_complete, quiz_reward, category_list
  final String? errorCode;
  final int? rewardAmount;
  final String? rewardType; // stars, quiz_attempt, hearts

  const AdEvent({
    required this.type,
    required this.adFormat,
    required this.placement,
    this.errorCode,
    this.rewardAmount,
    this.rewardType,
  });

  Map<String, dynamic> toMap() {
    return {
      'adFormat': adFormat,
      'placement': placement,
      if (errorCode != null) 'errorCode': errorCode,
      if (rewardAmount != null) 'rewardAmount': rewardAmount,
      if (rewardType != null) 'rewardType': rewardType,
    };
  }
}

class LearningAnalyticsEvents {
  const LearningAnalyticsEvents._();

  static const lessonStarted = 'lesson_started';
  static const lessonCompleted = 'lesson_completed';
  static const quizAttempted = 'quiz_attempted';
  static const quizCompleted = 'quiz_completed';
  static const quizQuestionAnswered = 'quiz_question_answered';
  static const streakMaintained = 'streak_maintained';
  static const streakMilestone = 'streak_milestone';
  static const dailyMissionCompleted = 'daily_mission_completed';
  static const letterPracticed = 'letter_practiced';
  static const practiceCompleted = 'practice_completed';

  // Ad events
  static const adImpression = 'ad_impression';
  static const adClick = 'ad_click';
  static const adRewardGranted = 'ad_reward_granted';
  static const adError = 'ad_error';
  static const adLoadFail = 'ad_load_fail';
  static const adDismissed = 'ad_dismissed';
}

class LearningAnalyticsService {
  LearningAnalyticsService({
    required SharedPreferences prefs,
    required AnalyticsRemoteWriter remoteWriter,
    AnalyticsUserIdProvider? userIdProvider,
    DateTime Function()? now,
    String Function()? idFactory,
  }) : _prefs = prefs,
       _remoteWriter = remoteWriter,
       _userIdProvider = userIdProvider,
       _now = now ?? DateTime.now,
       _idFactory = idFactory ?? const Uuid().v4;

  factory LearningAnalyticsService.appwrite({
    required SharedPreferences prefs,
    required AppwriteAuthService authService,
  }) {
    final tables = TablesDB(authService.client);
    return LearningAnalyticsService(
      prefs: prefs,
      userIdProvider: () async {
        try {
          final user = await authService.account.get().timeout(
            const Duration(seconds: 3),
          );
          return user.$id;
        } catch (_) {
          return null;
        }
      },
      remoteWriter: (eventId, payload) async {
        await tables
            .createRow(
              databaseId: AppwriteConfig.databaseId,
              tableId: collectionId,
              rowId: eventId,
              data: payload,
            )
            .timeout(const Duration(seconds: 4));
      },
    );
  }

  static const collectionId = 'learning_analytics_events';
  static const _pendingKey = 'pending_learning_analytics_events_v1';
  static const _sessionKey = 'learning_analytics_session_id';
  static const _maxPendingEvents = 80;
  static const _metadataMaxChars = 4096;

  final SharedPreferences _prefs;
  final AnalyticsRemoteWriter _remoteWriter;
  final AnalyticsUserIdProvider? _userIdProvider;
  final DateTime Function() _now;
  final String Function() _idFactory;

  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    Map<String, dynamic> metadata = const {},
    String? learnerLevel,
    String? scriptMode,
  }) async {
    final normalizedName = eventName.trim();
    if (normalizedName.isEmpty) return;

    final eventId = _safeId(_idFactory());
    final now = _now().toUtc();
    final payload = <String, dynamic>{
      'eventId': eventId,
      'eventName': normalizedName,
      'eventVersion': 1,
      'sessionId': _sessionId(),
      'source': _safeString(source, max: 80),
      'sourceId': _safeString(sourceId, max: 120),
      'userId': await _safeUserId(),
      'learnerLevel': _safeString(learnerLevel, max: 40),
      'scriptMode': _safeString(scriptMode, max: 40),
      'platform': _platformLabel(),
      'dateKey': _dateKey(now),
      'occurredAt': now.toIso8601String(),
      'metadata': _metadataJson(metadata),
    }..removeWhere((_, value) => value == null);

    await _writeOrQueue(eventId, payload);
  }

  /// Log AdMob monetization lifecycle and interaction event.
  Future<void> logAdEvent(AdEvent event) async {
    final eventName = switch (event.type) {
      AdEventType.impression => LearningAnalyticsEvents.adImpression,
      AdEventType.click => LearningAnalyticsEvents.adClick,
      AdEventType.reward => LearningAnalyticsEvents.adRewardGranted,
      AdEventType.error => LearningAnalyticsEvents.adError,
      AdEventType.loadFail => LearningAnalyticsEvents.adLoadFail,
      AdEventType.dismissed => LearningAnalyticsEvents.adDismissed,
    };

    await track(
      eventName,
      source: 'admob',
      sourceId: '${event.adFormat}_${event.placement}',
      metadata: event.toMap(),
    );
  }

  Future<void> flushPending() => _synchronized(() async {
    final pending = _pendingEvents();
    if (pending.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final item in pending) {
      final eventId = item['eventId']?.toString();
      if (eventId == null || eventId.isEmpty) continue;

      try {
        await _remoteWriter(eventId, Map<String, dynamic>.from(item));
      } catch (_) {
        remaining.add(item);
      }
    }

    await _savePending(remaining);
  });

  Future<void> _writeOrQueue(
    String eventId,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _remoteWriter(eventId, payload);
      unawaited(flushPending());
    } catch (e) {
      AppLogger.debug('LearningAnalytics: queued $eventId ($e)');
      await _queue(payload);
    }
  }

  Future<void> _queue(Map<String, dynamic> payload) => _synchronized(() async {
    final pending = _pendingEvents();
    pending.add(payload);
    final bounded = pending.length > _maxPendingEvents
        ? pending.sublist(pending.length - _maxPendingEvents)
        : pending;
    await _savePending(bounded);
  });

  Future<void>? _operationQueue;

  Future<T> _synchronized<T>(Future<T> Function() action) async {
    final previous = _operationQueue;
    final completer = Completer<void>();
    _operationQueue = completer.future;

    try {
      if (previous != null) {
        await previous.catchError((_) {});
      }
      return await action();
    } finally {
      completer.complete();
    }
  }

  List<Map<String, dynamic>> _pendingEvents() {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePending(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) {
      await _prefs.remove(_pendingKey);
      return;
    }
    await _prefs.setString(_pendingKey, jsonEncode(events));
  }

  static const _sessionLastActivityKey =
      'learning_analytics_session_last_activity_ts';
  static const Duration _sessionInactivityTimeout = Duration(minutes: 30);

  String _sessionId() {
    final nowMs = _now().millisecondsSinceEpoch;
    final existingSession = _prefs.getString(_sessionKey);
    final lastActivityMs = _prefs.getInt(_sessionLastActivityKey) ?? 0;

    final isExpired =
        (nowMs - lastActivityMs) > _sessionInactivityTimeout.inMilliseconds;

    if (existingSession != null && existingSession.isNotEmpty && !isExpired) {
      _prefs.setInt(_sessionLastActivityKey, nowMs);
      return existingSession;
    }

    final newSessionId = _safeId(_idFactory());
    _prefs.setString(_sessionKey, newSessionId);
    _prefs.setInt(_sessionLastActivityKey, nowMs);
    return newSessionId;
  }

  Future<String?> _safeUserId() async {
    try {
      final userId = await _userIdProvider?.call();
      return _safeString(userId, max: 80);
    } catch (_) {
      return null;
    }
  }

  static String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  static String _safeId(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceFirst(RegExp(r'^[^a-zA-Z0-9]+'), '');
    if (cleaned.isEmpty) return const Uuid().v4();
    return cleaned.length <= 36 ? cleaned : cleaned.substring(0, 36);
  }

  static String? _safeString(String? value, {required int max}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= max ? trimmed : trimmed.substring(0, max);
  }

  static String _metadataJson(Map<String, dynamic> metadata) {
    final sanitized = _sanitizeMetadata(metadata);
    String encoded = jsonEncode(sanitized);
    if (encoded.length > _metadataMaxChars) {
      final pruned = Map<String, dynamic>.from(sanitized);
      final keys = pruned.keys.toList();
      for (final key in keys) {
        if (encoded.length <= _metadataMaxChars) break;
        pruned.remove(key);
        encoded = jsonEncode(pruned);
      }
    }
    return encoded;
  }

  static Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> input) {
    final output = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key.trim();
      if (key.isEmpty || _isSensitiveKey(key)) continue;
      output[key] = _sanitizeValue(entry.value);
    }
    return output;
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('email') ||
        lower.contains('phone') ||
        lower.contains('password') ||
        lower.contains('secret') ||
        lower.contains('token');
  }

  static Object? _sanitizeValue(Object? value) {
    if (value == null || value is num || value is bool) return value;
    if (value is String) return _safeString(value, max: 256);
    if (value is Iterable) {
      return value.take(20).map(_sanitizeValue).toList();
    }
    if (value is Map) {
      return _sanitizeMetadata(Map<String, dynamic>.from(value));
    }
    return _safeString(value.toString(), max: 256);
  }
}

final learningAnalyticsServiceProvider = Provider<LearningAnalyticsService>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  try {
    return LearningAnalyticsService.appwrite(
      prefs: prefs,
      authService: ref.watch(appwriteAuthServiceProvider),
    );
  } catch (e) {
    AppLogger.debug('LearningAnalytics: Appwrite unavailable ($e)');
    return LearningAnalyticsService(
      prefs: prefs,
      remoteWriter: (eventId, payload) async => throw e,
    );
  }
});
