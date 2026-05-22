import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/appwrite_db_service.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_page_header.dart';
import '../settings/controllers/admin_maintenance_controller.dart';

class AdminGamificationScreen extends ConsumerStatefulWidget {
  const AdminGamificationScreen({super.key, required this.section});

  final String section;

  @override
  ConsumerState<AdminGamificationScreen> createState() =>
      _AdminGamificationScreenState();
}

class _GamificationSection {
  const _GamificationSection({
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

const _sections = <String, _GamificationSection>{
  'copy': _GamificationSection(
    key: 'copy',
    title: 'Gamification Copy',
    subtitle: 'Bravo messages and gentle learning encouragement.',
    collectionId: 'bravo_messages',
    idField: 'messageId',
    icon: Icons.tips_and_updates_rounded,
    editableFields: [
      'messageId',
      'trigger',
      'title',
      'body',
      'language',
      'scriptMode',
      'learnerLevel',
      'weight',
      'status',
      'isActive',
    ],
    defaultDraft: {
      'trigger': 'lesson_completed',
      'title': 'Nice learning step',
      'body': 'You gave Santali practice real attention today.',
      'language': 'en',
      'scriptMode': 'both',
      'learnerLevel': 'all',
      'weight': 1,
      'status': 'draft',
      'isActive': true,
    },
  ),
  'badges': _GamificationSection(
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
  'circle_templates': _GamificationSection(
    key: 'circle_templates',
    title: 'Circle Templates',
    subtitle: 'Weekly Learning Circle names, subtitles, themes, and icons.',
    collectionId: 'learning_circle_templates',
    idField: 'templateId',
    icon: Icons.groups_rounded,
    editableFields: [
      'templateId',
      'name',
      'subtitle',
      'description',
      'learnerLevel',
      'theme',
      'icon',
      'status',
      'isActive',
      'sortOrder',
    ],
    defaultDraft: {
      'name': 'Ol Chiki Starter Circle',
      'subtitle': 'You are warming up while more learners join.',
      'description': 'A gentle weekly circle for beginner learners.',
      'learnerLevel': 'beginner',
      'theme': 'leaf',
      'icon': '🌱',
      'status': 'draft',
      'isActive': true,
      'sortOrder': 0,
    },
  ),
  'missions': _GamificationSection(
    key: 'missions',
    title: 'Mission Templates',
    subtitle: 'Daily missions, quick wins, rewards, and circle points.',
    collectionId: 'mission_templates',
    idField: 'missionId',
    icon: Icons.flag_rounded,
    editableFields: [
      'missionId',
      'title',
      'description',
      'type',
      'targetCount',
      'rewardStars',
      'circlePoints',
      'learnerLevel',
      'isQuickWin',
      'status',
      'isActive',
      'sortOrder',
    ],
    defaultDraft: {
      'title': 'Complete 1 lesson',
      'description': 'Take one focused step in your learning path.',
      'type': 'lesson_completed',
      'targetCount': 1,
      'rewardStars': 25,
      'circlePoints': 40,
      'learnerLevel': 'all',
      'isQuickWin': false,
      'status': 'draft',
      'isActive': true,
      'sortOrder': 0,
    },
  ),
  'rewards': _GamificationSection(
    key: 'rewards',
    title: 'Reward Messages',
    subtitle: 'Reward, streak shield, and badge celebration copy.',
    collectionId: 'reward_messages',
    idField: 'messageId',
    icon: Icons.star_rounded,
    editableFields: [
      'messageId',
      'trigger',
      'title',
      'body',
      'rewardLabel',
      'icon',
      'status',
      'isActive',
    ],
    defaultDraft: {
      'trigger': 'stars_awarded',
      'title': 'Stars earned',
      'body': 'Your practice was counted.',
      'rewardLabel': 'Stars',
      'icon': '⭐',
      'status': 'draft',
      'isActive': true,
    },
  ),
  'quiz_feedback': _GamificationSection(
    key: 'quiz_feedback',
    title: 'Quiz Feedback',
    subtitle: 'Generic quiz learning feedback. Scoring remains backend-owned.',
    collectionId: 'quiz_feedback_messages',
    idField: 'messageId',
    icon: Icons.quiz_rounded,
    editableFields: [
      'messageId',
      'type',
      'title',
      'body',
      'status',
      'isActive',
    ],
    defaultDraft: {
      'type': 'correct',
      'title': 'Correct',
      'body': 'Good recognition. Keep the sound and meaning together.',
      'status': 'draft',
      'isActive': true,
    },
  ),
  'config': _GamificationSection(
    key: 'config',
    title: 'Gamification Config',
    subtitle: 'Guardrailed global limits for circles, shields, and Bakhed.',
    collectionId: 'gamification_config',
    idField: 'configId',
    icon: Icons.tune_rounded,
    editableFields: [
      'configId',
      'weeklyCircleMaxMembers',
      'weeklyCircleMinActiveMembers',
      'bakhedCompletionThreshold',
      'streakShieldMax',
      'quickWinEnabled',
      'weeklyCircleEnabled',
      'badgesEnabled',
      'mistakeReviewEnabled',
    ],
    defaultDraft: {
      'configId': 'default',
      'weeklyCircleMaxMembers': 20,
      'weeklyCircleMinActiveMembers': 8,
      'bakhedCompletionThreshold': 80,
      'streakShieldMax': 2,
      'quickWinEnabled': true,
      'weeklyCircleEnabled': true,
      'badgesEnabled': true,
      'mistakeReviewEnabled': true,
    },
  ),
  'audit_logs': _GamificationSection(
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
  'circle_events': _GamificationSection(
    key: 'circle_events',
    title: 'Circle Events',
    subtitle: 'Backend-recorded scoring events and duplicate prevention trail.',
    collectionId: 'circle_events',
    idField: 'sourceId',
    icon: Icons.timeline_rounded,
    editableFields: [],
    defaultDraft: {},
    readOnly: true,
  ),
  'learning_analytics_events': _GamificationSection(
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
  'circles': _GamificationSection(
    key: 'circles',
    title: 'Weekly Circles',
    subtitle: 'Open, full, locked, and closed weekly learning circles.',
    collectionId: 'weekly_circles',
    idField: 'circleId',
    icon: Icons.group_work_rounded,
    editableFields: ['circleName', 'status', 'theme', 'icon'],
    defaultDraft: {},
    readOnly: true,
  ),
  'bakhed_lyrics': _GamificationSection(
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
  'bakhed_vocabulary': _GamificationSection(
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
  'bakhed_notes': _GamificationSection(
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

class _AdminGamificationScreenState
    extends ConsumerState<AdminGamificationScreen> {
  String _search = '';
  String _status = 'all';
  int _reload = 0;
  bool _maintenanceBusy = false;
  String? _maintenanceMessage;

  _GamificationSection? get _section => _sections[widget.section];

  @override
  Widget build(BuildContext context) {
    if (widget.section == 'overview') {
      return _buildOverview(context);
    }
    if (widget.section == 'analytics') {
      return _buildAnalytics(context);
    }
    if (widget.section == 'maintenance') {
      return _buildMaintenance(context);
    }

    final section = _section;
    if (section == null) {
      return const Center(child: Text('Unknown gamification section'));
    }

    final isWide = MediaQuery.of(context).size.width > 860;
    final future = _loadRows(section, _reload);

    return Padding(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: section.title,
            subtitle: section.subtitle,
            eyebrow: 'GAMIFICATION',
            actions: [
              if (!section.readOnly)
                ElevatedButton.icon(
                  onPressed: () => _createDraft(section),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilters(context),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: SelectableText(
                      'Could not load ${section.title}: ${snapshot.error}',
                    ),
                  );
                }
                final rows = _filterRows(snapshot.data ?? const []);
                if (rows.isEmpty) {
                  final hasFilters =
                      _search.trim().isNotEmpty || _status != 'all';
                  return AdminEmptyState(
                    icon: section.icon,
                    title: hasFilters
                        ? 'No matching content'
                        : section.readOnly
                        ? 'No activity yet'
                        : 'No ${section.title.toLowerCase()} yet',
                    message: hasFilters
                        ? 'Clear search or filters to view all records.'
                        : section.readOnly
                        ? 'Records will appear here after real learner or backend activity.'
                        : 'Create the first admin-managed record for this section.',
                    actionLabel: !section.readOnly && !hasFilters
                        ? 'Create'
                        : null,
                    onAction: !section.readOnly && !hasFilters
                        ? () => _createDraft(section)
                        : null,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildRowCard(context, section, rows[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    final cards = _sections.values
        .where((section) => section.key != 'audit_logs')
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            title: 'Gamification CMS',
            subtitle:
                'Admin-managed copy, badges, circles, missions, rewards, config, and scoring traces.',
            eyebrow: 'PRODUCT OPS',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1,
                childAspectRatio: isWide ? 2.4 : 3.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final section = cards[index];
                return _OverviewCard(
                  section: section,
                  onTap: () => context.go(_pathForSection(section.key)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    return Padding(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminPageHeader(
            title: 'Learning Health Analytics',
            subtitle:
                'Real product signals across circles, rewards, mistakes, Bakhed, and content quality.',
            eyebrow: 'PRODUCT OPS',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Map<String, int>>(
              future: _loadAnalyticsMetrics(_reload),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: SelectableText(
                      'Could not load analytics: ${snapshot.error}',
                    ),
                  );
                }
                final metrics = snapshot.data ?? const <String, int>{};
                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 4 : 2,
                    childAspectRatio: isWide ? 1.8 : 1.35,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  children: [
                    for (final entry in metrics.entries)
                      _OpsMetricCard(label: entry.key, value: entry.value),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _loadAnalyticsMetrics(int reload) async {
    final db = ref.read(appwriteDbServiceProvider);
    Future<int> count(String collectionId, {List<String>? queries}) async {
      try {
        final rows = await db.listDocuments(
          collectionId,
          queries: [Query.limit(500), ...?queries],
          paginate: false,
        );
        return rows.length;
      } catch (_) {
        return 0;
      }
    }

    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final values = await Future.wait<int>([
      count('weekly_circles'),
      count('weekly_circles', queries: [Query.equal('status', 'open')]),
      count('weekly_circles', queries: [Query.equal('status', 'full')]),
      count('circle_members'),
      count('circle_events', queries: [Query.greaterThan('createdAt', today)]),
      count(
        'learning_analytics_events',
        queries: [Query.greaterThan('occurredAt', today)],
      ),
      count(
        'learning_analytics_events',
        queries: [Query.equal('eventName', 'lesson_completed')],
      ),
      count(
        'learning_analytics_events',
        queries: [Query.equal('eventName', 'quiz_attempted')],
      ),
      count(
        'learning_analytics_events',
        queries: [Query.equal('eventName', 'streak_milestone')],
      ),
      count('user_badges', queries: [Query.equal('isUnlocked', true)]),
      count('streak_shields'),
      count('mistake_review_sessions'),
      count('user_mistakes', queries: [Query.equal('isMastered', false)]),
      count(
        'bakhed_listening_progress',
        queries: [Query.equal('completed80Percent', true)],
      ),
      count('bakhed_lyrics'),
      count('bakhed_vocabulary'),
      count(
        'bakhed_cultural_notes',
        queries: [Query.equal('isPublished', true)],
      ),
    ]);
    return {
      'Active weekly circles': values[0],
      'Open circles': values[1],
      'Full circles': values[2],
      'Circle participants': values[3],
      'Events today': values[4],
      'Learning events today': values[5],
      'Lessons completed': values[6],
      'Quiz attempts': values[7],
      'Streak milestones': values[8],
      'Unlocked badges': values[9],
      'Streak shield records': values[10],
      'Mistake reviews completed': values[11],
      'Mistakes needing practice': values[12],
      'Bakhed 80% completions': values[13],
      'Bakhed lyric lines': values[14],
      'Bakhed vocabulary words': values[15],
      'Published cultural notes': values[16],
    };
  }

  Widget _buildMaintenance(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    return Padding(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Maintenance',
            subtitle:
                'Backups, schema health, and production readiness checks without exposing secrets.',
            eyebrow: 'PRODUCT OPS',
            actions: [
              ElevatedButton.icon(
                onPressed: _maintenanceBusy ? null : _createContentBackup,
                icon: const Icon(Icons.backup_rounded, size: 18),
                label: const Text('Create backup'),
              ),
              IconButton(
                tooltip: 'Refresh health',
                onPressed: () => setState(() => _reload++),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (_maintenanceMessage != null) ...[
            const SizedBox(height: 12),
            SelectableText(_maintenanceMessage!),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Map<String, bool>>(
              future: _loadSchemaHealth(_reload),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data ?? const <String, bool>{};
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = rows.entries.elementAt(index);
                    return ListTile(
                      leading: Icon(
                        entry.value
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: entry.value
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      title: Text(entry.key),
                      subtitle: Text(
                        entry.value
                            ? 'Available'
                            : 'Missing or not readable with current admin permissions',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, bool>> _loadSchemaHealth(int reload) async {
    final requiredCollections = [
      'bravo_messages',
      'badges',
      'user_badges',
      'learning_circle_templates',
      'mission_templates',
      'reward_messages',
      'quiz_feedback_messages',
      'gamification_config',
      'admin_audit_logs',
      'learning_analytics_events',
      'weekly_circles',
      'circle_members',
      'circle_events',
      'weekly_circle_recaps',
      'reward_events',
      'user_mistakes',
      'mistake_review_sessions',
      'streak_shields',
      'bakhed_lyrics',
      'bakhed_vocabulary',
      'bakhed_cultural_notes',
      'bakhed_listening_progress',
    ];
    final db = ref.read(appwriteDbServiceProvider);
    final entries = <String, bool>{};
    for (final collection in requiredCollections) {
      try {
        await db.listDocuments(
          collection,
          queries: [Query.limit(1)],
          paginate: false,
        );
        entries[collection] = true;
      } catch (_) {
        entries[collection] = false;
      }
    }
    return entries;
  }

  Future<void> _createContentBackup() async {
    setState(() {
      _maintenanceBusy = true;
      _maintenanceMessage = 'Creating backup...';
    });
    try {
      final fileId = await AdminMaintenanceController(ref).backupContent();
      setState(() {
        _maintenanceMessage = 'Backup created: ${fileId ?? 'completed'}';
      });
      await _audit('backup_created', 'admin_backups', fileId ?? 'unknown', {
        'source': 'maintenance_screen',
      });
    } catch (e) {
      setState(() {
        _maintenanceMessage = 'Backup failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _maintenanceBusy = false);
      }
    }
  }

  Widget _buildFilters(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        DropdownButton<String>(
          value: _status,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'draft', child: Text('Draft')),
            DropdownMenuItem(value: 'published', child: Text('Published')),
            DropdownMenuItem(value: 'archived', child: Text('Archived')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
          ],
          onChanged: (value) => setState(() => _status = value ?? 'all'),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => setState(() => _reload++),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildRowCard(
    BuildContext context,
    _GamificationSection section,
    Map<String, dynamic> row,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _titleFor(row, section);
    final subtitle = _subtitleFor(row);
    final status = row['status']?.toString() ?? '';
    final active = row['isActive'] == true;
    final supportsStatus = section.editableFields.contains('status');
    final supportsPublish =
        supportsStatus || section.collectionId == 'bakhed_cultural_notes';

    return Card(
      elevation: 0,
      color: AdminTokens.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AdminTokens.border(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminTokens.accentSoft(isDark),
                  child: Icon(section.icon, color: AdminTokens.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AdminTokens.cardTitle(isDark)),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AdminTokens.body(isDark),
                        ),
                    ],
                  ),
                ),
                if (status.isNotEmpty)
                  _StatusPill(label: status, color: _statusColor(status)),
                if (active) ...[
                  const SizedBox(width: 8),
                  const _StatusPill(label: 'active', color: AppColors.success),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showPreview(section, row),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Preview'),
                ),
                if (!section.readOnly)
                  OutlinedButton.icon(
                    onPressed: () => _editRow(section, row),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
                if (!section.readOnly && supportsPublish)
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(section, row, 'published'),
                    icon: const Icon(Icons.publish_rounded, size: 16),
                    label: const Text('Publish'),
                  ),
                if (!section.readOnly && supportsPublish)
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(section, row, 'draft'),
                    icon: const Icon(Icons.visibility_off_rounded, size: 16),
                    label: const Text('Unpublish'),
                  ),
                if (!section.readOnly && supportsStatus)
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus(section, row, 'archived'),
                    icon: const Icon(Icons.archive_rounded, size: 16),
                    label: const Text('Archive'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadRows(
    _GamificationSection section,
    int reload,
  ) async {
    final db = ref.read(appwriteDbServiceProvider);
    final queries = <String>[Query.limit(500)];
    if (section.collectionId == 'admin_audit_logs') {
      queries.add(Query.orderDesc('createdAt'));
    } else if (section.editableFields.contains('sortOrder')) {
      queries.add(Query.orderAsc('sortOrder'));
    }
    return db.listDocuments(section.collectionId, queries: queries);
  }

  List<Map<String, dynamic>> _filterRows(List<Map<String, dynamic>> rows) {
    final query = _search.trim().toLowerCase();
    return rows
        .where((row) {
          final status = row['status']?.toString().toLowerCase();
          final isActive = row['isActive'] == true;
          final statusMatches = switch (_status) {
            'all' => true,
            'active' => isActive,
            'inactive' => !isActive,
            _ => status == _status,
          };
          if (!statusMatches) return false;
          if (query.isEmpty) return true;
          return jsonEncode(row).toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _createDraft(_GamificationSection section) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final generatedId =
        '${section.key}_${DateTime.now().millisecondsSinceEpoch}';
    final id = section.key.startsWith('bakhed_')
        ? generatedId
        : section.defaultDraft[section.idField]?.toString().isNotEmpty == true
        ? section.defaultDraft[section.idField].toString()
        : generatedId;
    final draft = {
      ...section.defaultDraft,
      section.idField: id,
      'version': 1,
      'createdAt': now,
      'updatedAt': now,
    };

    await ref
        .read(appwriteDbServiceProvider)
        .createDocument(section.collectionId, id, draft);
    await _audit('${section.key}_created', section.collectionId, id, draft);
    HapticFeedback.selectionClick();
    setState(() => _reload++);
  }

  Future<void> _updateStatus(
    _GamificationSection section,
    Map<String, dynamic> row,
    String status,
  ) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    final payload = section.collectionId == 'bakhed_cultural_notes'
        ? {'isPublished': status == 'published'}
        : {
            'status': status,
            'isActive': status == 'published',
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          };
    await ref
        .read(appwriteDbServiceProvider)
        .updateDocument(section.collectionId, id, payload);
    await _audit('${section.key}_$status', section.collectionId, id, payload);
    setState(() => _reload++);
  }

  Future<void> _editRow(
    _GamificationSection section,
    Map<String, dynamic> row,
  ) async {
    final controllers = {
      for (final field in section.editableFields)
        field: TextEditingController(text: row[field]?.toString() ?? ''),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Edit ${section.title}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                ...controllers.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: entry.value,
                      minLines:
                          entry.key == 'body' || entry.key == 'description'
                          ? 3
                          : 1,
                      maxLines:
                          entry.key == 'body' || entry.key == 'description'
                          ? 6
                          : 1,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final id = row['id']?.toString();
                    if (id == null || id.isEmpty) return;
                    final payload = <String, dynamic>{};
                    for (final entry in controllers.entries) {
                      final oldValue = row[entry.key];
                      payload[entry.key] = _coerceValue(
                        entry.value.text.trim(),
                        oldValue,
                      );
                    }
                    payload['updatedAt'] = DateTime.now()
                        .toUtc()
                        .toIso8601String();
                    await ref
                        .read(appwriteDbServiceProvider)
                        .updateDocument(section.collectionId, id, payload);
                    await _audit(
                      '${section.key}_updated',
                      section.collectionId,
                      id,
                      payload,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    if (mounted) setState(() => _reload++);
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Object? _coerceValue(String value, Object? oldValue) {
    if (oldValue is bool) return value.toLowerCase() == 'true';
    if (oldValue is int) return int.tryParse(value) ?? oldValue;
    return value;
  }

  Future<void> _audit(
    String action,
    String targetType,
    String targetId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await ref
          .read(appwriteDbServiceProvider)
          .createDocument('admin_audit_logs', ID.unique(), {
            'action': action,
            'targetType': targetType,
            'targetId': targetId,
            'metadata': jsonEncode(metadata),
            'success': true,
            'createdAt': now,
          });
    } catch (_) {
      // Do not block the admin operation if audit logging is unavailable.
    }
  }

  void _showPreview(_GamificationSection section, Map<String, dynamic> row) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${section.title} Preview'),
        content: SizedBox(
          width: 720,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _PreviewCard(label: 'Light', row: row, dark: false),
              _PreviewCard(label: 'Dark', row: row, dark: true),
              SizedBox(
                width: 360,
                child: _PreviewCard(
                  label: 'Small Screen',
                  row: row,
                  dark: false,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _titleFor(Map<String, dynamic> row, _GamificationSection section) {
    for (final key in ['title', 'name', section.idField, 'action']) {
      final value = row[key]?.toString();
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return row['id']?.toString() ?? 'Untitled';
  }

  String _subtitleFor(Map<String, dynamic> row) {
    for (final key in [
      'body',
      'description',
      'subtitle',
      'meaning',
      'latin',
      'olChiki',
      'trigger',
      'type',
      'sourceId',
    ]) {
      final value = row[key]?.toString();
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return '';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'published' => AppColors.success,
      'archived' => Colors.blueGrey,
      'draft' => AppColors.duoOrange,
      _ => AppColors.primary,
    };
  }

  String _pathForSection(String key) {
    return switch (key) {
      'copy' => '/admin/gamification/copy',
      'badges' => '/admin/gamification/badges',
      'circle_templates' => '/admin/gamification/circles/templates',
      'missions' => '/admin/gamification/missions',
      'rewards' => '/admin/gamification/rewards',
      'quiz_feedback' => '/admin/gamification/quiz-feedback',
      'config' => '/admin/gamification/config',
      'circle_events' => '/admin/gamification/events',
      'circles' => '/admin/gamification/circles',
      'bakhed_lyrics' => '/admin/gamification/bakhed/lyrics',
      'bakhed_vocabulary' => '/admin/gamification/bakhed/vocabulary',
      'bakhed_notes' => '/admin/gamification/bakhed/cultural-notes',
      _ => '/admin/gamification',
    };
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.section, required this.onTap});

  final _GamificationSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTokens.border(isDark)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AdminTokens.accentSoft(isDark),
              child: Icon(section.icon, color: AdminTokens.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AdminTokens.cardTitle(isDark)),
                  const SizedBox(height: 4),
                  Text(
                    section.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTokens.body(isDark),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OpsMetricCard extends StatelessWidget {
  const _OpsMetricCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: AdminTokens.accent,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AdminTokens.body(isDark),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.label,
    required this.row,
    required this.dark,
  });

  final String label;
  final Map<String, dynamic> row;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final title =
        row['title']?.toString() ??
        row['name']?.toString() ??
        row['rewardLabel']?.toString() ??
        'Preview';
    final body =
        row['body']?.toString() ??
        row['description']?.toString() ??
        row['subtitle']?.toString() ??
        'No preview copy yet.';
    final icon = row['icon']?.toString() ?? '🌱';

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: dark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: dark ? Colors.white70 : Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
