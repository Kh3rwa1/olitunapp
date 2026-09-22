part of 'ai_studio_screen.dart';

extension _AiStudioInput on _AiStudioScreenState {
  // ── Input Panel ──────────────────────────────────────────────────────
  Widget _inputPanel(
    bool configured,
    AppLocalizations l10n,
    bool isDark, {
    required bool flex,
    required bool isMobile,
  }) {
    final draft = _draft;
    final locked = draft.busy || draft.selecting || _recording;
    final scanPending =
        _tool == _Tool.scan && draft.job != null && !draft.job!.isTerminal;
    final languages = studioLanguages.entries.where(
      (entry) => _tool != _Tool.translate || entry.key != 'sat-IN',
    );
    final panelTitle = switch (_tool) {
      _Tool.translate => l10n.aiStudioYourText,
      _Tool.transcribe => l10n.aiStudioYourAudio,
      _Tool.scan => l10n.aiStudioYourDocument,
    };

    final header = LayoutBuilder(
      builder: (context, headerConstraints) {
        final compact =
            headerConstraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;

        final titleWidget = Semantics(
          header: true,
          child: Text(
            panelTitle,
            style: AppTypography.inter(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );

        final dropdownWidget = SizedBox(
          width: compact ? double.infinity : (isMobile ? 136 : 154),
          height: 36,
          child: DropdownButtonFormField<String>(
            key: ValueKey('language-${_tool.name}-${draft.language}'),
            initialValue: draft.language,
            isExpanded: true,
            dropdownColor: isDark ? AppColors.studioDropdownDark : Colors.white,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              filled: true,
              fillColor: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.04,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            items: [
              for (final entry in languages)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: locked || scanPending
                ? null
                : (value) {
                    if (value != null) {
                      _setState(() => draft.language = value);
                      _maybeAutoRun();
                    }
                  },
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [titleWidget, const SizedBox(height: 6), dropdownWidget],
          );
        }

        return Row(
          children: [
            Expanded(child: titleWidget),
            const SizedBox(width: 8),
            dropdownWidget,
          ],
        );
      },
    );

    Widget body;
    if (_tool == _Tool.translate) {
      body = _buildTranslateInput(
        configured,
        locked,
        draft,
        l10n,
        isDark,
        isMobile,
      );
    } else if (_tool == _Tool.transcribe) {
      body = _buildTranscribeInput(locked, draft, l10n, isDark, isMobile);
    } else {
      body = _buildScanInput(
        locked,
        scanPending,
        draft,
        l10n,
        isDark,
        isMobile,
      );
    }

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (draft.error != null) ...[
          _notice(draft.error!, error: true, icon: Icons.error_outline_rounded),
          const SizedBox(height: 8),
        ],
        if (draft.busy) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              semanticsLabel: 'AI processing in progress',
              color: AppColors.primary,
              backgroundColor: AppColors.studioProgressBg,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 5),
          Semantics(
            liveRegion: true,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final dots = '.' * (1 + ((_pulse.value * 3).floor() % 3));
                return Text(
                  '${l10n.aiStudioThinking}$dots',
                  style: const TextStyle(
                    color: AppColors.amberEmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!scanPending) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _autoPill(draft, isDark),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('studio-process'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.elevatedButtonFg,
                    disabledBackgroundColor:
                        (isDark ? Colors.white : Colors.black).withValues(
                          alpha: 0.06,
                        ),
                    disabledForegroundColor: isDark
                        ? Colors.white24
                        : Colors.black26,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: configured && !locked && _validInput
                      ? () => unawaited(_process())
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_tool.icon, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          draft.busy
                              ? l10n.aiStudioProcessing
                              : l10n.aiStudioProcessWithAi(
                                  _tool.localizedLabel(l10n),
                                ),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isMobile ? 13 : 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return _studioCard(
      header: header,
      body: body,
      footer: footer,
      isDark: isDark,
      flex: flex,
      isMobile: isMobile,
    );
  }

  // ── Tool 1: Transcribe Input ─────────────────────────────────────────
  Widget _buildTranscribeInput(
    bool locked,
    _Draft draft,
    AppLocalizations l10n,
    bool isDark,
    bool isMobile,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 16 : 22,
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.03,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _recording
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.06,
                    ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: draft.busy || draft.selecting ? null : _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isMobile ? 64 : 70,
                  height: isMobile ? 64 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _recording
                        ? AppColors.studioRecordingRed
                        : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_recording
                                    ? AppColors.studioRecordingRed
                                    : AppColors.primary)
                                .withValues(alpha: 0.35),
                        blurRadius: _recording ? 20 : 12,
                        spreadRadius: _recording ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _recording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: isMobile ? 28 : 32,
                    color: _recording
                        ? Colors.white
                        : AppColors.elevatedButtonFg,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 10 : 14),
              FilledButton.tonal(
                key: const Key('studio-record'),
                style: FilledButton.styleFrom(
                  backgroundColor: _recording
                      ? AppColors.studioRecordingRed.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: _recording
                      ? AppColors.studioRecordingRed
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: draft.busy || draft.selecting
                    ? null
                    : _toggleRecording,
                child: Text(
                  _recording
                      ? l10n.aiStudioStopRecording(
                          _recordingSeconds.toString().padLeft(2, '0'),
                        )
                      : l10n.aiStudioRecordVoice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (_recording) ...[
                const SizedBox(height: 10),
                _waveform(),
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.aiStudioListening,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 14),
        if (draft.input != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.audiotrack_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    draft.input!.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 15,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('studio-pick'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
              side: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.12,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: locked ? null : _pick,
            icon: const Icon(Icons.upload_file_outlined, size: 15),
            label: Text(
              draft.selecting
                  ? l10n.aiStudioOpening
                  : draft.input == null
                  ? l10n.aiStudioUploadWav
                  : l10n.aiStudioReplaceRecording,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
