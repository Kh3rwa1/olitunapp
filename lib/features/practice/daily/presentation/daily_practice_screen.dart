// Daily practice: the same retrieval-practice flow as Today's Review, fed by
// [dailyPracticeCardsProvider] (due items → mistakes → unseen content), so
// there is always a 5-minute session available after the curriculum ends.

import 'package:flutter/material.dart';

import '../../../review/presentation/review_session_screen.dart';

/// Route of the daily practice session (registered in learning_routes.dart).
const String dailyPracticeRoute = '/practice/daily';

class DailyPracticeScreen extends StatelessWidget {
  const DailyPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewSessionScreen(mode: ReviewSessionMode.dailyPractice);
  }
}
