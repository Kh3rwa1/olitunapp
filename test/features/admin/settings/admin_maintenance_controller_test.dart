import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/features/admin/presentation/settings/controllers/admin_maintenance_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockWidgetRef extends Mock implements WidgetRef {}

class MockAppwriteAuthService extends Mock implements AppwriteAuthService {}

void main() {
  late MockWidgetRef ref;
  late MockAppwriteAuthService authService;
  late AdminMaintenanceController controller;

  setUp(() {
    ref = MockWidgetRef();
    authService = MockAppwriteAuthService();
    when(() => ref.read(appwriteAuthServiceProvider)).thenReturn(authService);
    controller = AdminMaintenanceController(ref);
  });

  group('AdminMaintenanceController', () {
    test(
      'backup content calls the maintenance function with the exact confirmation phrase and returns the backup file id',
      () async {
        when(
          () => authService.executeAdminMaintenance(
            action: 'backup_content',
            confirmation: 'BACKUP CONTENT',
          ),
        ).thenAnswer(
          (_) async => {
            'success': true,
            'backup': {'fileId': 'file123'},
          },
        );

        final backupFileId = await controller.backupContent();

        expect(backupFileId, 'file123');
        verify(
          () => authService.executeAdminMaintenance(
            action: 'backup_content',
            confirmation: 'BACKUP CONTENT',
          ),
        ).called(1);
      },
    );

    test(
      'backup content returns null when the response carries no backup file id',
      () async {
        when(
          () => authService.executeAdminMaintenance(
            action: 'backup_content',
            confirmation: 'BACKUP CONTENT',
          ),
        ).thenAnswer((_) async => {'success': true});

        expect(await controller.backupContent(), isNull);
      },
    );

    test('backup content rethrows failures from the maintenance function', () {
      when(
        () => authService.executeAdminMaintenance(
          action: 'backup_content',
          confirmation: 'BACKUP CONTENT',
        ),
      ).thenThrow(AppwriteException('Not allowed', 403, 'general_rate_limit'));

      expect(
        controller.backupContent(),
        throwsA(isA<AppwriteException>().having((e) => e.code, 'code', 403)),
      );
    });

    test(
      'wipe and seed rethrows failures and uses the exact wipe confirmation phrase',
      () {
        when(
          () => authService.executeAdminMaintenance(
            action: 'wipe_content',
            confirmation: 'WIPE ALL',
          ),
        ).thenThrow(AppwriteException('boom', 500, 'server_error'));

        expect(controller.wipeAndSeed(), throwsA(isA<AppwriteException>()));
        verify(
          () => authService.executeAdminMaintenance(
            action: 'wipe_content',
            confirmation: 'WIPE ALL',
          ),
        ).called(1);
      },
    );
  });

  group('parseAdminMaintenanceResponse', () {
    test('returns the decoded payload for a successful response', () {
      final result = parseAdminMaintenanceResponse(
        statusCode: 200,
        body: '{"success":true,"backup":{"fileId":"abc"}}',
      );

      expect(result['success'], isTrue);
      expect(result['backup'], {'fileId': 'abc'});
    });

    test('treats an empty body as a failed maintenance request', () {
      expect(
        () => parseAdminMaintenanceResponse(statusCode: 200, body: '  '),
        throwsA(
          isA<AppwriteException>()
              .having(
                (e) => e.message,
                'message',
                'Admin maintenance request failed.',
              )
              .having((e) => e.type, 'type', 'admin_maintenance_failed'),
        ),
      );
    });

    test('throws with the server message for non-2xx status codes', () {
      expect(
        () => parseAdminMaintenanceResponse(
          statusCode: 403,
          body: '{"success":false,"message":"Not allowed"}',
        ),
        throwsA(
          isA<AppwriteException>()
              .having((e) => e.message, 'message', 'Not allowed')
              .having((e) => e.code, 'code', 403)
              .having((e) => e.type, 'type', 'admin_maintenance_failed'),
        ),
      );
    });

    test('throws for a 200 body without a success flag', () {
      expect(
        () => parseAdminMaintenanceResponse(
          statusCode: 200,
          body: '{"message":"silently failed"}',
        ),
        throwsA(
          isA<AppwriteException>()
              .having((e) => e.message, 'message', 'silently failed')
              .having((e) => e.type, 'type', 'admin_maintenance_failed'),
        ),
      );
    });

    test('falls back to a generic message when the failure body is empty', () {
      expect(
        () => parseAdminMaintenanceResponse(statusCode: 500, body: ''),
        throwsA(
          isA<AppwriteException>().having(
            (e) => e.message,
            'message',
            'Admin maintenance request failed.',
          ),
        ),
      );
    });

    test('rejects a body that is not a JSON object', () {
      expect(
        () => parseAdminMaintenanceResponse(
          statusCode: 200,
          body: '["not","a","map"]',
        ),
        throwsA(
          isA<AppwriteException>().having(
            (e) => e.type,
            'type',
            'invalid_response',
          ),
        ),
      );
    });
  });

  group('adminMaintenanceBackupFileId', () {
    test('extracts the file id from a nested backup object', () {
      expect(
        adminMaintenanceBackupFileId({
          'backup': {'fileId': 'file42'},
        }),
        'file42',
      );
    });

    test('returns null when the backup payload is missing or malformed', () {
      expect(adminMaintenanceBackupFileId({}), isNull);
      expect(adminMaintenanceBackupFileId({'backup': 'not-a-map'}), isNull);
      expect(
        adminMaintenanceBackupFileId({
          'backup': {'fileId': ''},
        }),
        isNull,
      );
      expect(
        adminMaintenanceBackupFileId({
          'backup': {'fileId': 42},
        }),
        isNull,
      );
    });
  });
}
