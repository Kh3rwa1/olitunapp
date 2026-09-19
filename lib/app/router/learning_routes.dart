import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/lessons/presentation/category_lessons_screen.dart';
import '../../features/lessons/presentation/lesson_block_detail_screen.dart';
import '../../features/lessons/presentation/practice/practice_screen.dart';
import '../../features/content/presentation/content_detail_screen.dart';
import '../../features/learn/presentation/screens/content_grid_screen.dart';
import '../../features/quiz/presentation/quiz_list_screen.dart';
import '../../features/quiz/presentation/quiz_screen.dart';
import '../../features/quiz/presentation/mistake_review_screen.dart';
import '../../features/review/presentation/review_session_screen.dart';
import '../../features/home/presentation/screens/ai_translator_screen.dart';
import '../../features/ai_studio/presentation/ai_studio_screen.dart';
import '../../features/voice/presentation/screens/santali_voice_screen.dart';
import '../../shared/models/content_item.dart';
import 'route_names.dart';

List<RouteBase> buildLearningRoutes({
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  drillRoute,
  required GoRoute Function({
    required String path,
    String? name,
    required Widget Function(BuildContext, GoRouterState) child,
  })
  modalRoute,
}) {
  return [
    drillRoute(path: '/quizzes', child: (_, _) => const QuizListScreen()),
    drillRoute(path: '/mistakes', child: (_, _) => const MistakeReviewScreen()),
    drillRoute(path: '/review', child: (_, _) => const ReviewSessionScreen()),
    drillRoute(
      path: '/lessons/:categoryId',
      name: RouteNames.lessons,
      child: (_, state) => CategoryLessonsScreen(
        categoryId: state.pathParameters['categoryId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/lesson/:lessonId',
      redirect: (context, state) {
        final id = state.pathParameters['lessonId'];
        return '/lesson/$id/block/0';
      },
    ),
    drillRoute(
      path: '/lesson/:lessonId/block/:blockIndex',
      child: (_, state) {
        final lessonId = state.pathParameters['lessonId'] ?? '';
        final blockIndexStr = state.pathParameters['blockIndex'] ?? '0';
        final blockIndex = int.tryParse(blockIndexStr) ?? 0;
        return LessonBlockDetailScreen(
          lessonId: lessonId,
          initialBlockIndex: blockIndex,
        );
      },
    ),
    drillRoute(
      path: '/letter/standalone/:subcategoryId',
      child: (_, state) {
        final pathParam = state.pathParameters['subcategoryId'];
        final subcategoryId = pathParam == 'all' ? null : pathParam;
        return ContentGridScreen(
          kind: ContentKind.letter,
          subcategoryId: subcategoryId,
        );
      },
    ),
    drillRoute(
      path: '/number/standalone/:subcategoryId',
      child: (_, state) {
        final pathParam = state.pathParameters['subcategoryId'];
        final subcategoryId = pathParam == 'all' ? null : pathParam;
        return ContentGridScreen(
          kind: ContentKind.number,
          subcategoryId: subcategoryId,
        );
      },
    ),
    GoRoute(
      path: '/letter/:lessonId/:letterId',
      redirect: (context, state) {
        final id = state.pathParameters['letterId'];
        final lessonId = state.pathParameters['lessonId'];
        final block = state.uri.queryParameters['block'];
        final blockQ = block != null && block.isNotEmpty
            ? '&block=$block'
            : '';
        return '/content/letter/$id?lessonId=$lessonId$blockQ';
      },
    ),
    GoRoute(
      path: '/word/:lessonId/:wordId',
      redirect: (context, state) {
        final id = state.pathParameters['wordId'];
        final lessonId = state.pathParameters['lessonId'];
        final block = state.uri.queryParameters['block'];
        final blockQ = block != null && block.isNotEmpty
            ? '&block=$block'
            : '';
        return '/content/word/$id?lessonId=$lessonId$blockQ';
      },
    ),
    GoRoute(
      path: '/number/:lessonId/:numberId',
      redirect: (context, state) {
        final id = state.pathParameters['numberId'];
        final lessonId = state.pathParameters['lessonId'];
        final block = state.uri.queryParameters['block'];
        final blockQ = block != null && block.isNotEmpty
            ? '&block=$block'
            : '';
        return '/content/number/$id?lessonId=$lessonId$blockQ';
      },
    ),
    GoRoute(
      path: '/sentence/:lessonId/:sentenceId',
      redirect: (context, state) {
        final id = state.pathParameters['sentenceId'];
        final lessonId = state.pathParameters['lessonId'];
        final block = state.uri.queryParameters['block'];
        final blockQ = block != null && block.isNotEmpty
            ? '&block=$block'
            : '';
        return '/content/sentence/$id?lessonId=$lessonId$blockQ';
      },
    ),
    drillRoute(
      path: '/content/:kind/:id',
      child: (_, state) {
        final kindStr = state.pathParameters['kind'] ?? 'lesson';
        final id = state.pathParameters['id'] ?? '';
        final kind = ContentKind.fromString(kindStr);
        final lessonId = state.uri.queryParameters['lessonId'];
        final blockIndex =
            int.tryParse(state.uri.queryParameters['block'] ?? '') ?? 0;
        return ContentDetailScreen(
          kind: kind,
          id: id,
          lessonId: lessonId,
          blockIndex: blockIndex,
        );
      },
    ),
    drillRoute(
      path: '/practice/:char/:name',
      child: (_, state) => PracticeScreen(
        letterChar: state.pathParameters['char'] ?? '',
        letterName: state.pathParameters['name'] ?? '',
        startInTrace: state.uri.queryParameters['mode'] == 'trace',
      ),
    ),
    modalRoute(path: '/translate', child: (_, _) => const AiTranslatorScreen()),
    modalRoute(
      path: '/voice',
      child: (_, state) => SantaliVoiceScreen(
        initialText: state.extra is String ? state.extra as String : null,
      ),
    ),
    modalRoute(path: '/studio', child: (_, _) => const AiStudioScreen()),
    drillRoute(
      path: '/quiz/:quizId',
      name: RouteNames.quiz,
      child: (_, state) => QuizScreen(
        quizId: state.pathParameters['quizId'] ?? '',
        lessonId: state.uri.queryParameters['lessonId'],
      ),
    ),
  ];
}
