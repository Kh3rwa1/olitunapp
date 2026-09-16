import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/home/presentation/widgets/santali_voice_promo_card.dart';

void main() {
  group('SantaliVoicePromoCard', () {
    testWidgets('renders at home bottom and routes to /voice on tap', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: SingleChildScrollView(child: SantaliVoicePromoCard())),
          ),
          GoRoute(
            path: '/voice',
            builder: (_, _) => const Scaffold(body: Text('voice-studio')),
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

      expect(find.text('Santali AI Voice'), findsOneWidget);
      expect(find.text('Try now'), findsOneWidget);

      await tester.tap(find.text('Try now'));
      await tester.pumpAndSettle();

      expect(find.text('voice-studio'), findsOneWidget);
    });
  });
}
