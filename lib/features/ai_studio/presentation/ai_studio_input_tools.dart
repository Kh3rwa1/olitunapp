part of 'ai_studio_screen.dart';

extension _AiStudioInputTools on _AiStudioScreenState {
  // ── Tool 2: Translate Input ──────────────────────────────────────────
  Widget _buildTranslateInput(
    bool configured,
    bool locked,
    _Draft draft,
    AppLocalizations l10n,
    bool isDark,
    bool isMobile,
  ) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (configured && !locked && _validInput) {
            _process();
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (configured && !locked && _validInput) {
            _process();
          }
        },
      },
      child: TextField(
        key: const Key('studio-source'),
        controller: _source,
        enabled: !locked,
        minLines: isMobile ? 4 : 5,
        maxLines: null,
        maxLength: 2000,
        maxLengthEnforcement: MaxLengthEnforcement.none,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: isMobile ? 13.5 : 14,
          height: 1.45,
        ),
        onChanged: (_) => _onSourceChanged(),
        decoration: InputDecoration(
          hintText: l10n.aiStudioTextPlaceholder,
          hintStyle: TextStyle(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.35,
            ),
            fontSize: 13,
          ),
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
          errorText: _source.text.trim().runes.length > 2000
              ? l10n.aiStudioTextLimitError
              : null,
          helperText:
              (!isMobile &&
                  (kIsWeb ||
                      defaultTargetPlatform == TargetPlatform.macOS ||
                      defaultTargetPlatform == TargetPlatform.windows ||
                      defaultTargetPlatform == TargetPlatform.linux))
              ? 'Press Ctrl+Enter / ⌘+Enter to submit'
              : null,
          helperStyle: TextStyle(
            fontSize: 10,
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.4,
            ),
          ),
          counterStyle: TextStyle(
            fontSize: 10,
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tool 3: Scan Input ───────────────────────────────────────────────
  Widget _buildScanInput(
    bool locked,
    bool scanPending,
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
            vertical: isMobile ? 18 : 24,
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.03,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.06,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: isMobile ? 30 : 36,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.aiStudioUploadPrompt,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                AppLocalizations.of(context)!.aiStudioUploadFormats,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 10.5,
                ),
              ),
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
                  Icons.insert_drive_file_outlined,
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
        LayoutBuilder(
          builder: (context, boxConstraints) {
            final compact = boxConstraints.maxWidth < 240;
            final pickButton = OutlinedButton.icon(
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
              onPressed: locked || scanPending ? null : _pick,
              icon: const Icon(Icons.upload_file_outlined, size: 15),
              label: Text(
                draft.selecting
                    ? l10n.aiStudioOpening
                    : draft.input == null
                    ? l10n.aiStudioChooseFile
                    : l10n.aiStudioReplaceFile,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );

            final cameraButton = OutlinedButton.icon(
              key: const Key('studio-camera'),
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
              onPressed: locked || scanPending
                  ? null
                  : () => _pick(camera: true),
              icon: const Icon(Icons.camera_alt_outlined, size: 15),
              label: Text(
                l10n.aiStudioCapturePage,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [pickButton, const SizedBox(height: 6), cameraButton],
              );
            }

            return Row(
              children: [
                Expanded(child: pickButton),
                const SizedBox(width: 8),
                Expanded(child: cameraButton),
              ],
            );
          },
        ),
      ],
    );
  }
}
