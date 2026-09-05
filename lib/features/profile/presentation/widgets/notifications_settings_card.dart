import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/notification_providers.dart';
import 'settings_widgets.dart';

/// Card allowing learners to configure daily streak and habit reminder notifications.
class NotificationsSettingsCard extends ConsumerWidget {
  const NotificationsSettingsCard({
    super.key,
    required this.isDark,
    this.index = 3,
  });

  final bool isDark;
  final int index;

  String _formatTime(BuildContext context, int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  void _showFrequencyPicker(
    BuildContext context,
    WidgetRef ref,
    NotificationFrequency current,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.quizDarkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder Frequency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how often you would like to be reminded to practice Ol Chiki.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                ...NotificationFrequency.values.map((freq) {
                  final isSelected = freq == current;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    title: Text(
                      freq.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      freq.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    onTap: () {
                      ref
                          .read(notificationFrequencyProvider.notifier)
                          .setFrequency(freq);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scheduleRow(String time, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationsEnabledProvider);
    final hour = ref.watch(reminderHourProvider);
    final minute = ref.watch(reminderMinuteProvider);
    final frequency = ref.watch(notificationFrequencyProvider);

    return SettingsCard(
      title: 'Notifications & Habits',
      icon: Icons.notifications_active_rounded,
      color: AppColors.accentOchre,
      index: index,
      children: [
        ToggleTile(
          icon: Icons.alarm_rounded,
          title: 'Daily Study Reminder',
          subtitle:
              'Get gentle daily reminders to practice and protect your streak',
          value: enabled,
          isDark: isDark,
          onChanged: (value) =>
              ref.read(notificationsEnabledProvider.notifier).toggle(value),
        ),
        if (enabled) ...[
          const SizedBox(height: 10),
          SettingTile(
            icon: Icons.repeat_rounded,
            title: 'Reminder Frequency',
            subtitle: frequency.label,
            isDark: isDark,
            onTap: () => _showFrequencyPicker(context, ref, frequency),
          ),
          const SizedBox(height: 10),
          SettingTile(
            icon: Icons.schedule_rounded,
            title: 'Reminder Time',
            subtitle: _formatTime(context, hour, minute),
            isDark: isDark,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: hour, minute: minute),
              );
              if (picked != null) {
                await ref
                    .read(reminderHourProvider.notifier)
                    .setHour(picked.hour);
                await ref
                    .read(reminderMinuteProvider.notifier)
                    .setMinute(picked.minute);
              }
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Daily Schedule Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (frequency == NotificationFrequency.high) ...[
                  _scheduleRow('☀️ 9:00 AM', 'Morning Kickstart'),
                  _scheduleRow('🎯 2:30 PM', 'Midday Study Boost'),
                  _scheduleRow(
                    '🌆 ${_formatTime(context, hour, minute)}',
                    'Main Practice (Custom)',
                  ),
                  _scheduleRow('🌙 9:45 PM', 'Night Streak Saver'),
                ] else if (frequency == NotificationFrequency.balanced) ...[
                  _scheduleRow('☀️ 9:00 AM', 'Morning Kickstart'),
                  _scheduleRow(
                    '🌆 ${_formatTime(context, hour, minute)}',
                    'Main Practice (Custom)',
                  ),
                ] else ...[
                  _scheduleRow(
                    '🌆 ${_formatTime(context, hour, minute)}',
                    'Main Practice (Custom)',
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
