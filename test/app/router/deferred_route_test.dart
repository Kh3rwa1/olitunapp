import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/app/router/deferred_route.dart';

void main() {
  group('DeferredLibrary and DeferredRoute Tests', () {
    test('DeferredLibrary caches load future and marks isLoaded', () async {
      int loadCalls = 0;
      final lib = DeferredLibrary(() async {
        loadCalls++;
      });

      expect(lib.isLoaded, isFalse);
      final f1 = lib.ensureLoaded();
      final f2 = lib.ensureLoaded();
      expect(identical(f1, f2), isTrue);

      await f1;
      expect(lib.isLoaded, isTrue);
      expect(loadCalls, equals(1));
    });

    test(
      'DeferredLibrary resets pending future on error to allow retry',
      () async {
        int loadCalls = 0;
        final lib = DeferredLibrary(() async {
          loadCalls++;
          if (loadCalls == 1) throw Exception('Network timeout');
        });

        await expectLater(lib.ensureLoaded(), throwsA(isA<Exception>()));
        expect(lib.isLoaded, isFalse);

        // Second attempt succeeds
        await lib.ensureLoaded();
        expect(lib.isLoaded, isTrue);
        expect(loadCalls, equals(2));
      },
    );

    testWidgets('DeferredRoute renders builder directly when already loaded', (
      tester,
    ) async {
      final lib = DeferredLibrary(() async {});
      await lib.ensureLoaded();

      await tester.pumpWidget(
        MaterialApp(
          home: DeferredRoute(
            library: lib,
            builder: (_) => const Text('Admin Dashboard Loaded'),
          ),
        ),
      );

      expect(find.text('Admin Dashboard Loaded'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'DeferredRoute displays CircularProgressIndicator while loading inside Scaffold',
      (tester) async {
        final completer = Completer<void>();
        final lib = DeferredLibrary(() => completer.future);

        await tester.pumpWidget(
          MaterialApp(
            home: DeferredRoute(
              library: lib,
              builder: (_) => const Text('Done'),
            ),
          ),
        );

        // Loading state inside Scaffold
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.text('Done'), findsNothing);

        completer.complete();
        await tester.pumpAndSettle();

        expect(find.text('Done'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'DeferredRoute handles error with a retry IconButton inside Scaffold',
      (tester) async {
        bool shouldFail = true;
        final lib = DeferredLibrary(() async {
          if (shouldFail) throw Exception('Chunk download failed');
        });

        await tester.pumpWidget(
          MaterialApp(
            home: DeferredRoute(
              library: lib,
              builder: (_) => const Text('Success After Retry'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Error state inside Scaffold with refresh button
        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);

        shouldFail = false;
        await tester.tap(find.byIcon(Icons.refresh_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Success After Retry'), findsOneWidget);
      },
    );
  });
}
