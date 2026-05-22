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
          flex: 1,
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
          flex: 1,
          cellBuilder: (item) => Text(
            item.order.toString(),
            style: const TextStyle(
              fontFamily: 'Poppins',
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
              style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
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
