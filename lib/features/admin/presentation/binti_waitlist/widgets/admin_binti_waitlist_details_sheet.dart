part of '../admin_binti_waitlist_screen.dart';

// Bottom sheet showing one waitlist entry with contact actions and status updates.
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
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close details',
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
