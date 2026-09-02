import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/widgets/parallax_hero_sliver_app_bar.dart';

Widget _host(Widget sliver, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Material(
        child: CustomScrollView(
          slivers: [
            sliver,
            const SliverToBoxAdapter(
              child: SizedBox(height: 1200, child: Center(child: Text('BODY'))),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the expanded header with gradient and title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ParallaxHeroSliverAppBar(
          gradient: LinearGradient(colors: [Color(0xFF3355EE), Colors.purple]),
          glyph: 'ᱚ',
          title: Text('Letters'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.text('Letters'), findsOneWidget);
    expect(find.text('ᱚ'), findsOneWidget);
    expect(find.byType(FlexibleSpaceBar), findsOneWidget);
  });

  testWidgets('supports leading actions and a hero child', (tester) async {
    await tester.pumpWidget(
      _host(
        const ParallaxHeroSliverAppBar(
          gradient: LinearGradient(colors: [Colors.blue, Colors.red]),
          title: Text('Stories'),
          leading: Icon(Icons.arrow_back),
          actions: [Icon(Icons.share)],
          heroChild: Icon(Icons.auto_stories),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
  });

  testWidgets('heroTag wraps the background in a Hero', (tester) async {
    await tester.pumpWidget(
      _host(
        const ParallaxHeroSliverAppBar(
          gradient: LinearGradient(colors: [Colors.indigo, Colors.cyan]),
          heroTag: 'hero/letters/cat_1',
          title: Text('Tagged'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'hero/letters/cat_1');
  });

  testWidgets('heroChildFullBleed fills the expanded header', (tester) async {
    await tester.pumpWidget(
      _host(
        const ParallaxHeroSliverAppBar(
          gradient: LinearGradient(colors: [Colors.teal, Colors.lime]),
          heroChild: FlutterLogo(size: 200),
          heroChildFullBleed: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logoFinder = find.byType(FlutterLogo);
    expect(logoFinder, findsOneWidget);
    final size = tester.getSize(logoFinder);
    // Full-bleed: the logo spans (nearly) the whole expanded header width.
    expect(size.width, greaterThan(300));
  });

  testWidgets('collapses when scrolled like a large app bar', (tester) async {
    await tester.pumpWidget(
      _host(
        const ParallaxHeroSliverAppBar(
          gradient: LinearGradient(colors: [Colors.pink, Colors.orange]),
          title: Text('Scrollable'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragFrom(const Offset(200, 400), const Offset(0, -600));
    await tester.pumpAndSettle();

    // After scrolling, the page content has moved up into the header area.
    expect(tester.getRect(find.text('BODY')).top, lessThan(400));
  });

  testWidgets('reduce-motion keeps the bar functional without stretch', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ParallaxHeroSliverAppBar(
          gradient: LinearGradient(colors: [Colors.brown, Colors.amber]),
          title: Text('Calm'),
        ),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calm'), findsOneWidget);

    final bar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    // Reduce motion disables stretch + parallax collapse.
    expect(bar.stretch, isFalse);
    final space = tester.widget<FlexibleSpaceBar>(
      find.byType(FlexibleSpaceBar),
    );
    expect(space.collapseMode, CollapseMode.none);
    expect(space.stretchModes, isEmpty);
  });
}
