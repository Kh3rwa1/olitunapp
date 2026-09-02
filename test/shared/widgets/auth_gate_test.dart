import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/widgets/auth_gate.dart';

Widget _host({required AsyncValue<bool> authState}) {
  final router = GoRouter(
    initialLocation: '/gated',
    routes: [
      GoRoute(
        path: '/gated',
        builder: (context, state) => const AuthGate(child: Text('SECRET')),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const Text('WELCOME'),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

Future<void> _pumpAuthed(
  WidgetTester tester,
  AsyncValue<bool> state, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isAuthenticatedProvider.overrideWith(
          (ref) async => state.value ?? (throw state.error!),
        ),
        ...overrides,
      ],
      child: _host(authState: state),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the protected child when authenticated', (tester) async {
    await _pumpAuthed(tester, const AsyncValue.data(true));
    expect(find.text('SECRET'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
  });

  testWidgets('shows the login prompt with default copy when signed out', (
    tester,
  ) async {
    await _pumpAuthed(tester, const AsyncValue.data(false));

    expect(find.text('SECRET'), findsNothing);
    expect(find.text('Login Required'), findsOneWidget);
    expect(
      find.text('Sign in to unlock this feature and track your progress.'),
      findsOneWidget,
    );
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets('custom title, subtitle and icon are honoured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [isAuthenticatedProvider.overrideWith((ref) async => false)],
        child: const MaterialApp(
          home: AuthGate(
            title: 'Members only',
            subtitle: 'Create an account to continue.',
            icon: Icons.workspace_premium,
            child: Text('PREMIUM'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Members only'), findsOneWidget);
    expect(find.text('Create an account to continue.'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
  });

  testWidgets('shows the loading spinner while auth resolves', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWith(
            (ref) => Completer<bool>().future,
          ),
        ],
        child: _host(authState: const AsyncValue.loading()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('SECRET'), findsNothing);
  });

  testWidgets('auth errors fall back to the login prompt', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWith(
            (ref) async => throw Exception('network down'),
          ),
        ],
        child: _host(
          authState: AsyncValue<bool>.error(
            Exception('offline'),
            StackTrace.empty,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Login Required'), findsOneWidget);
  });

  testWidgets('Sign In navigates to /welcome', (tester) async {
    await _pumpAuthed(tester, const AsyncValue.data(false));

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME'), findsOneWidget);
  });
}
