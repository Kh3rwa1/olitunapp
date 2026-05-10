import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/api/ai_service.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../widgets/admin_form_widgets.dart';
import 'letter_media_field.dart';

/// Bottom sheet for creating/editing a single letter.
///
/// This was originally an inline `showModalBottomSheet` closure inside
/// `AdminLettersScreen._showLetterDialog` (~680 lines). It is now a
/// self-contained [ConsumerStatefulWidget] that can be shown via
/// [LetterFormSheet.show].
class LetterFormSheet extends ConsumerStatefulWidget {
  final LetterModel? letter;
  const LetterFormSheet({super.key, this.letter});

  /// Convenience launcher.
  static void show(BuildContext context, WidgetRef ref, LetterModel? letter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LetterFormSheet(letter: letter),
    );
  }

  @override
  ConsumerState<LetterFormSheet> createState() => _LetterFormSheetState();
}

class _LetterFormSheetState extends ConsumerState<LetterFormSheet> {
  late final TextEditingController _charCtrl;
  late final TextEditingController _romanCtrl;
  late final TextEditingController _pronCtrl;

  String? _audioUrl;
  String? _imageUrl;
  String? _animationUrl;

  bool get _isEditing => widget.letter != null;

  @override
  void initState() {
    super.initState();
    _charCtrl = TextEditingController(text: widget.letter?.charOlChiki ?? '');
    _romanCtrl = TextEditingController(text: widget.letter?.transliterationLatin ?? '');
    _pronCtrl = TextEditingController(text: widget.letter?.pronunciation ?? '');
    _audioUrl = widget.letter?.audioUrl;
    _imageUrl = widget.letter?.imageUrl;
    _animationUrl = widget.letter?.animationUrl;
  }

  @override
  void dispose() {
    _charCtrl.dispose();
    _romanCtrl.dispose();
    _pronCtrl.dispose();
    super.dispose();
  }

  // ─── AI-assisted field fill ───────────────────────────

  Future<void> _magicFill(TextEditingController target, String Function(TranslateResult) transform) async {
    if (_charCtrl.text.trim().isEmpty) return;
    final result = await ref.read(aiServiceProvider).translateFromOlChiki(_charCtrl.text.trim());
    if (result != null && mounted) {
      setState(() => target.text = transform(result));
    }
  }

  // ─── Save ─────────────────────────────────────────────

  void _save() {
    HapticFeedback.lightImpact();
    final letter = LetterModel(
      id: widget.letter?.id ?? const Uuid().v4(),
      charOlChiki: _charCtrl.text,
      transliterationLatin: _romanCtrl.text,
      pronunciation: _pronCtrl.text.isNotEmpty ? _pronCtrl.text : null,
      order: widget.letter?.order ?? 0,
      audioUrl: _audioUrl,
      imageUrl: _imageUrl,
      animationUrl: _animationUrl,
    );
    if (_isEditing) {
      ref.read(lettersProvider.notifier).updateLetter(letter);
    } else {
      ref.read(lettersProvider.notifier).addLetter(letter);
    }
    Navigator.pop(context);
  }

  // ─── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AdminTokens.radius2xl)),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          _buildHandle(isDark),
          _buildTitle(isDark),
          Divider(height: 1, color: AdminTokens.divider(isDark)),
          Expanded(child: _buildFields(isDark)),
          _buildActions(isDark),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AdminTokens.borderStrong(isDark),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.premiumMint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditing ? Icons.edit_rounded : Icons.add_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isEditing ? 'Edit Letter' : 'New Letter',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminTextField(controller: _charCtrl, label: 'Ol Chiki Character', hint: 'e.g., ᱚ'),
          const SizedBox(height: 20),
          _aiRow(
            child: AdminTextField(controller: _romanCtrl, label: 'Romanization', hint: 'e.g., a'),
            tooltip: 'Magic Fill (Romanization)',
            onTap: () => _magicFill(_romanCtrl, (r) => r.translation.toLowerCase()),
          ),
          const SizedBox(height: 20),
          _aiRow(
            child: AdminTextField(controller: _pronCtrl, label: 'Pronunciation (optional)', hint: 'e.g., like "a" in "about"'),
            tooltip: 'Magic Fill (Pronunciation)',
            onTap: () => _magicFill(_pronCtrl, (r) => 'like "${r.translation}" in ...'),
          ),
          const SizedBox(height: 24),
          LetterMediaField(
            label: 'Audio Pronunciation',
            icon: Icons.audiotrack_rounded,
            accent: AppColors.primary,
            currentUrl: _audioUrl,
            uploadFolder: 'letters-audio',
            fileType: FileType.audio,
            onUploaded: (url) => setState(() => _audioUrl = url),
          ),
          const SizedBox(height: 24),
          LetterMediaField(
            label: 'Hero Image/GIF (Optional)',
            subtitle: 'Upload high-quality image or animated GIF',
            icon: Icons.image_rounded,
            accent: const Color(0xFF6366F1),
            currentUrl: _imageUrl,
            uploadFolder: 'letters-images',
            fileType: FileType.image,
            onUploaded: (url) => setState(() => _imageUrl = url),
            previewBuilder: (url) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 60, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          LetterMediaField(
            label: 'Lottie Animation (Optional)',
            subtitle: 'Upload a .json Lottie animation file',
            icon: Icons.animation_rounded,
            accent: const Color(0xFF10B981),
            currentUrl: _animationUrl,
            uploadFolder: 'animations',
            fileType: FileType.custom,
            allowedExtensions: const ['json'],
            onUploaded: (url) => setState(() => _animationUrl = url),
          ),
        ],
      ),
    );
  }

  /// Text field + AI magic-fill button in a Row.
  Widget _aiRow({required Widget child, required String tooltip, required VoidCallback onTap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: child),
        const SizedBox(width: 8),
        _MagicFillButton(tooltip: tooltip, onTap: onTap),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AdminTokens.baseTint(isDark),
        border: Border(top: BorderSide(color: AdminTokens.divider(isDark))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: AdminSecondaryButton(label: 'Cancel', onTap: () => Navigator.pop(context))),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AdminPrimaryButton(
                label: _isEditing ? 'Save Changes' : 'Add Letter',
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small stateful button that shows a spinner while the AI translate call runs.
class _MagicFillButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onTap;
  const _MagicFillButton({required this.tooltip, required this.onTap});

  @override
  State<_MagicFillButton> createState() => _MagicFillButtonState();
}

class _MagicFillButtonState extends State<_MagicFillButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                widget.onTap();
                // Give the async call time to complete before clearing spinner.
                await Future.delayed(const Duration(milliseconds: 1200));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      icon: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_awesome_rounded, size: 20),
      tooltip: widget.tooltip,
    );
  }
}
