import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_data_table.dart';
import '../widgets/admin_glass_card.dart';
import '../analytics/admin_analytics_csv_exporter.dart';
import '../widgets/common/admin_modal_sheet.dart';
part 'widgets/admin_binti_waitlist_details_sheet.dart';
part 'widgets/admin_binti_waitlist_kpi_row.dart';

class AdminBintiWaitlistScreen extends ConsumerStatefulWidget {
  const AdminBintiWaitlistScreen({super.key});

  @override
  ConsumerState<AdminBintiWaitlistScreen> createState() =>
      _AdminBintiWaitlistScreenState();
}

class _AdminBintiWaitlistScreenState
    extends ConsumerState<AdminBintiWaitlistScreen> {
  String _selectedFilter =
      'all'; // 'all', 'new', 'contacted', 'converted', 'closed'

  @override
  Widget build(BuildContext context) {
    final waitlistAsync = ref.watch(adminWaitlistProvider);
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
            title: 'Binti Guru Waitlist',
            subtitle: 'Manage client waitlist bookings and match with reciters',
            icon: Icons.event_note_rounded,
            eyebrow: 'MARKETPLACE · WAITLIST',
            actions: [
              waitlistAsync.maybeWhen(
                data: (items) => OutlinedButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => _exportToCsv(context, items),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Export CSV',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main content
          Expanded(
            child: waitlistAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'Waitlist is empty',
                    message:
                        'Once users book Binti Guru services from the app, their requests will appear here.',
                    actionLabel: 'Refresh',
                    onAction: () =>
                        ref.read(adminWaitlistProvider.notifier).loadWaitlist(),
                  );
                }

                // Compute metrics
                final totalBookings = items.length;
                final newCount = items.where((p) => p.status == 'new').length;
                final contactedCount = items
                    .where((p) => p.status == 'contacted')
                    .length;
                final convertedCount = items
                    .where((p) => p.status == 'converted')
                    .length;

                // Filter list
                final filtered = items.where((p) {
                  if (_selectedFilter == 'new') {
                    return p.status == 'new';
                  }
                  if (_selectedFilter == 'contacted') {
                    return p.status == 'contacted';
                  }
                  if (_selectedFilter == 'converted') {
                    return p.status == 'converted';
                  }
                  if (_selectedFilter == 'closed') {
                    return p.status == 'closed';
                  }
                  return true;
                }).toList();

                return Column(
                  children: [
                    // KPI Row
                    _BintiWaitlistKpiRow(
                      isDark: isDark,
                      isWide: isWideScreen,
                      total: totalBookings,
                      newCount: newCount,
                      contacted: contactedCount,
                      converted: convertedCount,
                    ),
                    const SizedBox(height: 24),

                    // Filter chips row
                    _buildFilterChips(isDark),
                    const SizedBox(height: 16),

                    // Data Table
                    Expanded(child: _buildDataTable(filtered, isDark)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: SelectableText(
                  'Error loading waitlist: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('All Bookings', 'all', isDark),
          const SizedBox(width: 8),
          _chip('New', 'new', isDark),
          const SizedBox(width: 8),
          _chip('Contacted', 'contacted', isDark),
          const SizedBox(width: 8),
          _chip('Converted', 'converted', isDark),
          const SizedBox(width: 8),
          _chip('Closed', 'closed', isDark),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = value);
      },
    );
  }

  Widget _buildDataTable(List<WaitlistModel> items, bool isDark) {
    return AdminDataTable<WaitlistModel>(
      items: items,
      searchHint: 'Search waitlist by name, phone, city, state...',
      searchPredicate: (item, query) {
        return item.fullName.toLowerCase().contains(query) ||
            item.phoneNumber.contains(query) ||
            item.city.toLowerCase().contains(query) ||
            item.state.toLowerCase().contains(query) ||
            item.ceremonyType.toLowerCase().contains(query);
      },
      columns: [
        AdminColumn<WaitlistModel>(
          label: 'Client Name',
          flex: 2,
          cellBuilder: (item) => Text(
            item.fullName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AdminColumn<WaitlistModel>(
          label: 'Phone Number',
          flex: 2,
          cellBuilder: (item) => Text(
            item.phoneNumber,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        ),
        AdminColumn<WaitlistModel>(
          label: 'Ceremony',
          flex: 2,
          cellBuilder: (item) {
            final label = item.ceremonyType.toUpperCase();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
        AdminColumn<WaitlistModel>(
          label: 'Location',
          flex: 2,
          cellBuilder: (item) => Text(
            '${item.city}, ${item.state}',
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AdminColumn<WaitlistModel>(
          label: 'Event Date',
          flex: 2,
          cellBuilder: (item) {
            if (item.eventDate == null || item.eventDate!.isEmpty) {
              return const Text(
                'Not set',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              );
            }
            final dt = DateTime.tryParse(item.eventDate!);
            if (dt == null) {
              return Text(
                item.eventDate!,
                style: const TextStyle(fontSize: 12),
              );
            }
            return Text(
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
            );
          },
        ),
        AdminColumn<WaitlistModel>(
          label: 'Status',
          flex: 2,
          cellBuilder: (item) {
            final status = item.status;
            Color c = Colors.grey;
            if (status == 'new') c = Colors.orange;
            if (status == 'contacted') c = Colors.purple;
            if (status == 'converted') c = Colors.green;
            if (status == 'closed') c = Colors.red;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: c,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ],
      onRowTap: (item) => _showDetailsSheet(context, item),
    );
  }

  void _showDetailsSheet(BuildContext context, WaitlistModel entry) {
    showAdminBottomSheet(
      context: context,
      builder: (ctx) {
        return _WaitlistDetailsSheet(entry: entry, parentRef: ref);
      },
    );
  }

  Future<void> _exportToCsv(
    BuildContext context,
    List<WaitlistModel> items,
  ) async {
    const header =
        'Waitlist ID,User ID,Client Name,Phone Number,Ceremony Type,Event Date,City,State,Notes,Submitted At,Contacted At,Status\n';

    String escape(String? val) {
      if (val == null) return '';
      if (val.contains(',') || val.contains('"') || val.contains('\n')) {
        return '"${val.replaceAll('"', '""')}"';
      }
      return val;
    }

    final rows = items
        .map((p) {
          return [
            escape(p.id),
            escape(p.userId),
            escape(p.fullName),
            escape(p.phoneNumber),
            escape(p.ceremonyType),
            escape(p.eventDate),
            escape(p.city),
            escape(p.state),
            escape(p.notes),
            escape(p.submittedAt),
            escape(p.contactedAt),
            escape(p.status),
          ].join(',');
        })
        .join('\n');

    final csv = header + rows;
    final filename =
        'olitun-binti-waitlist-${DateTime.now().millisecondsSinceEpoch}.csv';

    try {
      await exportAnalyticsCsv(filename: filename, csv: csv);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waitlist data exported as $analyticsCsvExportLabel'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
