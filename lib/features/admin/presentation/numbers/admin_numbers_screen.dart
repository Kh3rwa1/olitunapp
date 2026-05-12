import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/models/content_models.dart';
import '../widgets/admin_empty_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/admin_form_widgets.dart';
import 'widgets/number_form_sheet.dart';
import 'widgets/number_grid.dart';

class AdminNumbersScreen extends ConsumerWidget {
  const AdminNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbersAsync = ref.watch(numbersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: AdminTokens.base(isDark)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(isWideScreen ? 32 : 20),
                  child: _buildHeader(context, isDark, isWideScreen),
                ),
                Expanded(
                  child: numbersAsync.when(
                    data: (numbers) => numbers.isEmpty
                        ? _emptyState(context, ref, isDark)
                        : NumberGrid(
                            numbers: numbers,
                            isDark: isDark,
                            isWideScreen: isWideScreen,
                            onEdit: (n) =>
                                NumberFormSheet.show(context, ref, n),
                            onDelete: (n) => _confirmDelete(context, ref, n),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: SelectableText(
                        'Error loading numbers: $error',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => NumberFormSheet.show(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Number',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool isWideScreen) {
    return Row(
      children: [
        if (!isWideScreen) ...[
          GestureDetector(
            onTap: () => context.go('/admin'),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminTokens.sunken(isDark),
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                border: Border.all(color: AdminTokens.border(isDark)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AdminTokens.textPrimary(isDark),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        const Expanded(
          child: AdminPageHeader(
            title: 'Ol Chiki Numbers',
            subtitle: 'Manage numerals and counting',
            eyebrow: 'CONTENT · NUMBERS',
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }

  Widget _emptyState(BuildContext context, WidgetRef ref, bool isDark) {
    return AdminEmptyState(
      glyph: '᱑',
      icon: Icons.pin_rounded,
      title: 'No numbers yet',
      message: 'Add Ol Chiki numerals to teach counting.',
      actionLabel: 'Add Number',
      onAction: () => NumberFormSheet.show(context, ref, null),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    NumberModel number,
  ) async {
    final ok = await showAdminConfirmDialog(
      context: context,
      title: 'Delete Number',
      message:
          'Are you sure you want to delete "${number.numeral}" (${number.nameLatin})? This action cannot be undone.',
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      ref.read(numbersProvider.notifier).deleteNumber(number.id);
    }
  }
}
