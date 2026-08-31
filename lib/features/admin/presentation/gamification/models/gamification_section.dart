import 'package:flutter/material.dart';

class GamificationSection {
  const GamificationSection({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.collectionId,
    required this.idField,
    required this.icon,
    required this.editableFields,
    required this.defaultDraft,
    this.readOnly = false,
  });

  final String key;
  final String title;
  final String subtitle;
  final String collectionId;
  final String idField;
  final IconData icon;
  final List<String> editableFields;
  final Map<String, dynamic> defaultDraft;
  final bool readOnly;
}

const gamificationSections = <String, GamificationSection>{
  'badges': GamificationSection(
    key: 'badges',
    title: 'Badges',
    subtitle: 'Names, descriptions, icons, categories, and unlock rules.',
    collectionId: 'badges',
    idField: 'badgeId',
    icon: Icons.emoji_events_rounded,
    editableFields: [
      'badgeId',
      'name',
      'description',
      'category',
      'icon',
      'target',
      'rewardStars',
      'unlockRule',
      'status',
      'isActive',
      'sortOrder',
    ],
    defaultDraft: {
      'name': 'First Lesson',
      'description': 'Complete your first Santali learning step.',
      'category': 'learning',
      'icon': '🏆',
      'target': 1,
      'rewardStars': 10,
      'unlockRule': '{}',
      'status': 'draft',
      'isActive': true,
      'sortOrder': 0,
    },
  ),
  'config': GamificationSection(
    key: 'config',
    title: 'Gamification Config',
    subtitle: 'Guardrailed global limits for badges, missions, and Bakhed.',
    collectionId: 'gamification_config',
    idField: 'configId',
    icon: Icons.tune_rounded,
    editableFields: [
      'configId',
      'bakhedCompletionThreshold',
      'quickWinEnabled',
      'badgesEnabled',
      'mistakeReviewEnabled',
    ],
    defaultDraft: {
      'configId': 'default',
      'bakhedCompletionThreshold': 80,
      'quickWinEnabled': true,
      'badgesEnabled': true,
      'mistakeReviewEnabled': true,
    },
  ),
  'audit_logs': GamificationSection(
    key: 'audit_logs',
    title: 'Audit Logs',
    subtitle: 'Admin changes, reward operations, and maintenance history.',
    collectionId: 'admin_audit_logs',
    idField: 'targetId',
    icon: Icons.history_rounded,
    editableFields: [],
    defaultDraft: {},
    readOnly: true,
  ),
  'learning_analytics_events': GamificationSection(
    key: 'learning_analytics_events',
    title: 'Learning Analytics Events',
    subtitle:
        'Privacy-safe product analytics for lessons, quizzes, streaks, and missions.',
    collectionId: 'learning_analytics_events',
    idField: 'eventId',
    icon: Icons.insights_rounded,
    editableFields: [],
    defaultDraft: {},
    readOnly: true,
  ),
  'learning_analytics_daily_rollups': GamificationSection(
    key: 'learning_analytics_daily_rollups',
    title: 'Learning Analytics Rollups',
    subtitle:
        'Nightly aggregated event totals for the admin analytics dashboard.',
    collectionId: 'learning_analytics_daily_rollups',
    idField: 'rollupId',
    icon: Icons.query_stats_rounded,
    editableFields: [],
    defaultDraft: {},
    readOnly: true,
  ),
  'bakhed_lyrics': GamificationSection(
    key: 'bakhed_lyrics',
    title: 'Bakhed Lyrics',
    subtitle: 'Timed Ol Chiki, Latin, and meaning lines for lyric mode.',
    collectionId: 'bakhed_lyrics',
    idField: 'bakhedId',
    icon: Icons.lyrics_rounded,
    editableFields: [
      'bakhedId',
      'lineIndex',
      'startMs',
      'endMs',
      'olChiki',
      'latin',
      'meaning',
    ],
    defaultDraft: {
      'bakhedId': 'seed_1',
      'lineIndex': 0,
      'startMs': 0,
      'endMs': 0,
      'olChiki': '',
      'latin': '',
      'meaning': '',
    },
  ),
  'bakhed_vocabulary': GamificationSection(
    key: 'bakhed_vocabulary',
    title: 'Bakhed Vocabulary',
    subtitle: 'Words learners practice after listening to a Bakhed.',
    collectionId: 'bakhed_vocabulary',
    idField: 'bakhedId',
    icon: Icons.menu_book_rounded,
    editableFields: [
      'bakhedId',
      'olChiki',
      'latin',
      'meaning',
      'audioFileId',
      'sortOrder',
    ],
    defaultDraft: {
      'bakhedId': 'seed_1',
      'olChiki': '',
      'latin': '',
      'meaning': '',
      'audioFileId': '',
      'sortOrder': 0,
    },
  ),
  'bakhed_notes': GamificationSection(
    key: 'bakhed_notes',
    title: 'Bakhed Cultural Notes',
    subtitle:
        'Published cultural context, source notes, and respectful learning copy.',
    collectionId: 'bakhed_cultural_notes',
    idField: 'noteId',
    icon: Icons.library_books_rounded,
    editableFields: [
      'noteId',
      'bakhedId',
      'title',
      'body',
      'source',
      'isPublished',
    ],
    defaultDraft: {
      'bakhedId': 'seed_1',
      'title': 'Cultural Note',
      'body': '',
      'source': '',
      'isPublished': false,
    },
  ),
};
