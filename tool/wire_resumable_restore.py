"""One-off assertion-checked wiring; run only on the restore review branch."""
from pathlib import Path
import json


def patch(path, old, new):
    p = Path(path)
    text = p.read_text()
    if text.count(old) != 1:
        raise RuntimeError(f'{path}: source anchor changed')
    p.write_text(text.replace(old, new))


main = 'functions/admin-maintenance/src/main.js'
patch(main, "import { restoreValidatedContent } from './restore_backup.js';", "import { runResumableRestore } from './resumable_restore.js';")
patch(main, '  createdAt = new Date().toISOString(),\n}) {', '  createdAt = new Date().toISOString(),\n  fileId = ID.unique(),\n}) {')
patch(main, '    BACKUP_BUCKET_ID,\n    ID.unique(),\n    file,', '    BACKUP_BUCKET_ID,\n    fileId,\n    file,')
patch(main, '''export async function restoreContent({ databases, storage, fileId }) {
  return restoreValidatedContent({
    databases,
    storage,
    fileId,
    databaseId: DATABASE_ID,
    bucketId: BACKUP_BUCKET_ID,
    collectionIds: CONTENT_COLLECTIONS,
    deleteCollection: collectionId => deleteCollectionDocuments(databases, collectionId),
    sanitizeDocument,
  });
}''', '''export async function ensureRestoreSafetyBackup({ databases, storage, actorUserId, fileId }) {
  const confirmed = file => {
    if (!Number.isInteger(file.chunksTotal) || file.chunksTotal < 1 ||
        file.chunksUploaded !== file.chunksTotal) {
      throw Object.assign(new Error('Safety backup upload is incomplete. No restore deletion is allowed. Inspect the upload before retrying.'), { status: 503 });
    }
    return { bucketId: BACKUP_BUCKET_ID, fileId: file.$id, fileName: file.name };
  };
  try {
    return confirmed(await storage.getFile(BACKUP_BUCKET_ID, fileId));
  } catch (err) {
    if (err.code !== 404 && err.status !== 404) throw err;
  }
  try {
    return await createContentBackup({ databases, storage, actorUserId, fileId });
  } catch (err) {
    if (err.code !== 409 && err.status !== 409) throw err;
    return confirmed(await storage.getFile(BACKUP_BUCKET_ID, fileId));
  }
}

export async function restoreContent({ databases, storage, fileId, restoreId, actorUserId }) {
  return runResumableRestore({
    databases, storage, fileId, restoreId, actorUserId,
    databaseId: DATABASE_ID, bucketId: BACKUP_BUCKET_ID,
    collectionIds: CONTENT_COLLECTIONS, sanitizeDocument,
    journalCollectionId: process.env.ADMIN_RESTORE_JOBS_COLLECTION_ID || 'admin_restore_jobs',
    pageQueries: limit => [Query.limit(limit), Query.orderAsc('$id')],
    ensureSafetyBackup: options => ensureRestoreSafetyBackup({ databases, storage, ...options }),
  });
}''')
patch(main, '''    if (body.action === 'restore_content') {
      const { restored, deleted } = await restoreContent({
        databases,
        storage,
        fileId: body.fileId,
      });

      log(
        `Admin maintenance restore_content completed by ${userId} using backup ${body.fileId}; safety backup ${backup.fileId}.`,
      );
      return json(res, 200, {
        success: true,
        backup,
        restored,
        deleted,
      });
    }

''', '')
patch(main, '    const storage = new Storage(client);\n    const backup = await createContentBackup({', '''    const storage = new Storage(client);
    // Restore owns its safety backup and durable identity; do not create a new
    // backup of a partially restored database on retries.
    if (body.action === 'restore_content') {
      const result = await restoreContent({
        databases, storage, fileId: body.fileId,
        restoreId: body.restoreId, actorUserId: userId,
      });
      log(`Admin restore ${result.jobId}: ${result.phase}.`);
      return json(res, result.complete ? 200 : 202, {
        success: true, ...result,
        message: result.complete ? 'Restore completed.' : 'Restore checkpoint saved; resume the same operation.',
      });
    }
    const backup = await createContentBackup({''')

controller = 'lib/features/admin/presentation/settings/controllers/admin_maintenance_controller.dart'
patch(controller, "import 'package:flutter_riverpod/flutter_riverpod.dart';", """import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../../core/auth/admin_restore_client.dart';
import '../../../../../core/config/appwrite_config.dart';""")
patch(controller, '  Future<String?> backupContent() async {', '''  Future<Map<String, dynamic>> restoreContent(
    String fileId, {
    String? operationId,
    void Function(Map<String, dynamic>)? onProgress,
    bool Function()? shouldContinue,
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
    );
    // A local cache error must not turn an acknowledged restore into a new
    // destructive operation on the next UI retry.
    try {
      await CacheService.clear();
    } catch (error) {
      CrashReporting.addAdminMaintenanceBreadcrumb(
        action: 'restore_cache_clear', success: false, error: error.toString(),
      );
    }
    return result;
  }

  Future<String?> backupContent() async {''')

section = 'lib/features/admin/presentation/settings/sections/admin_danger_zone_section.dart'
patch(section, '    required this.onWipe,', '    required this.onWipe,\n    this.onRestore,')
patch(section, '  final VoidCallback onWipe;', '  final VoidCallback onWipe;\n  final VoidCallback? onRestore;')
patch(section, "              AdminSecondaryButton(\n                label: 'Wipe & Re-seed',", """              if (onRestore != null)
                AdminSecondaryButton(
                  label: 'Restore / Resume',
                  icon: Icons.settings_backup_restore_rounded,
                  destructive: true,
                  onTap: onRestore!,
                ),
              AdminSecondaryButton(
                label: 'Wipe & Re-seed',""")

screen = 'lib/features/admin/presentation/settings/admin_settings_screen.dart'
patch(screen, "import 'widgets/admin_settings_section_card.dart';", "import 'widgets/admin_settings_section_card.dart';\nimport 'widgets/admin_restore_dialog.dart';")
patch(screen, '  Future<void> _executeBackupContent() async {', '''  Future<void> _showRestoreDialog() async {
    final controller = AdminMaintenanceController(ref);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminRestoreDialog(
        onRestore: (fileId, operationId, onProgress, shouldContinue) =>
            controller.restoreContent(
              fileId,
              operationId: operationId,
              onProgress: onProgress,
              shouldContinue: shouldContinue,
            ),
      ),
    );
    if (!mounted || result == null) return;
    final backup = result['backup'];
    _showSnackBar(
      'Restore completed. Safety backup: ${backup is Map ? backup['fileId'] : 'see operation record'}',
      AppColors.success,
    );
  }

  Future<void> _executeBackupContent() async {''')
patch(screen, '                        onWipe: _showWipeConfirmationDialog,', '                        onWipe: _showWipeConfirmationDialog,\n                        onRestore: _showRestoreDialog,')
patch('lib/core/auth/admin_restore_client.dart', ').whenComplete(() => _inFlight.remove(key));', ').whenComplete(() {\n      _inFlight.remove(key);\n    });')

config = Path('appwrite.json')
body = json.loads(config.read_text())
functions = [f for f in body['functions'] if f.get('$id') == 'admin-maintenance']
assert len(functions) == 1
for scope in ['documents.read', 'documents.write', 'files.read']:
    if scope not in functions[0]['scopes']:
        functions[0]['scopes'].append(scope)
config.write_text(json.dumps(body, indent=2) + '\n')
print('Restore runtime, recovery UI, and declared function scopes wired.')
