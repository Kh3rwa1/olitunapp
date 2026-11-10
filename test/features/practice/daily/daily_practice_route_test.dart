import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/practice/daily/presentation/daily_practice_route.dart';

void main() {
  test(
    'daily practice route is the path the notification router deep-links to',
    () {
      expect(dailyPracticeRoute, '/practice/daily');
    },
  );
}
