import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/admin_login_screen.dart';

void main() {
  testWidgets('renders the login form fields and helper copy', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AdminLoginScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Sign in'), findsOneWidget);
    expect(
      find.text('Need access? Ask a team owner to add you in Appwrite.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('sign-in with an invalid email keeps the user on the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AdminLoginScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    final emailFields = find.byType(TextFormField);
    expect(emailFields, findsAtLeast(2));
    await tester.enterText(emailFields.first, 'not-an-email');
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 400));

    // Client-side validation blocks the request and stays on the login form.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
  });
}
