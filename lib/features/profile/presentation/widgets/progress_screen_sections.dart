import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/waitlist_provider.dart';
import '../../../../shared/widgets/bento_grid.dart';

class ProgressErrorState extends StatelessWidget {
  const ProgressErrorState({
    super.key,
    required this.isDark,
    required this.onRetry,
  });

  final bool isDark;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Could not load progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved progress is still safe. Try refreshing this view.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "MY BINTI GURU BOOKINGS" section extracted from the profile screen.
class BintiGuruBookingsSection extends ConsumerWidget {
  const BintiGuruBookingsSection({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitlistAsync = ref.watch(userWaitlistProvider);

    return waitlistAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.01),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 40,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
                const SizedBox(height: 12),
                Text(
                  'No bookings found',
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Book verified reciters for your ceremonies under the Bakhed tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final booking = bookings[index];

            final ceremonyName = booking.ceremonyType.isNotEmpty
                ? booking.ceremonyType[0].toUpperCase() +
                      booking.ceremonyType.substring(1)
                : 'Other';

            Color statusColor;
            Color statusBgColor;
            switch (booking.status) {
              case 'new':
                statusColor = Colors.orangeAccent;
                statusBgColor = Colors.orangeAccent.withValues(alpha: 0.12);
                break;
              case 'contacted':
                statusColor = Colors.blueAccent;
                statusBgColor = Colors.blueAccent.withValues(alpha: 0.12);
                break;
              case 'converted':
                statusColor = Colors.greenAccent;
                statusBgColor = Colors.greenAccent.withValues(alpha: 0.12);
                break;
              case 'closed':
              default:
                statusColor = Colors.grey;
                statusBgColor = Colors.grey.withValues(alpha: 0.12);
                break;
            }

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ceremonyName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking.eventDate != null
                            ? booking.eventDate!.split('T')[0]
                            : 'No date specified',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${booking.city}, ${booking.state}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (booking.notes != null &&
                      booking.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.notes!,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Failed to load waitlist bookings.',
          style: TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}

/// "ACCOUNT" action tiles extracted from the profile screen.
class ActionTilesSection extends StatelessWidget {
  const ActionTilesSection({
    super.key,
    required this.isDark,
    required this.onEditName,
    required this.onShare,
  });

  final bool isDark;
  final VoidCallback onEditName;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        AnimatedBentoChild(
          index: 0,
          child: BentoActionCard(
            icon: Icons.edit_rounded,
            label: 'Edit Name',
            color: AppColors.brandBlue,
            isDark: isDark,
            onTap: onEditName,
          ),
        ),
        AnimatedBentoChild(
          index: 1,
          child: BentoActionCard(
            icon: Icons.share_rounded,
            label: 'Share',
            color: AppColors.primary,
            isDark: isDark,
            onTap: onShare,
          ),
        ),
        AnimatedBentoChild(
          index: 2,
          child: BentoActionCard(
            icon: Icons.settings_rounded,
            label: 'Settings',
            color: AppColors.accentOchre,
            isDark: isDark,
            onTap: () {
              context.push('/settings');
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════ BENTO ACTION CARD ═══════════════

class BentoActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const BentoActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCell(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(28),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
