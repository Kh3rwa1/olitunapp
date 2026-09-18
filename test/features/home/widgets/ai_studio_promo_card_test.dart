import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/home/presentation/widgets/ai_studio_promo_card.dart';

void main() {
  group('AiStudioPromoCard', () {
    testWidgets('renders at home bottom and routes to /studio on tap', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: SingleChildScrollView(child: AiStudioPromoCard()),
            ),
          ),
          GoRoute(
            path: '/studio',
            builder: (_, _) => const Scaffold(body: Text('ai-studio')),
          ),
        ],
      );

      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('AI Studio'), findsOneWidget);
      expect(find.textContaining('NEW • AI STUDIO'), findsOneWidget);

      await tester.tap(find.text('AI Studio'));
      await tester.pumpAndSettle();

      expect(find.text('ai-studio'), findsOneWidget);
    });
  });
}
