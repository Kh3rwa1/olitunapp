import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/access/admin_access_screen.dart';
import 'package:itun/features/admin/presentation/access/controllers/admin_access_controller.dart';
import 'package:itun/features/admin/presentation/settings/sections/admin_badge_names_section.dart';
import 'package:itun/features/admin/presentation/settings/sections/admin_onboarding_video_section.dart';

class _FakeAdminAccessController extends StateNotifier<AdminAccessState>
    implements AdminAccessController {
  _FakeAdminAccessController()
    : super(
        const AdminAccessState(
          isLoading: false,
          admins: [
            {
              'userId': 'admin_1',
              'userEmail': 'admin@example.com',
              'userName': 'Super Admin',
            },
          ],
        ),
      );

  @override
  Future<void> addAdmin(String email) async {}

  @override
  Future<void> loadSummary() async {}

  @override
  Future<void> removeAdmin(String userId) async {}

  @override
  Future<void> resetPassword(String password) async {}

  @override
  void setMessage(String? value) {}

  @override
  void updateRevokeSessions(bool value) {}

  @override
  void updateSelectedUserId(String? value) {}
}

void main() {
  group('Admin Panel Responsive Layout Tests', () {
    testWidgets('AdminBadgeNamesSection renders cleanly at 320px width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final archerCtrl = TextEditingController(text: 'Santali Archer');
      final kudumCtrl = TextEditingController(text: 'Kudum Master');
      final kherwalCtrl = TextEditingController(text: 'Kherwal Elder');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminBadgeNamesSection(
                archerNameController: archerCtrl,
                kudumNameController: kudumCtrl,
                kherwalNameController: kherwalCtrl,
                onSave: () {},
                onReset: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Save Badge Names'), findsOneWidget);
      expect(find.text('Reset Defaults'), findsOneWidget);
    });

    testWidgets('AdminOnboardingVideoSection renders cleanly at 320px width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminOnboardingVideoSection(
                currentVideoUrl: 'https://example.com/onboarding.mp4',
                isUploading: false,
                onUpload: () {},
                onReset: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Custom Video Active'), findsOneWidget);
      expect(find.text('Upload Video'), findsOneWidget);
    });

    testWidgets('AdminAccessScreen renders without overflow on 320px mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminAccessControllerProvider.overrideWith(
              (ref) => _FakeAdminAccessController(),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: AdminAccessScreen())),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Admin Access'), findsOneWidget);
      expect(find.text('Team Members'), findsOneWidget);
    });
  });
}
