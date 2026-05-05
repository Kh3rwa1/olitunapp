import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/features/admin/providers/admin_auth_provider.dart';

class _MockAuth extends Mock implements AppwriteAuthService {}

void main() {
  group('AdminAuthService', () {
    late _MockAuth mockAuth;

    setUp(() {
      mockAuth = _MockAuth();
    });

    test('isCurrentUserAdmin returns false when teams list is empty', () async {
      final service = AdminAuthService(
        mockAuth,
        teamsListFetcher: () async => [],
      );
      expect(await service.isCurrentUserAdmin(), isFalse);
    });

    test(
      'isCurrentUserAdmin returns false when admin team id is not in list',
      () async {
        final service = AdminAuthService(
          mockAuth,
          teamsListFetcher: () async => ['team-abc', 'team-xyz'],
        );
        expect(await service.isCurrentUserAdmin(), isFalse);
      },
    );

    test('isCurrentUserAdmin returns false when fetcher throws', () async {
      final service = AdminAuthService(
        mockAuth,
        teamsListFetcher: () async => throw Exception('network error'),
      );
      expect(await service.isCurrentUserAdmin(), isFalse);
    });
  });
}
