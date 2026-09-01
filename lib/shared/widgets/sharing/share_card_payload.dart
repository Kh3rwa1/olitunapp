import 'package:flutter/material.dart';

enum ShareCardKind {
  quizResult,
  streakMilestone,
  badgeAchievement,
  dailyAffirmation,
}

class ShareCardPayload {
  final ShareCardKind kind;
  final String title;
  final String? subtitle;
  final String? olChikiText;
  final String? metricLabel;
  final String? metricValue;
  final String? secondaryMetricLabel;
  final String? secondaryMetricValue;
  final IconData? icon;
  final String? emoji;
  final Color? accentColor;
  final String shareMessage;

  const ShareCardPayload({
    required this.kind,
    required this.title,
    this.subtitle,
    this.olChikiText,
    this.metricLabel,
    this.metricValue,
    this.secondaryMetricLabel,
    this.secondaryMetricValue,
    this.icon,
    this.emoji,
    this.accentColor,
    required this.shareMessage,
  });

  /// Factory for Quiz Completion results
  factory ShareCardPayload.quizResult({
    required int score,
    required int total,
    required int percentage,
    required int stars,
  }) {
    return ShareCardPayload(
      kind: ShareCardKind.quizResult,
      title: 'Santali Quiz Completed! 🎉',
      subtitle: 'Practicing Ol Chiki on Olitun',
      olChikiText: 'ᱚᱞ ᱪᱤᱠᱤ ᱪᱮᱫᱚᱜ ᱢᱮ',
      metricLabel: 'Score',
      metricValue: '$score / $total ($percentage%)',
      secondaryMetricLabel: 'Stars Earned',
      secondaryMetricValue: '+$stars ⭐',
      icon: Icons.emoji_events_rounded,
      shareMessage:
          'I just scored $score/$total ($percentage%) on my Santali quiz on Olitun! 🚀 Download Olitun to learn Ol Chiki: https://olitun.app',
    );
  }

  /// Factory for Streak milestones
  factory ShareCardPayload.streakMilestone({required int streakDays}) {
    return ShareCardPayload(
      kind: ShareCardKind.streakMilestone,
      title: '$streakDays Day Streak! 🔥',
      subtitle: 'Daily Santali Learning Habit',
      olChikiText: 'ᱫᱤᱱᱟᱹᱢ ᱦᱤᱞᱚᱜ ᱚᱞ ᱪᱤᱠᱤ',
      metricLabel: 'Active Streak',
      metricValue: '$streakDays Days',
      secondaryMetricLabel: 'Milestone',
      secondaryMetricValue: 'Top Learner 🏆',
      icon: Icons.local_fire_department_rounded,
      shareMessage:
          'I am on a $streakDays-day learning streak on Olitun! 🔥 Join me in learning Santali: https://olitun.app',
    );
  }

  /// Factory for Unlocked Badges
  factory ShareCardPayload.badgeAchievement({
    required String badgeName,
    required String description,
    required String iconEmoji,
    required String category,
  }) {
    return ShareCardPayload(
      kind: ShareCardKind.badgeAchievement,
      title: '$badgeName Unlocked! 🏆',
      subtitle: description,
      olChikiText: 'ᱡᱤᱛᱠᱟᱹᱨ ᱢᱟᱱᱟᱣ',
      metricLabel: 'Category',
      metricValue: category,
      secondaryMetricLabel: 'Achievement',
      secondaryMetricValue: 'Verified ✅',
      emoji: iconEmoji,
      shareMessage:
          'I just unlocked the "$badgeName" badge on Olitun! 🏅 Learn Ol Chiki with me: https://olitun.app',
    );
  }
}
