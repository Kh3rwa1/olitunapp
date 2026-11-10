import 'reminder_context.dart';

/// One notification's text.
typedef ReminderText = ({String title, String body});

/// Reminder copy derived from real learner state. Rules: never mention a
/// streak the learner does not have, state real numbers, no guilt.
class ReminderCopy {
  const ReminderCopy._();

  /// Payload for taps: review when reviews are due, otherwise home.
  static String payloadFor(ReminderContext ctx) =>
      ctx.dueReviews > 0 ? 'review' : 'daily';

  static String _days(int n) => n == 1 ? '1 day' : '$n days';

  static String _reviews(int n) => n == 1 ? '1 review' : '$n reviews';

  /// Main (user-timed) slot.
  static ReminderText evening(ReminderContext ctx) {
    if (ctx.streak > 0) {
      return (
        title: 'Keep your ${ctx.streak}-day streak going 🔥',
        body: ctx.dueReviews > 0
            ? '${_reviews(ctx.dueReviews)} ready. Two minutes keeps the streak alive.'
            : 'Two minutes of Ol Chiki today keeps your streak alive.',
      );
    }
    if (ctx.dueReviews > 0) {
      return (
        title: '${_reviews(ctx.dueReviews)} ready',
        body: 'A quick review locks in what you learned. No rush.',
      );
    }
    return (
      title: 'Today’s Santali word is waiting',
      body: 'Learn one word in Ol Chiki today. It takes two minutes.',
    );
  }

  /// 09:00 slot (balanced and high).
  static ReminderText morning(ReminderContext ctx) {
    if (ctx.dueReviews > 0) {
      return (
        title: 'Good morning ☀️ ${_reviews(ctx.dueReviews)} ready',
        body: 'Start the day with a quick Ol Chiki review.',
      );
    }
    return (
      title: 'Start your morning with Ol Chiki ☀️',
      body: 'A two-minute lesson sets the tone for the day.',
    );
  }

  /// 14:30 slot (high only).
  static ReminderText afternoon(ReminderContext ctx) {
    return (
      title: 'Midday Ol Chiki boost 🎯',
      body: ctx.streak > 0
          ? 'A short break and one new word keeps day ${ctx.streak + 1} on track.'
          : 'Take a short break and learn one new Santali word.',
    );
  }

  /// Late slot (high only). Only meaningful with a real streak; callers skip
  /// the slot when [ReminderContext.streak] is 0.
  static ReminderText night(ReminderContext ctx) {
    return (
      title: 'Your ${_days(ctx.streak)} streak ends at midnight ⏳',
      body: 'One quick lesson before bed saves it.',
    );
  }

  /// Lapse series: one-shots after 3, 7 and 14 days without practice.
  static ReminderText lapse(int day) {
    switch (day) {
      case 3:
        return (
          title: 'Your Santali is waiting 🪶',
          body: 'A short review keeps what you learned fresh. No rush.',
        );
      case 7:
        return (
          title: 'One week away from Ol Chiki',
          body: 'Pick up where you left off. Two minutes is enough.',
        );
      default:
        return (
          title: 'Johar! Ready to come back?',
          body: 'Your lessons and progress are saved. Start again any day.',
        );
    }
  }
}
