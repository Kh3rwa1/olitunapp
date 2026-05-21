import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/admin_form_widgets.dart';

class AdminOnboardingVideoSection extends StatelessWidget {
  const AdminOnboardingVideoSection({
    super.key,
    required this.currentVideoUrl,
    required this.isUploading,
    required this.onUpload,
    required this.onReset,
  });

  final String? currentVideoUrl;
  final bool isUploading;
  final VoidCallback onUpload;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentVideoUrl != null
                            ? AppColors.success
                            : AdminTokens.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      currentVideoUrl != null
                          ? 'Custom Video Active'
                          : 'Using Default Bundled Video',
                      style: AdminTokens.bodyStrong(isDark),
                    ),
                  ],
                ),
                if (currentVideoUrl != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AdminTokens.base(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusXs),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Text(
                      currentVideoUrl!,
                      style: AdminTokens.label(
                        isDark,
                      ).copyWith(fontFamily: 'monospace'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AdminPrimaryButton(
                  label: isUploading ? 'Uploading…' : 'Upload Video',
                  icon: isUploading
                      ? Icons.hourglass_top_rounded
                      : Icons.cloud_upload_rounded,
                  onTap: isUploading ? () {} : onUpload,
                ),
              ),
              if (currentVideoUrl != null) ...[
                const SizedBox(width: 12),
                AdminSecondaryButton(
                  label: 'Reset',
                  icon: Icons.restore_rounded,
                  onTap: onReset,
                ),
              ],
            ],
          ),
          if (isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(
                backgroundColor: AdminTokens.accentSoft(isDark),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AdminTokens.accent,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
