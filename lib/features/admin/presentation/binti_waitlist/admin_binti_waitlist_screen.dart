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
                    _buildKpiRow(
                      isDark,
                      isWideScreen,
                      totalBookings,
                      newCount,
                      contactedCount,
                      convertedCount,
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

  Widget _buildKpiRow(
    bool isDark,
    bool isWide,
    int total,
    int newCount,
    int contacted,
    int converted,
  ) {
    final cardStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      fontFamily: 'Poppins',
      color: isDark ? Colors.white : Colors.black87,
    );

    final cards = [
      _KpiItem(
        title: 'Total Bookings',
        value: total.toString(),
        icon: Icons.book_online_rounded,
        accentColor: Colors.blue,
      ),
      _KpiItem(
        title: 'New Requests',
        value: newCount.toString(),
        icon: Icons.fiber_new_rounded,
        accentColor: Colors.orange,
      ),
      _KpiItem(
        title: 'Contacted',
        value: contacted.toString(),
        icon: Icons.chat_bubble_outline_rounded,
        accentColor: Colors.purple,
      ),
      _KpiItem(
        title: 'Converted',
        value: converted.toString(),
        icon: Icons.check_circle_rounded,
        accentColor: Colors.green,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildKpiCard(isDark, c, cardStyle),
                ),
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.map((c) => _buildKpiCard(isDark, c, cardStyle)).toList(),
    );
  }

  Widget _buildKpiCard(bool isDark, _KpiItem card, TextStyle cardStyle) {
    return AdminGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black54,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: card.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(card.icon, size: 16, color: card.accentColor),
              ),
            ],
          ),
          Text(card.value, style: cardStyle),
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
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
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
              style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF151922) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

class _WaitlistDetailsSheet extends ConsumerStatefulWidget {
  final WaitlistModel entry;
  final WidgetRef parentRef;

  const _WaitlistDetailsSheet({required this.entry, required this.parentRef});

  @override
  ConsumerState<_WaitlistDetailsSheet> createState() =>
      _WaitlistDetailsSheetState();
}

class _WaitlistDetailsSheetState extends ConsumerState<_WaitlistDetailsSheet> {
  late String _status;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.entry.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    try {
      await widget.parentRef
          .read(adminWaitlistProvider.notifier)
          .updateStatus(widget.entry.id, newStatus);
      setState(() => _status = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated to ${newStatus.toUpperCase()} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _launchCall() async {
    final uri = Uri.parse('tel:+91${widget.entry.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not initiate call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final message =
        'Hi ${widget.entry.fullName}, we received your request on Olitun for a Binti Guru for the upcoming ${widget.entry.ceremonyType} ceremony in ${widget.entry.city}. I wanted to follow up and match you with a reciter. Is now a good time to chat?';
    final url =
        'https://wa.me/91${widget.entry.phoneNumber}?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final submittedDate = DateTime.tryParse(widget.entry.submittedAt);
    final eventDate = widget.entry.eventDate != null
        ? DateTime.tryParse(widget.entry.eventDate!)
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waitlist Request Detail'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.entry.fullName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 32),

          Row(
            children: [
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.phone_rounded,
                  label: 'Phone Number',
                  value: widget.entry.phoneNumber,
                  isDark: isDark,
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    onPressed: _launchCall,
                    icon: const Icon(Icons.phone, size: 18),
                    style: IconButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _launchWhatsApp,
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    style: IconButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.celebration_rounded,
                  label: 'Ceremony Type',
                  value: widget.entry.ceremonyType.toUpperCase(),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Event Date',
                  value: eventDate != null
                      ? '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}'
                      : 'Not Scheduled',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.location_on_rounded,
                  label: 'City',
                  value: widget.entry.city,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildDetailTile(
                  icon: Icons.map_rounded,
                  label: 'State',
                  value: widget.entry.state,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDetailTile(
            icon: Icons.access_time_rounded,
            label: 'Submitted At',
            value: submittedDate != null
                ? '${submittedDate.year}-${submittedDate.month.toString().padLeft(2, '0')}-${submittedDate.day.toString().padLeft(2, '0')} ${submittedDate.hour.toString().padLeft(2, '0')}:${submittedDate.minute.toString().padLeft(2, '0')}'
                : 'Unknown',
            isDark: isDark,
          ),
          if (widget.entry.contactedAt != null) ...[
            const SizedBox(height: 16),
            _buildDetailTile(
              icon: Icons.contact_phone_rounded,
              label: 'Contacted At',
              value: widget.entry.contactedAt!,
              isDark: isDark,
            ),
          ],

          if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'NOTES / COMMENTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTokens.sunken(isDark),
                border: Border.all(color: AdminTokens.border(isDark)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.entry.notes!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],

          const Divider(height: 40),

          // Status & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT STATUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _status == 'new'
                              ? Colors.orange
                              : (_status == 'contacted'
                                    ? Colors.purple
                                    : (_status == 'converted'
                                          ? Colors.green
                                          : Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _status.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_updating)
                const CircularProgressIndicator()
              else
                Row(
                  children: [
                    if (_status == 'new')
                      TextButton.icon(
                        onPressed: () => _updateStatus('contacted'),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Contacted'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    if (_status == 'contacted')
                      TextButton.icon(
                        onPressed: () => _updateStatus('converted'),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('Convert'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    if (_status != 'closed')
                      TextButton.icon(
                        onPressed: () => _updateStatus('closed'),
                        icon: const Icon(Icons.cancel_rounded, size: 16),
                        label: const Text('Close'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.87)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });
}
