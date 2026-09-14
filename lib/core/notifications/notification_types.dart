/// Frequency of habit and streak study reminders throughout the day.
enum NotificationFrequency {
  /// Single reminder per day at user's preferred time.
  once,

  /// 2 reminders per day: Morning kickstart (9:00 AM) and Evening study.
  balanced,

  /// 4 reminders per day: Morning (9:00 AM), Midday (2:30 PM), Evening, and Night streak saver (9:45 PM).
  high,
}

extension NotificationFrequencyX on NotificationFrequency {
  String get label {
    switch (this) {
      case NotificationFrequency.high:
        return 'High (4x daily)';
      case NotificationFrequency.balanced:
        return 'Balanced (2x daily)';
      case NotificationFrequency.once:
        return 'Relaxed (1x daily)';
    }
  }

  String get description {
    switch (this) {
      case NotificationFrequency.high:
        return 'Morning, Midday, Evening & Night streak saver';
      case NotificationFrequency.balanced:
        return 'Morning boost & Evening study reminder';
      case NotificationFrequency.once:
        return 'Single daily reminder at your preferred time';
    }
  }

  int get remindersPerDay {
    switch (this) {
      case NotificationFrequency.high:
        return 4;
      case NotificationFrequency.balanced:
        return 2;
      case NotificationFrequency.once:
        return 1;
    }
  }
}

/// Learner-state notification copy (product principle: reminders reflect
/// what the learner needs to remember, never guilt).
///
/// Rules: state real numbers, state the time cost, no fake urgency, no
/// "you haven't opened the app 😢" shaming.
class NotificationCopy {
  const NotificationCopy._();

  /// "5 words are ready for review." + honest time cost.
  static ({String title, String body}) reviewDue({
    required int dueCount,
    required int minutes,
  }) {
    final items = dueCount == 1 ? '1 item is' : '$dueCount items are';
    return (
      title: '$dueCount review${dueCount == 1 ? '' : 's'} ready',
      body:
          '$items ready for review (~$minutes min). Open Today\u2019s Review when you have a moment.',
    );
  }

  /// "Two words you struggled with yesterday are due."
  static ({String title, String body}) reviewStruggle({
    required int struggleCount,
  }) {
    final words = struggleCount == 1
        ? 'A word you found tricky'
        : '$struggleCount words you found tricky';
    return (
      title: 'Tricky ones are back',
      body:
          '$words ${struggleCount == 1 ? 'is' : 'are'} due again — a quick retry locks them in.',
    );
  }

  /// Neutral inactivity nudge (replaces guilt framing).
  static const ({String title, String body}) gentleReturn = (
    title: 'Your Santali is waiting',
    body: 'A short review keeps what you learned fresh. No rush.',
  );
}
