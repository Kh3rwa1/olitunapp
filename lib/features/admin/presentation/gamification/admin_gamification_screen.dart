import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gamification_cms_api.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/common/admin_modal_sheet.dart';
import 'models/gamification_section.dart';
import 'views/gamification_analytics_view.dart';
import 'views/gamification_maintenance_view.dart';
import 'views/gamification_overview_view.dart';
import 'widgets/gamification_row_card.dart';
import 'widgets/gamification_widgets.dart';

class AdminGamificationScreen extends ConsumerStatefulWidget {
  const AdminGamificationScreen({super.key, required this.section});

  final String section;

  @override
  ConsumerState<AdminGamificationScreen> createState() =>
      _AdminGamificationScreenState();
}

class _AdminGamificationScreenState
    extends ConsumerState<AdminGamificationScreen> {
  String _search = '';
  String _status = 'all';
  int _reload = 0;
  String? _rowsKey;
  Future<List<Map<String, dynamic>>>? _rows;

  GamificationSection? get _section => gamificationSections[widget.section];

  @override
  Widget build(BuildContext context) {
    if (widget.section == 'overview') {
      return const GamificationOverviewView();
    }
    if (widget.section == 'analytics') {
      return GamificationAnalyticsView(reload: _reload);
    }
    if (widget.section == 'maintenance') {
      return const GamificationMaintenanceView();
    }

    final section = _section;
    if (section == null) {
      return const Center(child: Text('Unknown gamification section'));
    }

    final isWide = MediaQuery.of(context).size.width > 860;
    // Refetch only when the section or the reload counter changes, not on
    // every keystroke in the search field.
    final loadKey = '${section.key}#$_reload';
    if (_rowsKey != loadKey || _rows == null) {
      _rowsKey = loadKey;
      _rows = _loadRows(section);
    }
    final future = _rows!;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 32 : 16,
                isWide ? 32 : 16,
                isWide ? 32 : 16,
                0,
              ),
              sliver: SliverToBoxAdapter(
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
                  ],
                ),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: SelectableText(
                    'Could not load ${section.title}: ${snapshot.error}',
                  ),
                ),
              )
            else
              ...() {
                final rows = _filterRows(snapshot.data ?? const []);
                if (rows.isEmpty) {
                  final hasFilters =
                      _search.trim().isNotEmpty || _status != 'all';
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AdminEmptyState(
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
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 32 : 16,
                      0,
                      isWide ? 32 : 16,
                      120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final row = rows[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GamificationRowCard(
                            section: section,
                            row: row,
                            onPreview: () => _showPreview(section, row),
                            onEdit: () => _editRow(section, row),
                            onPublish: () =>
                                _updateStatus(section, row, 'published'),
                            onUnpublish: () =>
                                _updateStatus(section, row, 'draft'),
                            onArchive: () =>
                                _updateStatus(section, row, 'archived'),
                          ),
                        );
                      }, childCount: rows.length),
                    ),
                  ),
                ];
              }(),
          ],
        );
      },
    );
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

  Future<List<Map<String, dynamic>>> _loadRows(GamificationSection section) {
    // The Worker returns rows in display order (sortOrder / lineIndex, and
    // newest first for audit logs).
    return ref.read(gamificationCmsApiProvider).listRows(section.collectionId);
  }

  /// Runs a CMS write; on failure shows the Worker's message instead of
  /// failing silently. Returns whether the write succeeded.
  Future<bool> _write(Future<void> Function(GamificationCmsApi api) op) async {
    try {
      await op(ref.read(gamificationCmsApiProvider));
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
      return false;
    }
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

  Future<void> _createDraft(GamificationSection section) async {
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
    };

    final saved = await _write(
      (api) => api.upsertRow(section.collectionId, id, draft, createOnly: true),
    );
    if (!saved) return;
    HapticFeedback.selectionClick();
    setState(() => _reload++);
  }

  Future<void> _updateStatus(
    GamificationSection section,
    Map<String, dynamic> row,
    String status,
  ) async {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) return;
    final payload = section.collectionId == 'bakhed_cultural_notes'
        ? {'isPublished': status == 'published'}
        : {'status': status, 'isActive': status == 'published'};
    if (!await _write(
      (api) => api.upsertRow(section.collectionId, id, payload),
    )) {
      return;
    }
    setState(() => _reload++);
  }

  Future<void> _editRow(
    GamificationSection section,
    Map<String, dynamic> row,
  ) async {
    final controllers = {
      for (final field in section.editableFields)
        field: TextEditingController(text: row[field]?.toString() ?? ''),
    };

    await showAdminBottomSheet<void>(
      context: context,
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
                    final saved = await _write(
                      (api) => api.upsertRow(section.collectionId, id, payload),
                    );
                    if (!saved) return;
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

  void _showPreview(GamificationSection section, Map<String, dynamic> row) {
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
              GamificationPreviewCard(label: 'Light', row: row, dark: false),
              GamificationPreviewCard(label: 'Dark', row: row, dark: true),
              SizedBox(
                width: 360,
                child: GamificationPreviewCard(
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
}
