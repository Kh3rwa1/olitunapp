import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itun/core/api/admin_dashboard_api.dart';
import 'package:itun/core/theme/app_colors.dart';
import '../../settings/controllers/admin_maintenance_controller.dart';
import '../../widgets/admin_page_header.dart';

class GamificationMaintenanceView extends ConsumerStatefulWidget {
  const GamificationMaintenanceView({super.key});

  @override
  ConsumerState<GamificationMaintenanceView> createState() =>
      _GamificationMaintenanceViewState();
}

class _GamificationMaintenanceViewState
    extends ConsumerState<GamificationMaintenanceView> {
  int _reload = 0;
  bool _maintenanceBusy = false;
  String? _maintenanceMessage;

  /// Which backing D1 tables exist, checked by the Worker.
  Future<Map<String, bool>> _loadSchemaHealth() =>
      ref.read(adminDashboardApiProvider).schemaHealth();

  Future<void> _createContentBackup() async {
    setState(() {
      _maintenanceBusy = true;
      _maintenanceMessage = 'Creating backup...';
    });
    try {
      final fileId = await AdminMaintenanceController(ref).backupContent();
      setState(() {
        _maintenanceMessage = 'Backup created: ${fileId ?? 'completed'}';
      });
    } catch (e) {
      setState(() {
        _maintenanceMessage = 'Backup failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _maintenanceBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 860;
    return Padding(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Maintenance',
            subtitle:
                'Backups, schema health, and production readiness checks without exposing secrets.',
            eyebrow: 'PRODUCT OPS',
            actions: [
              ElevatedButton.icon(
                onPressed: _maintenanceBusy ? null : _createContentBackup,
                icon: const Icon(Icons.backup_rounded, size: 18),
                label: const Text('Create backup'),
              ),
              IconButton(
                tooltip: 'Refresh health',
                onPressed: () => setState(() => _reload++),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (_maintenanceMessage != null) ...[
            const SizedBox(height: 12),
            SelectableText(_maintenanceMessage!),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<Map<String, bool>>(
              future: _loadSchemaHealth(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data ?? const <String, bool>{};
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = rows.entries.elementAt(index);
                    return ListTile(
                      leading: Icon(
                        entry.value
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: entry.value
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      title: Text(entry.key),
                      subtitle: Text(
                        entry.value
                            ? 'Available'
                            : 'Missing from the D1 schema',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
