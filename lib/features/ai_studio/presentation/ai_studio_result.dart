part of 'ai_studio_screen.dart';

extension _AiStudioResult on _AiStudioScreenState {
  // ── Result Panel ─────────────────────────────────────────────────────
  Widget _resultPanel(
    AppLocalizations l10n,
    bool isDark, {
    required bool flex,
    required bool isMobile,
  }) {
    final draft = _draft;
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
        _statusBadge(l10n, ref.watch(aiStudioServiceProvider).configured),
      ],
    );

    Widget body;
    if (_tool == _Tool.scan && job != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _notice(
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
              onPressed:
                  draft.busy || !ref.watch(aiStudioServiceProvider).configured
                  ? null
                  : () => _process(checkStatus: true),
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
              onPressed: () => _setState(() {
                draft.result.text = job.text;
                draft.edited = false;
              }),
              child: Text(
                AppLocalizations.of(context)!.aiStudioReplaceWithScan,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 6),
          ],
          _buildResultEditor(draft, l10n, isDark, isMobile),
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
      body = _buildResultEditor(draft, l10n, isDark, isMobile);
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
                onPressed: hasText ? () => _shareResult(copy: true) : null,
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
                onPressed: hasText ? () => _shareResult(copy: false) : null,
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
              if (_tool != _Tool.translate)
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
                      hasText &&
                          draft.language != 'sat-IN' &&
                          !_drafts[_Tool.translate]!.busy
                      ? () => _sendResult(voice: false)
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
                onPressed: hasText ? () => _sendResult(voice: true) : null,
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
                onPressed: () => unawaited(_flipTo(showResult: false)),
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
    }

    return _studioCard(
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
            'result-${_tool.name}-$hasText-${job?.status ?? 'none'}',
          ),
          child: body,
        ),
      ),
      footer: footer,
      isDark: isDark,
      flex: flex,
      isMobile: isMobile,
    );
  }

  Widget _buildResultEditor(
    _Draft draft,
    AppLocalizations l10n,
    bool isDark,
    bool isMobile,
  ) {
    return TextField(
      key: ValueKey('studio-result-${_tool.name}'),
      controller: draft.result,
      minLines: isMobile ? 5 : 6,
      maxLines: null,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontFamily: 'OlChiki',
        fontSize: isMobile ? 14 : 15,
        height: 1.5,
      ),
      onChanged: (_) => _setState(() => draft.edited = true),
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
