import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/presentation/widgets/progress_screen_sections.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/waitlist_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';

WaitlistModel _booking({
  String id = 'w1',
  String status = 'new',
  String? eventDate,
  String? notes,
}) => WaitlistModel(
  id: id,
  fullName: 'Somi Murmu',
  phoneNumber: '9000000000',
  ceremonyType: 'karam',
  eventDate: eventDate,
  city: 'Dumka',
  state: 'Jharkhand',
  notes: notes,
  submittedAt: '2026-08-01T10:00:00Z',
  status: status,
);

Future<void> pumpSection(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ProgressErrorState', () {
    testWidgets('renders the failure copy and retry button', (tester) async {
      var retried = 0;
      await pumpSection(
        tester,
        ProgressErrorState(isDark: false, onRetry: () => retried++),
      );

      expect(find.text('Could not load progress'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });

  group('BintiGuruBookingsSection', () {
    testWidgets('shows the empty state when no bookings exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userWaitlistProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BintiGuruBookingsSection(isDark: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No bookings found'), findsOneWidget);
      expect(
        find.text(
          'Book verified reciters for your ceremonies under the Bakhed tab.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders booking cards with ceremony, status and city', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userWaitlistProvider.overrideWith(
              (ref) async => [
                _booking(
                  status: 'contacted',
                  eventDate: '2026-09-15T00:00:00Z',
                  notes: 'Bring the banam',
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BintiGuruBookingsSection(isDark: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Karam'), findsOneWidget);
      expect(find.text('CONTACTED'), findsOneWidget);
      expect(find.text('2026-09-15'), findsOneWidget);
      expect(find.text('Dumka, Jharkhand'), findsOneWidget);
      expect(find.text('Bring the banam'), findsOneWidget);
    });

    testWidgets('shows the failure message when the waitlist errors', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userWaitlistProvider.overrideWith(
              (ref) => Future<List<WaitlistModel>>.error(StateError('down')),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: BintiGuruBookingsSection(isDark: false)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load waitlist bookings.'), findsOneWidget);
    });
  });

  group('ActionTilesSection', () {
    testWidgets('renders the three account action tiles', (tester) async {
      var editName = 0;
      var share = 0;
      await pumpSection(
        tester,
        ActionTilesSection(
          isDark: false,
          onEditName: () => editName++,
          onShare: () => share++,
        ),
      );

      expect(find.text('Edit Name'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(BentoActionCard), findsNWidgets(3));

      await tester.tap(find.text('Edit Name'));
      await tester.tap(find.text('Share'));
      expect(editName, 1);
      expect(share, 1);
    });

    testWidgets('BentoActionCard invokes its callback on tap', (tester) async {
      var taps = 0;
      await pumpSection(
        tester,
        SizedBox(
          width: 160,
          height: 160,
          child: BentoActionCard(
            icon: Icons.edit_rounded,
            label: 'Do it',
            color: Colors.blue,
            isDark: false,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Do it'));
      expect(taps, 1);
    });
  });
}
