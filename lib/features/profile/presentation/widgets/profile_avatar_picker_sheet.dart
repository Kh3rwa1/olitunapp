import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/profile_avatar.dart';
import '../providers/profile_account_providers.dart';

/// Stateful bottom-sheet body for choosing a real bundled animation or a name
/// initial. Selection state lives for the sheet's whole lifetime and every
/// accepted change is persisted through [onChanged].
class ProfileAvatarPickerSheet extends ConsumerStatefulWidget {
  const ProfileAvatarPickerSheet({
    super.key,
    required this.initialAvatarId,
    required this.initialColorIndex,
    required this.onChanged,
    this.avatarsForTesting,
  });

  final String initialAvatarId;
  final int initialColorIndex;
  final Future<void> Function(String avatarId, int colorIndex) onChanged;

  /// Deterministic catalog override for widget tests. Production always reads
  /// Flutter's real AssetManifest through [availableAvatarsProvider].
  final List<ProfileAvatar>? avatarsForTesting;

  @override
  ConsumerState<ProfileAvatarPickerSheet> createState() =>
      _ProfileAvatarPickerSheetState();
}

class _ProfileAvatarPickerSheetState
    extends ConsumerState<ProfileAvatarPickerSheet> {
  late String _selectedAvatarId;
  late int _selectedColorIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = normalizeAvatarId(widget.initialAvatarId);
    _selectedColorIndex = widget.initialColorIndex.clamp(
      0,
      AppColors.avatarPalettes.length - 1,
    );
  }

  Future<void> _persist({String? avatarId, int? colorIndex}) async {
    if (_isSaving) return;

    final nextAvatarId = normalizeAvatarId(avatarId ?? _selectedAvatarId);
    final nextColorIndex = (colorIndex ?? _selectedColorIndex).clamp(
      0,
      AppColors.avatarPalettes.length - 1,
    );
    if (nextAvatarId == _selectedAvatarId &&
        nextColorIndex == _selectedColorIndex) {
      return;
    }

    final previousAvatarId = _selectedAvatarId;
    final previousColorIndex = _selectedColorIndex;
    setState(() {
      _selectedAvatarId = nextAvatarId;
      _selectedColorIndex = nextColorIndex;
      _isSaving = true;
    });

    try {
      await widget.onChanged(nextAvatarId, nextColorIndex);
      await HapticFeedback.selectionClick();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedAvatarId = previousAvatarId;
        _selectedColorIndex = previousColorIndex;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save avatar. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final avatarsAsync = widget.avatarsForTesting == null
        ? ref.watch(availableAvatarsProvider)
        : AsyncValue.data(widget.avatarsForTesting!);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose your avatar',
                      style: AppTypography.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  if (_isSaving)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              _SectionLabel(label: 'Background color', isDark: isDark),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: List.generate(AppColors.avatarPalettes.length, (i) {
                  final selected = i == _selectedColorIndex;
                  return Semantics(
                    label: 'Avatar background ${i + 1}',
                    button: true,
                    selected: selected,
                    child: Tooltip(
                      message: 'Background ${i + 1}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkResponse(
                          key: ValueKey('avatar-color-$i'),
                          onTap: _isSaving
                              ? null
                              : () => _persist(colorIndex: i),
                          radius: 24,
                          child: AnimatedContainer(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: AppColors.avatarPalettes[i],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.avatarPalettes[i][0]
                                            .withValues(alpha: 0.38),
                                        blurRadius: 9,
                                      ),
                                    ]
                                  : const [],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: 'Avatar style', isDark: isDark),
              const SizedBox(height: 10),
              avatarsAsync.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => _AvatarLoadError(
                  onRetry: () => ref.invalidate(availableAvatarsProvider),
                ),
                data: (avatars) => LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 520 ? 4 : 3;
                    final options = <Widget>[
                      _AvatarOption(
                        key: const ValueKey(
                          'avatar-option-$kInitialAvatarId',
                        ),
                        label: 'Name initial',
                        selected: usesProfileInitial(_selectedAvatarId),
                        enabled: !_isSaving,
                        isDark: isDark,
                        onTap: () => _persist(avatarId: kInitialAvatarId),
                        child: Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      ...avatars.map((avatar) {
                        final selected = avatar.id == _selectedAvatarId;
                        return _AvatarOption(
                          key: ValueKey('avatar-option-${avatar.id}'),
                          label: avatar.label,
                          selected: selected,
                          enabled: !_isSaving,
                          isDark: isDark,
                          onTap: () => _persist(avatarId: avatar.id),
                          child: RepaintBoundary(
                            child: Lottie.asset(
                              avatar.assetPath,
                              width: 68,
                              height: 68,
                              fit: BoxFit.contain,
                              animate: !reduceMotion && selected,
                              repeat: !reduceMotion && selected,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.person_rounded,
                                size: 42,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }),
                    ];
                    return GridView.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.88,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: options,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: Text(_isSaving ? 'Saving…' : 'Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: AppTypography.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white60 : Colors.black54,
      ),
    ),
  );
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.isDark,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label avatar',
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: selected ? 0.09 : 0.05)
                  : Colors.black.withValues(alpha: selected ? 0.06 : 0.035),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : (isDark ? Colors.white12 : Colors.black12),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Center(child: ExcludeSemantics(child: child))),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarLoadError extends StatelessWidget {
  const _AvatarLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        const Text('Could not load avatar animations.'),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}
