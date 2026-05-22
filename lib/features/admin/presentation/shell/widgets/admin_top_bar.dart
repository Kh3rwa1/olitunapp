import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/admin_command_palette.dart';

class AdminTopBar extends StatefulWidget {
  final bool isDark;
  const AdminTopBar({super.key, required this.isDark});

  @override
  State<AdminTopBar> createState() => _AdminTopBarState();
}

class _AdminTopBarState extends State<AdminTopBar> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    super.dispose();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isMeta = HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;
      if (isMeta && event.logicalKey == LogicalKeyboardKey.keyK) {
        _showCommandPalette(context);
        return true;
      }
    }
    return false;
  }

  void _showCommandPalette(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const AdminCommandPalette();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim1.value,
            sigmaY: 12 * anim1.value,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final crumbs = _crumbsFor(location);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminTokens.divider(widget.isDark))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dashboard_customize_rounded,
            size: 16,
            color: AdminTokens.textTertiary(widget.isDark),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AdminTokens.textMuted(widget.isDark),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              crumbs[i],
              style: AdminTokens.label(widget.isDark).copyWith(
                color: i == crumbs.length - 1
                    ? AdminTokens.textPrimary(widget.isDark)
                    : AdminTokens.textTertiary(widget.isDark),
                fontWeight: i == crumbs.length - 1
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
          
          // Center Command Launcher trigger
          const Spacer(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: GestureDetector(
              onTap: () => _showCommandPalette(context),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF0F1622) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTokens.border(widget.isDark)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 15,
                      color: AdminTokens.textMuted(widget.isDark),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search or type a command...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.5,
                        color: AdminTokens.textMuted(widget.isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        '⌘K',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AdminTokens.textSecondary(widget.isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),

          AdminTopBarChip(
            isDark: widget.isDark,
            icon: Icons.bolt_rounded,
            label: 'Live',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          AdminTopBarChip(
            isDark: widget.isDark,
            icon: Icons.person_outline_rounded,
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  List<String> _crumbsFor(String location) {
    if (location == '/admin' || location == '/admin/') return ['Dashboard'];
    final segments = location
        .replaceFirst('/admin/', '')
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    return ['Admin', ...segments.map(_titleize)];
  }

  String _titleize(String s) {
    final cleaned = s.replaceAll('-', ' ').replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map(
          (p) => p.isEmpty
              ? p
              : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class AdminTopBarChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Color? color;

  const AdminTopBarChip({
    super.key,
    required this.isDark,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AdminTokens.textSecondary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: isDark ? 0.14 : 0.1)
            : AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.28)
              : AdminTokens.border(isDark),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: AdminTokens.label(isDark).copyWith(
              color: tint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
