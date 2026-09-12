import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/features/profile/presentation/providers/weekly_leaderboard_provider.dart';

void main() {
  test('parses leaderboard only from a completed successful execution', () {
    const execution = FunctionExecutionResult(
      status: 'completed',
      statusCode: 200,
      responseBody: '''
        {
          "ok": true,
          "leaderboard": {
            "rank": 1,
            "points": 120,
            "totalParticipants": 4,
            "weekStart": "2026-09-07",
            "weekEnd": "2026-09-13",
            "generatedAt": "2026-09-10T05:30:00.000Z",
            "breakdown": {"lesson_completed": 120}
          }
        }
      ''',
    );
    final entity = parseWeeklyLeaderboardExecution(execution);
    expect(entity.rank, 1);
    expect(entity.points, 120);
  });

  test('rejects failed, non-200, and missing leaderboard executions', () {
    expect(
      () => parseWeeklyLeaderboardExecution(
        const FunctionExecutionResult(
          status: 'failed',
          statusCode: 500,
          responseBody: '{}',
        ),
      ),
      throwsStateError,
    );
    expect(
      () => parseWeeklyLeaderboardExecution(
        const FunctionExecutionResult(
          status: 'completed',
          statusCode: 401,
          responseBody: '{"ok":false}',
        ),
      ),
      throwsStateError,
    );
    expect(
      () => parseWeeklyLeaderboardExecution(
        const FunctionExecutionResult(
          status: 'completed',
          statusCode: 200,
          responseBody: '{"ok":true}',
        ),
      ),
      throwsFormatException,
    );
  });
}
