import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/presentation/providers/audio_download_providers.dart';
import 'settings_widgets.dart';

/// Phase 6 "Cache management" UI (spec line 1034): shows offline audio
/// storage usage and clip count, and lets the learner delete all
/// downloaded story audio.
///
/// Rendered only when the `audioDownloadsEnabled` flag is on AND the
/// platform supports file storage (native); on web and with the flag
/// off the card collapses to nothing so the existing settings screen
/// is unchanged (spec §27).
class DownloadsManagementCard extends ConsumerWidget {
  final int index;

  const DownloadsManagementCard({super.key, required this.index});

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(downloadsAvailableProvider);
    if (!available) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usage = ref.watch(downloadStorageUsageProvider).valueOrNull ?? 0;
    final count = ref.watch(downloadCountProvider).valueOrNull ?? 0;

    return SettingsCard(
      title: 'Downloads',
      icon: Icons.download_rounded,
      color: AppColors.duoBlue,
      index: index,
      children: [
        SettingTile(
          icon: Icons.storage_rounded,
          title: 'Offline audio',
          subtitle:
              '${_formatBytes(usage)} used · $count clip${count == 1 ? '' : 's'} saved',
          isDark: isDark,
          onTap: () {
            // Re-scan the manifest and any in-flight download state.
            ref.invalidate(downloadStorageUsageProvider);
            ref.invalidate(downloadCountProvider);
          },
        ),
        const SizedBox(height: 10),
        SettingTile(
          icon: Icons.delete_sweep_rounded,
          title: 'Delete all downloads',
          subtitle: 'Free up space by removing every offline story clip',
          isDark: isDark,
          isDestructive: true,
          onTap: () => _confirmDeleteAll(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all downloads?'),
        content: const Text(
          'This removes every offline story audio clip from this device. '
          'Stories will stream again when you are back online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.duoRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(audioDownloadProvider.notifier).deleteAll();
      ref.invalidate(downloadStorageUsageProvider);
      ref.invalidate(downloadCountProvider);
    } catch (e) {
      AppLogger.warning('DownloadsManagementCard: delete all failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not clear downloads')),
        );
      }
    }
  }
}
