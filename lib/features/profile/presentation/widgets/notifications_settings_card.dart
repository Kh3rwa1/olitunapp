import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationsEnabledProvider);
    final hour = ref.watch(reminderHourProvider);
    final minute = ref.watch(reminderMinuteProvider);

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
              'Get a gentle daily reminder to practice and protect your streak',
          value: enabled,
          isDark: isDark,
          onChanged: (value) =>
              ref.read(notificationsEnabledProvider.notifier).toggle(value),
        ),
        if (enabled) ...[
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
        ],
      ],
    );
  }
}
