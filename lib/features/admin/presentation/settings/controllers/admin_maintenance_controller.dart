import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/auth/appwrite_auth_service.dart';
import '../../../../../core/observability/crash_reporting.dart';
import '../../../../../core/storage/cache_service.dart';
import '../../../../../shared/providers/seed_provider.dart';

class AdminMaintenanceController {
  AdminMaintenanceController(this.ref);

  final WidgetRef ref;

  Future<String?> backupContent() async {
    try {
      final result = await ref
          .read(appwriteAuthServiceProvider)
          .executeAdminMaintenance(
            action: 'backup_content',
            confirmation: 'BACKUP CONTENT',
          );
      final backupFileId = adminMaintenanceBackupFileId(result);
      CrashReporting.addAdminMaintenanceBreadcrumb(
        action: 'backup_content',
        backupFileId: backupFileId,
      );
      return backupFileId;
    } catch (e) {
      CrashReporting.addAdminMaintenanceBreadcrumb(
        action: 'backup_content',
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<String?> wipeAndSeed() async {
    try {
      final result = await ref
          .read(appwriteAuthServiceProvider)
          .executeAdminMaintenance(
            action: 'wipe_content',
            confirmation: 'WIPE ALL',
          );
      final backupFileId = adminMaintenanceBackupFileId(result);
      CrashReporting.addAdminMaintenanceBreadcrumb(
        action: 'wipe_content',
        backupFileId: backupFileId,
      );

      await CacheService.clear();
      await seedAppContent(ref);
      return backupFileId;
    } catch (e) {
      CrashReporting.addAdminMaintenanceBreadcrumb(
        action: 'wipe_content',
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}
