import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../../core/auth/admin_restore_client.dart';
import '../../../../../core/config/appwrite_config.dart';

import '../../../../../core/auth/appwrite_auth_service.dart';
import '../../../../../core/observability/crash_reporting.dart';
import '../../../../../core/storage/cache_service.dart';
import '../../../../../shared/providers/seed_provider.dart';

class AdminMaintenanceController {
  AdminMaintenanceController(this.ref);

  final WidgetRef ref;

  Future<Map<String, dynamic>> restoreContent(
    String fileId, {
    String? operationId,
    void Function(Map<String, dynamic>)? onProgress,
    bool Function()? shouldContinue,
    bool dryRun = false,
  }) async {
    final service = ref.read(appwriteAuthServiceProvider);
    if (!await service.isLoggedIn()) {
      throw AppwriteException('Sign in as an admin before restoring.', 401);
    }
    final prefs = await SharedPreferences.getInstance();
    final functions = Functions(service.client);
    final client = AdminRestoreClient(
      prefs: prefs,
      projectId: '${AppwriteConfig.endpoint}|${AppwriteConfig.projectId}',
      execute: (payload) async {
        final execution = await functions.createExecution(
          functionId: 'admin-maintenance',
          body: jsonEncode(payload),
          xasync: false,
          method: ExecutionMethod.pOST,
        );
        return parseAdminRestoreResponse(
          statusCode: execution.responseStatusCode,
          body: execution.responseBody,
        );
      },
    );
    final result = await client.restore(
      fileId: fileId,
      operationId: operationId,
      onProgress: onProgress,
      shouldContinue: shouldContinue,
      dryRun: dryRun,
    );
    // A local cache error must not turn an acknowledged restore into a new
    // destructive operation on the next UI retry.
    if (!dryRun) {
      try {
        await CacheService.clear();
      } catch (error) {
        CrashReporting.addAdminMaintenanceBreadcrumb(
          action: 'restore_cache_clear',
          success: false,
          error: error.toString(),
        );
      }
    }
    return result;
  }

  Future<Map<String, dynamic>> rollbackContent(
    String restoreId, {
    void Function(Map<String, dynamic>)? onProgress,
  }) async {
    final service = ref.read(appwriteAuthServiceProvider);
    if (!await service.isLoggedIn()) {
      throw AppwriteException('Sign in as an admin before rolling back.', 401);
    }
    final prefs = await SharedPreferences.getInstance();
    final functions = Functions(service.client);
    final client = AdminRestoreClient(
      prefs: prefs,
      projectId: '${AppwriteConfig.endpoint}|${AppwriteConfig.projectId}',
      execute: (payload) async {
        final execution = await functions.createExecution(
          functionId: 'admin-maintenance',
          body: jsonEncode(payload),
          xasync: false,
          method: ExecutionMethod.pOST,
        );
        return parseAdminRestoreResponse(
          statusCode: execution.responseStatusCode,
          body: execution.responseBody,
        );
      },
    );
    final result = await client.rollback(
      restoreId: restoreId,
      onProgress: onProgress,
    );
    try {
      await CacheService.clear();
    } catch (error) {
      CrashReporting.addAdminMaintenanceBreadcrumb(
        action: 'rollback_cache_clear',
        success: false,
        error: error.toString(),
      );
    }
    return result;
  }

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
