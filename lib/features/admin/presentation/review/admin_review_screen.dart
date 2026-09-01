/// Phase 5 — admin review workflow screen.
///
/// Two queues in one screen: Sarvam-generated / human-recorded audio
/// tracks (audio_tracks) and localized translations
/// (localized_contents). Items surface here while `reviewStatus` is
/// `needsReview` and become learner-visible only after approval.
///
/// Wire-up: reviewContent Appwrite Function (admin-team gated) via
/// [adminReviewApiClientProvider]; audio preview uses the shared
/// AudioService.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_section_header.dart';
import 'admin_review_api_client.dart';
import 'admin_review_models.dart';

/// Which queue is currently displayed.
enum AdminReviewTab { audio, translations }

/// Which review-status slice is currently displayed.
enum AdminReviewStatusFilter { needsReview, approved, rejected }

class AdminReviewScreen extends ConsumerStatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  ConsumerState<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends ConsumerState<AdminReviewScreen> {
  AdminReviewTab _tab = AdminReviewTab.audio;
  AdminReviewStatusFilter _statusFilter = AdminReviewStatusFilter.needsReview;

  final Set<String> _selectedAudioIds = {};
  final Set<String> _selectedLocalizedIds = {};

  Set<String> _selectedIdsFor(AdminReviewTab tab) => switch (tab) {
    AdminReviewTab.audio => _selectedAudioIds,
    AdminReviewTab.translations => _selectedLocalizedIds,
  };

  String get _statusParam => switch (_statusFilter) {
    AdminReviewStatusFilter.needsReview => 'needsReview',
    AdminReviewStatusFilter.approved => 'approved',
    AdminReviewStatusFilter.rejected => 'rejected',
  };

  Future<void> _refresh() async {
    // Re-run the active list via the future provider family.
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    ref.invalidate(_reviewQueueProvider);
  }

  Future<void> _applyDecision(ApproveReject decision) async {
    final ids = _selectedIdsFor(_tab).toList();
    if (ids.isEmpty) return;

    final client = ref.read(adminReviewApiClientProvider);
    try {
      final result = switch ((_tab, decision)) {
        (AdminReviewTab.audio, ApproveReject.approve) =>
          await client.approveAudio(ids),
        (AdminReviewTab.audio, ApproveReject.reject) =>
          await client.rejectAudio(ids),
        (AdminReviewTab.translations, ApproveReject.approve) =>
          await client.approveLocalized(ids),
        (AdminReviewTab.translations, ApproveReject.reject) =>
          await client.rejectLocalized(ids),
      };

      _selectedIdsFor(_tab).clear();
      await _refresh();
      if (!mounted) return;
      _showFeedback(
        ok: true,
        message:
            '${result.updated} of ${result.requested} item(s) '
            '${decision == ApproveReject.approve ? 'approved' : 'rejected'}.'
            '${result.failed > 0 ? ' ${result.failed} could not be updated (broken or missing items are skipped).' : ''}',
      );
    } on AdminReviewException catch (e) {
      if (!mounted) return;
      _showFeedback(ok: false, message: e.message);
    } catch (e) {
      if (!mounted) return;
      _showFeedback(ok: false, message: 'Review action failed: $e');
    }
  }

  void _showFeedback({required bool ok, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: ok ? AppColors.primary : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 16,
        vertical: isWide ? 32 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Content Review',
            subtitle:
                'Approve Sarvam audio and localized translations before they '
                'become visible to learners',
            icon: Icons.fact_check_rounded,
            eyebrow: 'CONTENT · REVIEW',
          ),
          const SizedBox(height: 16),
          _buildTabs(isDark),
          const SizedBox(height: 16),
          _buildToolbar(isDark),
          const SizedBox(height: 16),
          Expanded(child: _buildQueueBody()),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(
        children: [
          _buildTabButton(
            isDark,
            label: 'Audio Tracks',
            icon: Icons.graphic_eq_rounded,
            tab: AdminReviewTab.audio,
          ),
          _buildTabButton(
            isDark,
            label: 'Translations',
            icon: Icons.translate_rounded,
            tab: AdminReviewTab.translations,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    bool isDark, {
    required String label,
    required IconData icon,
    required AdminReviewTab tab,
  }) {
    final selected = _tab == tab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        onTap: () => setState(() {
          _tab = tab;
          _statusFilter = AdminReviewStatusFilter.needsReview;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? Colors.white
                    : AdminTokens.textSecondary(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : AdminTokens.textPrimary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(bool isDark) {
    final selectedIds = _selectedIdsFor(_tab);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildStatusFilterChips(isDark),
        if (selectedIds.isNotEmpty &&
            _statusFilter == AdminReviewStatusFilter.needsReview) ...[
          ActionChip(
            avatar: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              'Approve selected (${selectedIds.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 12.5,
              ),
            ),
            backgroundColor: AppColors.primary,
            onPressed: () => _applyDecision(ApproveReject.approve),
          ),
          ActionChip(
            avatar: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              'Reject selected (${selectedIds.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 12.5,
              ),
            ),
            backgroundColor: AppColors.error,
            onPressed: () => _applyDecision(ApproveReject.reject),
          ),
          ActionChip(
            avatar: Icon(
              Icons.clear_all_rounded,
              size: 16,
              color: AdminTokens.textSecondary(isDark),
            ),
            label: Text(
              'Clear',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                color: AdminTokens.textPrimary(isDark),
              ),
            ),
            backgroundColor: AdminTokens.sunken(isDark),
            onPressed: () => setState(_selectedIdsFor(_tab).clear),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusFilterChips(bool isDark) {
    Widget chipFor(AdminReviewStatusFilter filter, String label) {
      final selected = _statusFilter == filter;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AdminTokens.textSecondary(isDark),
          ),
        ),
        selected: selected,
        onSelected: (_) => setState(() {
          _statusFilter = filter;
          _selectedIdsFor(_tab).clear();
        }),
        selectedColor: AppColors.primary,
        backgroundColor: AdminTokens.sunken(isDark),
        side: BorderSide(color: AdminTokens.border(isDark)),
        showCheckmark: false,
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        chipFor(AdminReviewStatusFilter.needsReview, 'Needs review'),
        chipFor(AdminReviewStatusFilter.approved, 'Approved'),
        chipFor(AdminReviewStatusFilter.rejected, 'Rejected'),
      ],
    );
  }

  Widget _buildQueueBody() {
    final queueAsync = ref.watch(_reviewQueueProvider((_tab, _statusParam)));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return queueAsync.when(
      data: (queue) => queue.rows.isEmpty
          ? AdminEmptyState(
              icon: _tab == AdminReviewTab.audio
                  ? Icons.graphic_eq_outlined
                  : Icons.translate_rounded,
              title: 'Queue is empty',
              message:
                  'No ${_tab == AdminReviewTab.audio ? 'audio tracks' : 'translations'} '
                  'with status "$_statusParam". Generate audio or sync '
                  'translations first, then review them here.',
            )
          : _buildQueueList(queue, isDark),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(isDark, error),
    );
  }

  Widget _buildError(bool isDark, Object error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            'Error loading review queue: $error',
            style: const TextStyle(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueList(AdminReviewQueue queue, bool isDark) {
    if (_tab == AdminReviewTab.audio) {
      return ListView.separated(
        itemCount: queue.audio.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildAudioCard(queue.audio[index], isDark),
      );
    }
    return ListView.separated(
      itemCount: queue.localized.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildLocalizedCard(queue.localized[index], isDark),
    );
  }

  Widget _buildAudioCard(AdminAudioTrackRow track, bool isDark) {
    final selected = _selectedAudioIds.contains(track.id);
    final canDecide = _statusFilter == AdminReviewStatusFilter.needsReview;
    final approveEnabled = canDecide && track.isApprovable;

    return _ReviewCard(
      selected: selected,
      isDark: isDark,
      onToggleSelect: canDecide
          ? () => setState(() {
              if (selected) {
                _selectedAudioIds.remove(track.id);
              } else {
                _selectedAudioIds.add(track.id);
              }
            })
          : null,
      leading: Checkbox(
        value: selected,
        onChanged: canDecide
            ? (_) => setState(() {
                if (selected) {
                  _selectedAudioIds.remove(track.id);
                } else {
                  _selectedAudioIds.add(track.id);
                }
              })
            : null,
      ),
      title: track.title,
      subtitle: _AudioTrackMeta(track: track, isDark: isDark),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (track.hasAudio) _PreviewButton(audioUrl: track.audioUrl!),
          const SizedBox(width: 8),
          _DecisionButtons(
            isDark: isDark,
            canDecide: canDecide,
            approveEnabled: approveEnabled,
            approveTooltip: track.isApprovable
                ? 'Approve'
                : 'Track is not approvable yet (missing audio URL or generation not completed)',
            onApprove: () => _decideSingle([track.id], ApproveReject.approve),
            onReject: () => _decideSingle([track.id], ApproveReject.reject),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalizedCard(AdminLocalizedContentRow row, bool isDark) {
    final selected = _selectedLocalizedIds.contains(row.id);
    final canDecide = _statusFilter == AdminReviewStatusFilter.needsReview;

    return _ReviewCard(
      selected: selected,
      isDark: isDark,
      onToggleSelect: canDecide
          ? () => setState(() {
              if (selected) {
                _selectedLocalizedIds.remove(row.id);
              } else {
                _selectedLocalizedIds.add(row.id);
              }
            })
          : null,
      leading: Checkbox(
        value: selected,
        onChanged: canDecide
            ? (_) => setState(() {
                if (selected) {
                  _selectedLocalizedIds.remove(row.id);
                } else {
                  _selectedLocalizedIds.add(row.id);
                }
              })
            : null,
      ),
      title: '${row.title} · ${row.languageCode}',
      subtitle: _LocalizedMeta(row: row, isDark: isDark),
      trailing: _DecisionButtons(
        isDark: isDark,
        canDecide: canDecide,
        approveEnabled: canDecide,
        onApprove: () => _decideSingle([row.id], ApproveReject.approve),
        onReject: () => _decideSingle([row.id], ApproveReject.reject),
      ),
    );
  }

  Future<void> _decideSingle(List<String> ids, ApproveReject decision) async {
    _selectedIdsFor(_tab)
      ..clear()
      ..addAll(ids);
    await _applyDecision(decision);
  }
}

enum ApproveReject { approve, reject }

/// A normalized view of one queue page regardless of tab.
class AdminReviewQueue {
  final List<AdminAudioTrackRow> audio;
  final List<AdminLocalizedContentRow> localized;
  final int total;

  const AdminReviewQueue({
    this.audio = const [],
    this.localized = const [],
    this.total = 0,
  });

  List<dynamic> get rows =>
      audio.isNotEmpty || localized.isEmpty ? audio : localized;
}

final _reviewQueueProvider = FutureProvider.autoDispose
    .family<AdminReviewQueue, (AdminReviewTab, String)>((ref, key) async {
      final (tab, status) = key;
      final client = ref.watch(adminReviewApiClientProvider);
      if (tab == AdminReviewTab.audio) {
        final page = await client.listAudioTracks(reviewStatus: status);
        return AdminReviewQueue(audio: page.tracks, total: page.total);
      }
      final page = await client.listLocalizedContents(reviewStatus: status);
      return AdminReviewQueue(localized: page.contents, total: page.total);
    });

class _ReviewCard extends StatelessWidget {
  final bool selected;
  final bool isDark;
  final VoidCallback? onToggleSelect;
  final Widget leading;
  final String title;
  final Widget subtitle;
  final Widget trailing;

  const _ReviewCard({
    required this.selected,
    required this.isDark,
    this.onToggleSelect,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleSelect,
      borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTokens.raised(isDark),
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AdminTokens.border(isDark),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: AdminTokens.raisedShadow(isDark),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AdminTokens.textPrimary(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  subtitle,
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _AudioTrackMeta extends StatelessWidget {
  final AdminAudioTrackRow track;
  final bool isDark;

  const _AudioTrackMeta({required this.track, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _MetaBadge(
          label: track.languageCode,
          icon: Icons.language_rounded,
          color: Colors.blue,
          isDark: isDark,
        ),
        _MetaBadge(
          label: track.trackType,
          icon: Icons.waves_rounded,
          color: Colors.deepPurple,
          isDark: isDark,
        ),
        if (track.isHumanRecorded)
          _MetaBadge(
            label: 'Human',
            icon: Icons.mic_rounded,
            color: Colors.green,
            isDark: isDark,
          )
        else
          _MetaBadge(
            label: 'Gen: ${track.generationStatus ?? 'unknown'}',
            icon: Icons.smart_toy_rounded,
            color: _generationColor(track.generationStatus),
            isDark: isDark,
          ),
        if (track.errorMessage != null)
          _MetaBadge(
            label: track.errorMessage!,
            icon: Icons.error_outline_rounded,
            color: Colors.red,
            isDark: isDark,
          ),
      ],
    );
  }

  Color _generationColor(String? status) {
    if (status == 'completed') return Colors.green;
    if (status == 'failed') return Colors.red;
    if (status == 'queued' || status == 'processing') return Colors.orange;
    return Colors.grey;
  }
}

class _LocalizedMeta extends StatelessWidget {
  final AdminLocalizedContentRow row;
  final bool isDark;

  const _LocalizedMeta({required this.row, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (row.meaning != null) 'Meaning: ${row.meaning!}',
      if (row.explanation != null) 'Explanation: ${row.explanation!}',
    ];
    return Text(
      parts.isEmpty ? '—' : parts.join('  ·  '),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: AdminTokens.textSecondary(isDark),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetaBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark
                ? color.withValues(alpha: 0.85)
                : color.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? color.withValues(alpha: 0.85)
                  : color.withValues(alpha: 0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends ConsumerStatefulWidget {
  final String audioUrl;

  const _PreviewButton({required this.audioUrl});

  @override
  ConsumerState<_PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends ConsumerState<_PreviewButton> {
  bool _playing = false;

  Future<void> _toggle() async {
    final audio = ref.read(audioServiceProvider);
    if (_playing) {
      await audio.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final ok = await audio.tryPlayUrl(widget.audioUrl);
    if (!mounted) return;
    setState(() => _playing = ok);
    if (ok) {
      // Update the button when playback finishes naturally.
      audio.isPlayingStream.listen((playing) {
        if (!playing && mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  void dispose() {
    if (_playing) {
      ref.read(audioServiceProvider).stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _playing ? 'Pause preview' : 'Play preview',
      icon: Icon(
        _playing ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
        size: 22,
        color: AppColors.primary,
      ),
      onPressed: _toggle,
    );
  }
}

class _DecisionButtons extends StatelessWidget {
  final bool isDark;
  final bool canDecide;
  final bool approveEnabled;
  final String? approveTooltip;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _DecisionButtons({
    required this.isDark,
    required this.canDecide,
    required this.approveEnabled,
    this.approveTooltip,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (!canDecide) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: approveTooltip ?? 'Approve',
          child: IconButton(
            icon: Icon(
              Icons.check_circle_outline_rounded,
              size: 21,
              color: approveEnabled
                  ? Colors.green
                  : (isDark ? Colors.white24 : Colors.black12),
            ),
            onPressed: approveEnabled ? onApprove : null,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.cancel_outlined,
            size: 21,
            color: AppColors.error,
          ),
          onPressed: onReject,
          tooltip: 'Reject',
        ),
      ],
    );
  }
}
