import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_form_widgets.dart';
import '../widgets/admin_data_table.dart';
import 'widgets/admin_affirmation_form.dart';

class AdminAffirmationsScreen extends ConsumerStatefulWidget {
  const AdminAffirmationsScreen({super.key});

  @override
  ConsumerState<AdminAffirmationsScreen> createState() =>
      _AdminAffirmationsScreenState();
}

class _AdminAffirmationsScreenState
    extends ConsumerState<AdminAffirmationsScreen> {
  bool _isSyncing = false;

  Future<void> _triggerSheetSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final result = await ref
          .read(affirmationsProvider.notifier)
          .syncFromGoogleSheet();
      if (!mounted) return;
      final isSynced = result['synced'] == true;
      final reason = result['reason'];
      final message = isSynced
          ? 'Successfully synced latest affirmation from Google Sheet!'
          : (reason == 'already_up_to_date'
                ? 'Affirmations are already up to date with the latest sheet row.'
                : 'Google Sheet checked. No new rows found.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSynced
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
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
          backgroundColor: isSynced
              ? AppColors.primary
              : const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to sync from Google Sheet: $e',
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Widget _buildGoogleSheetSyncBanner(bool isDark, bool isWideScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: isWideScreen
          ? Row(
              children: [
                _buildSheetIconBadge(isDark),
                const SizedBox(width: 16),
                Expanded(child: _buildSheetInfoText(isDark)),
                const SizedBox(width: 16),
                _buildSyncButton(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSheetIconBadge(isDark),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSheetInfoText(isDark)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: _buildSyncButton()),
              ],
            ),
    );
  }

  Widget _buildSheetIconBadge(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF107C41).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(
          color: const Color(0xFF107C41).withValues(alpha: 0.25),
        ),
      ),
      child: const Icon(
        Icons.table_chart_rounded,
        color: Color(0xFF107C41),
        size: 22,
      ),
    );
  }

  Widget _buildSheetInfoText(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Google Sheet Auto-Sync',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AdminTokens.textPrimary(isDark),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Every 3 Hours',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Fetches the latest (last) row automatically from the connected spreadsheet and updates the daily affirmation.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AdminTokens.textSecondary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton() {
    return ElevatedButton.icon(
      onPressed: _isSyncing ? null : _triggerSheetSync,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF107C41),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF107C41).withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        ),
      ),
      icon: _isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.sync_rounded, size: 18),
      label: Text(
        _isSyncing ? 'Syncing...' : 'Sync from Sheet Now',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final affirmationsAsync = ref.watch(affirmationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 32 : 16,
        vertical: isWideScreen ? 32 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          AdminSectionHeader(
            title: 'Daily Affirmations',
            subtitle: 'Manage Santali wisdom and transformation scripts',
            icon: Icons.auto_awesome_rounded,
            eyebrow: 'CONTENT · AFFIRMATIONS',
            actions: [
              ElevatedButton.icon(
                onPressed: () => AdminAffirmationForm.show(context, ref, null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Add Affirmation',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Google Sheet Integration & Sync Card
          _buildGoogleSheetSyncBanner(isDark, isWideScreen),

          // Main content
          Expanded(
            child: affirmationsAsync.when(
              data: (items) => items.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : _buildDataTable(items, isDark),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: SelectableText(
                  'Error loading affirmations: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return AdminEmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'No affirmations yet',
          message:
              'Create your first daily affirmation card to engage and inspire users.',
          actionLabel: 'Create Affirmation',
          onAction: () => AdminAffirmationForm.show(context, ref, null),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .scale(begin: const Offset(0.96, 0.96));
  }

  Widget _buildDataTable(List<AffirmationModel> items, bool isDark) {
    return AdminDataTable<AffirmationModel>(
      items: items,
      searchHint: 'Search Ol Chiki text, phonetic, meaning...',
      searchPredicate: (item, query) {
        return item.olChikiText.toLowerCase().contains(query) ||
            item.santaliPhonetic.toLowerCase().contains(query) ||
            item.englishMeaning.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query);
      },
      columns: [
        AdminColumn<AffirmationModel>(
          label: 'Ol Chiki Text',
          flex: 2,
          cellBuilder: (item) => Text(
            item.olChikiText,
            style: const TextStyle(
              fontFamily: 'OlChiki',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        AdminColumn<AffirmationModel>(
          label: 'English Meaning',
          flex: 3,
          cellBuilder: (item) => Text(
            item.englishMeaning,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        AdminColumn<AffirmationModel>(
          label: 'Category',
          flex: 2,
          cellBuilder: (item) => _buildCategoryBadge(item.category, isDark),
        ),
        AdminColumn<AffirmationModel>(
          label: 'Premium',
          cellBuilder: (item) => item.isPremium
              ? const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 18,
                )
              : Icon(
                  Icons.circle_outlined,
                  color: isDark ? Colors.white24 : Colors.black12,
                  size: 18,
                ),
        ),
        AdminColumn<AffirmationModel>(
          label: 'Order',
          cellBuilder: (item) => Text(
            item.order.toString(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          comparator: (a, b) => a.order.compareTo(b.order),
        ),
        AdminColumn<AffirmationModel>(
          label: 'Published',
          flex: 2,
          cellBuilder: (item) {
            final dt = DateTime.tryParse(item.publishedAt);
            if (dt == null) return const Text('—');
            return Text(
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
            );
          },
        ),
      ],
      trailingBuilder: (item) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            onPressed: () => AdminAffirmationForm.show(context, ref, item),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
            onPressed: () => _showDeleteDialog(context, item),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category, bool isDark) {
    MaterialColor color;
    String label;
    switch (category) {
      case 'identity':
        color = Colors.blue;
        label = 'Identity';
        break;
      case 'habit':
        color = Colors.orange;
        label = 'Habit';
        break;
      case 'wealth':
        color = Colors.green;
        label = 'Wealth';
        break;
      case 'culture':
        color = Colors.purple;
        label = 'Culture';
        break;
      default:
        color = Colors.grey;
        label = category;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color.shade300 : color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    AffirmationModel item,
  ) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Affirmation',
      message:
          'Are you sure you want to delete this affirmation? This action cannot be undone.',
    );
    if (ok == true) {
      ref.read(affirmationsProvider.notifier).delete(item.id);
    }
  }
}
