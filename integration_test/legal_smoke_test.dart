import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:itun/features/legal/presentation/legal_document_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('legal documents render for release smoke checks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalDocumentScreen(type: LegalDocumentType.privacy),
      ),
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('What Olitun Collects'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: LegalDocumentScreen(type: LegalDocumentType.terms),
      ),
    );

    expect(find.text('Terms Of Use'), findsOneWidget);
    expect(find.text('Learning Purpose'), findsOneWidget);
  });
}
