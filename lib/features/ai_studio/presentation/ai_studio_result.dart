import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/ai_spark_assistant.dart';
import 'ai_studio_layout.dart';
import 'ai_studio_session.dart';

/// Result side of the studio: processing spark, scan job status, the
/// editable result and the copy / share / hand-off actions.
class StudioResultPanel extends StatelessWidget {
  const StudioResultPanel({
    super.key,
    required this.tool,
    required this.draft,
    required this.configured,
    required this.translateBusy,
    required this.statusBadge,
    required this.flex,
    required this.isMobile,
    required this.onRestoreSpark,
    required this.onCheckStatus,
    required this.onReplaceWithScan,
    required this.onEdited,
    required this.onShare,
    required this.onSend,
    required this.onEditSource,
  });

  final StudioTool tool;
  final StudioDraft draft;
  final bool configured;

  /// Whether the Translate tool's own draft is busy (blocks hand-off).
  final bool translateBusy;
  final Widget statusBadge;
  final bool flex;
  final bool isMobile;
  final VoidCallback onRestoreSpark;
  final VoidCallback onCheckStatus;
  final VoidCallback onReplaceWithScan;
  final VoidCallback onEdited;

  /// `copy: true` copies, otherwise opens the share sheet.
  final void Function(bool copy) onShare;

  /// `voice: true` opens Voice Studio, otherwise hands off to Translate.
  final void Function(bool voice) onSend;
  final VoidCallback onEditSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = draft.result.text.trim().isNotEmpty;
    final job = draft.job;

    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              l10n.aiStudioReviewAndUse,
              style: AppTypography.inter(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        statusBadge,
      ],
    );

    final isProcessing =
        draft.busy ||
        (tool == StudioTool.scan &&
            job != null &&
            !job.isTerminal &&
            job.text.isEmpty);

    Widget body;
    if (isProcessing) {
      final status = studioSparkStatus(tool, l10n);
      final subhead = studioSparkSubhead(tool, job);
      body = Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 18 : 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AiSparkAssistant(
                statusText: status,
                subheadText: subhead,
                size: isMobile ? 180 : 220,
                onTap: onRestoreSpark,
              ),
              if (tool == StudioTool.scan &&
                  job != null &&
                  !job.isTerminal &&
                  !draft.auto) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('studio-check-status'),
                  onPressed: draft.busy || !configured ? null : onCheckStatus,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: Text(
                    AppLocalizations.of(context)!.aiStudioCheckStatus,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (tool == StudioTool.scan && job != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioNotice(
            job.isTerminal
                ? 'Scan status: ${job.status}. Review any available text below.'
                : (draft.auto
                      ? l10n.aiStudioScanningLive
                      : 'Scan status: ${job.status}. Use Check status for updates. Keep this screen open to retain this job.'),
            icon: job.isTerminal
                ? Icons.description_outlined
                : Icons.hourglass_top_rounded,
          ),
          const SizedBox(height: 6),
          SelectableText(
            AppLocalizations.of(context)!.aiStudioJobId(job.id),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 6),
          if (!job.isTerminal) ...[
            OutlinedButton.icon(
              key: const Key('studio-check-status'),
              onPressed: draft.busy || !configured ? null : onCheckStatus,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                AppLocalizations.of(context)!.aiStudioCheckStatus,
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (draft.edited && job.text.isNotEmpty) ...[
            TextButton(
              onPressed: onReplaceWithScan,
              child: Text(
                AppLocalizations.of(context)!.aiStudioReplaceWithScan,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 6),
          ],
          StudioResultEditor(
            tool: tool,
            draft: draft,
            isMobile: isMobile,
            onEdited: onEdited,
          ),
        ],
      );
    } else if (!hasText && !draft.edited) {
      body = Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 24 : 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 44 : 52,
                height: isMobile ? 44 : 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.04,
                  ),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: isMobile ? 20 : 24,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aiStudioResultPlaceholder,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: isMobile ? 13 : 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.aiStudioResultDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontSize: isMobile ? 10.5 : 11,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = StudioResultEditor(
        tool: tool,
        draft: draft,
        isMobile: isMobile,
        onEdited: onEdited,
      );
    }

    Widget? footer;
    if (hasText || draft.edited) {
      footer = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: hasText ? () => onShare(true) : null,
                icon: const Icon(Icons.copy_outlined, size: 14),
                label: Text(
                  l10n.aiStudioCopy,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.12,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: hasText ? () => onShare(false) : null,
                icon: const Icon(
                  kIsWeb ? Icons.content_paste_outlined : Icons.share_outlined,
                  size: 14,
                ),
                label: Text(
                  kIsWeb ? l10n.aiStudioCopyToShare : l10n.aiStudioShare,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (tool != StudioTool.translate)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    side: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.12,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed:
                      hasText && draft.language != 'sat-IN' && !translateBusy
                      ? () => onSend(false)
                      : null,
                  icon: const Icon(Icons.translate_rounded, size: 14),
                  label: Text(
                    l10n.aiStudioTranslateResult,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                onPressed: hasText ? () => onSend(true) : null,
                icon: const Icon(Icons.graphic_eq_rounded, size: 14),
                label: Text(
                  l10n.aiStudioSendToVoiceStudio,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                onPressed: onEditSource,
                icon: const Icon(Icons.arrow_back_rounded, size: 13),
                label: Text(
                  AppLocalizations.of(context)!.aiStudioEditSource,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],
        ],
      );
    } else if (isProcessing && isMobile) {
      footer = Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          onPressed: onEditSource,
          icon: const Icon(Icons.arrow_back_rounded, size: 13),
          label: Text(
            AppLocalizations.of(context)!.aiStudioEditSource,
            style: const TextStyle(fontSize: 11.5),
          ),
        ),
      );
    }

    return StudioCard(
      header: header,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(
            'result-${tool.name}-$isProcessing-$hasText-${job?.status ?? 'none'}',
          ),
          child: body,
        ),
      ),
      footer: footer,
      flex: flex,
      isMobile: isMobile,
    );
  }
}

/// Editable OCR / transcription / translation result.
class StudioResultEditor extends StatelessWidget {
  const StudioResultEditor({
    super.key,
    required this.tool,
    required this.draft,
    required this.isMobile,
    required this.onEdited,
  });

  final StudioTool tool;
  final StudioDraft draft;
  final bool isMobile;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      key: ValueKey('studio-result-${tool.name}'),
      controller: draft.result,
      minLines: isMobile ? 5 : 6,
      maxLines: null,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontFamily: 'OlChiki',
        fontSize: isMobile ? 14 : 15,
        height: 1.5,
      ),
      onChanged: (_) => onEdited(),
      decoration: InputDecoration(
        hintText: l10n.aiStudioResultPlaceholder,
        filled: true,
        fillColor: (isDark ? Colors.black : Colors.white).withValues(
          alpha: 0.25,
        ),
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.08,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
