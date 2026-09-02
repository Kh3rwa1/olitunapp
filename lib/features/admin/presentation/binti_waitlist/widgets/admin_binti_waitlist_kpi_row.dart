part of '../admin_binti_waitlist_screen.dart';

// KPI summary row for the waitlist screen.
class _BintiWaitlistKpiRow extends StatelessWidget {
  final bool isDark;
  final bool isWide;
  final int total;
  final int newCount;
  final int contacted;
  final int converted;

  const _BintiWaitlistKpiRow({
    required this.isDark,
    required this.isWide,
    required this.total,
    required this.newCount,
    required this.contacted,
    required this.converted,
  });

  @override
  Widget build(BuildContext context) {
    final cardStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      fontFamily: 'Inter',
      color: isDark ? Colors.white : Colors.black87,
    );

    final cards = [
      _KpiItem(
        title: 'Total Bookings',
        value: total.toString(),
        icon: Icons.book_online_rounded,
        accentColor: Colors.blue,
      ),
      _KpiItem(
        title: 'New Requests',
        value: newCount.toString(),
        icon: Icons.fiber_new_rounded,
        accentColor: Colors.orange,
      ),
      _KpiItem(
        title: 'Contacted',
        value: contacted.toString(),
        icon: Icons.chat_bubble_outline_rounded,
        accentColor: Colors.purple,
      ),
      _KpiItem(
        title: 'Converted',
        value: converted.toString(),
        icon: Icons.check_circle_rounded,
        accentColor: Colors.green,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildKpiCard(isDark, c, cardStyle),
                ),
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards.map((c) => _buildKpiCard(isDark, c, cardStyle)).toList(),
    );
  }

  Widget _buildKpiCard(bool isDark, _KpiItem card, TextStyle cardStyle) {
    return AdminGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black54,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: card.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(card.icon, size: 16, color: card.accentColor),
              ),
            ],
          ),
          Text(card.value, style: cardStyle),
        ],
      ),
    );
  }
}

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });
}
