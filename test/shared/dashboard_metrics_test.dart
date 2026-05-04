import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/providers/dashboard_metrics_provider.dart';
import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_colors.dart';

void main() {
  group('ActivityItem', () {
    test('constructs with all required fields', () {
      final item = ActivityItem(
        title: 'New lesson added',
        subtitle: 'Vowels Introduction',
        icon: Icons.school_rounded,
        color: AppColors.duoBlue,
        timestamp: DateTime(2026, 5, 4, 10, 30),
        isUpdate: false,
      );

      expect(item.title, 'New lesson added');
      expect(item.subtitle, 'Vowels Introduction');
      expect(item.isUpdate, isFalse);
    });

    test('isUpdate flag differentiates creates from updates', () {
      final create = ActivityItem(
        title: 'New word added',
        subtitle: 'hello',
        icon: Icons.menu_book_rounded,
        color: AppColors.duoYellow,
        timestamp: DateTime.now(),
        isUpdate: false,
      );

      final update = ActivityItem(
        title: 'Word updated',
        subtitle: 'hello',
        icon: Icons.menu_book_rounded,
        color: AppColors.duoYellow,
        timestamp: DateTime.now(),
        isUpdate: true,
      );

      expect(create.isUpdate, isFalse);
      expect(update.isUpdate, isTrue);
    });
  });

  group('DashboardMetrics', () {
    test('hasAnyActivity returns false when all empty', () {
      const metrics = DashboardMetrics(
        recentActivity: [],
        lessonsSeries: [0, 0, 0, 0, 0, 0, 0],
        vocabularySeries: [0, 0, 0, 0, 0, 0, 0],
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weekOverWeekDelta: null,
      );

      expect(metrics.hasAnyActivity, isFalse);
    });

    test('hasAnyActivity returns true with activity items', () {
      final metrics = DashboardMetrics(
        recentActivity: [
          ActivityItem(
            title: 'Test',
            subtitle: 'sub',
            icon: Icons.star,
            color: Colors.green,
            timestamp: DateTime.now(),
            isUpdate: false,
          ),
        ],
        lessonsSeries: [0, 0, 0, 0, 0, 0, 0],
        vocabularySeries: [0, 0, 0, 0, 0, 0, 0],
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weekOverWeekDelta: null,
      );

      expect(metrics.hasAnyActivity, isTrue);
    });

    test('hasAnyActivity returns true with non-zero lessons series', () {
      const metrics = DashboardMetrics(
        recentActivity: [],
        lessonsSeries: [0, 0, 0, 1, 0, 0, 0],
        vocabularySeries: [0, 0, 0, 0, 0, 0, 0],
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weekOverWeekDelta: null,
      );

      expect(metrics.hasAnyActivity, isTrue);
    });

    test('hasAnyActivity returns true with non-zero vocabulary series', () {
      const metrics = DashboardMetrics(
        recentActivity: [],
        lessonsSeries: [0, 0, 0, 0, 0, 0, 0],
        vocabularySeries: [0, 0, 3, 0, 0, 0, 0],
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weekOverWeekDelta: null,
      );

      expect(metrics.hasAnyActivity, isTrue);
    });

    test('weekOverWeekDelta is nullable', () {
      const withDelta = DashboardMetrics(
        recentActivity: [],
        lessonsSeries: [0, 0, 0, 0, 0, 0, 0],
        vocabularySeries: [0, 0, 0, 0, 0, 0, 0],
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weekOverWeekDelta: 25.0,
      );

      const withoutDelta = DashboardMetrics(
        recentActivity: [],
        lessonsSeries: [0, 0, 0, 0, 0, 0, 0],
        vocabularySeries: [0, 0, 0, 0, 0, 0, 0],
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weekOverWeekDelta: null,
      );

      expect(withDelta.weekOverWeekDelta, 25.0);
      expect(withoutDelta.weekOverWeekDelta, isNull);
    });

    test('series are always length 7', () {
      const metrics = DashboardMetrics(
        recentActivity: [],
        lessonsSeries: [1, 2, 3, 4, 5, 6, 7],
        vocabularySeries: [7, 6, 5, 4, 3, 2, 1],
        dayLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        weekOverWeekDelta: null,
      );

      expect(metrics.lessonsSeries.length, 7);
      expect(metrics.vocabularySeries.length, 7);
      expect(metrics.dayLabels.length, 7);
    });
  });
}
