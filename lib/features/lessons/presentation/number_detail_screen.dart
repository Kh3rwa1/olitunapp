import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/presentation/animations/scale_button.dart';

class NumberDetailScreen extends ConsumerStatefulWidget {
  final String numberId;
  final String lessonId;

  const NumberDetailScreen({
    super.key,
    required this.numberId,
    required this.lessonId,
  });

  @override
  ConsumerState<NumberDetailScreen> createState() => _NumberDetailScreenState();
}

class _NumberDetailScreenState extends ConsumerState<NumberDetailScreen> {
  int _currentIndex = 0;
  static const double _swipeVelocityThreshold = 380;

  // Ol Chiki numbers data with values and names
  final Map<String, List<Map<String, dynamic>>> lessonNumbers = {
    'numbers_1': [
      {
        'num': '᱑',
        'value': '1',
        'name': 'Mit',
        'emoji': '☝️',
        'color': const Color(0xFFE3F2FD),
        'accentColor': const Color(0xFF2196F3),
      },
      {
        'num': '᱒',
        'value': '2',
        'name': 'Bar',
        'emoji': '✌️',
        'color': const Color(0xFFE8F5E9),
        'accentColor': const Color(0xFF4CAF50),
      },
      {
        'num': '᱓',
        'value': '3',
        'name': 'Pe',
        'emoji': '🤟',
        'color': const Color(0xFFFFF8E1),
        'accentColor': const Color(0xFFFFC107),
      },
      {
        'num': '᱔',
        'value': '4',
        'name': 'Pon',
        'emoji': '🍀',
        'color': const Color(0xFFF3E5F5),
        'accentColor': AppColors.duoBlue,
      },
      {
        'num': '᱕',
        'value': '5',
        'name': 'Mone',
        'emoji': '🖐️',
        'color': const Color(0xFFFCE4EC),
        'accentColor': const Color(0xFFE91E63),
      },
    ],
    'numbers_2': [
      {
        'num': '᱖',
        'value': '6',
        'name': 'Turui',
        'emoji': '🎲',
        'color': const Color(0xFFE0F7FA),
        'accentColor': const Color(0xFF00BCD4),
      },
      {
        'num': '᱗',
        'value': '7',
        'name': 'Eae',
        'emoji': '🌈',
        'color': const Color(0xFFFAFAFA),
        'accentColor': const Color(0xFF607D8B),
      },
      {
        'num': '᱘',
        'value': '8',
        'name': 'Irel',
        'emoji': '🎱',
        'color': const Color(0xFFECEFF1),
        'accentColor': const Color(0xFF455A64),
      },
      {
        'num': '᱙',
        'value': '9',
        'name': 'Are',
        'emoji': '🕘',
        'color': const Color(0xFFFFF3E0),
        'accentColor': const Color(0xFFFF5722),
      },
      {
        'num': '᱑᱐',
        'value': '10',
        'name': 'Gel',
        'emoji': '🔟',
        'color': const Color(0xFFFFEBEE),
        'accentColor': const Color(0xFFF44336),
      },
    ],
  };

  List<Map<String, dynamic>> get numbers =>
      lessonNumbers[widget.lessonId] ?? lessonNumbers['numbers_1']!;

  @override
  void initState() {
    super.initState();
    // Find initial index based on numberId or value
    final index = numbers.indexWhere(
      (n) => n['num'] == widget.numberId || n['value'] == widget.numberId,
    );
    _currentIndex = index >= 0 ? index : 0;
  }

  void _goToNumber(int index) {
    if (index >= 0 && index < numbers.length) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  void _goToNextNumber() {
    if (_currentIndex < numbers.length - 1) {
      _goToNumber(_currentIndex + 1);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _goToPreviousNumber() {
    if (_currentIndex > 0) {
      _goToNumber(_currentIndex - 1);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _swipeVelocityThreshold) return;

    if (velocity < 0) {
      _goToNextNumber();
      return;
    }

    _goToPreviousNumber();
  }

  @override
  Widget build(BuildContext context) {
    final number = numbers[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : number['color'],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ScaleButton(
            onPressed: () => context.go('/lesson/${widget.lessonId}'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: number['accentColor'],
              ),
            ),
          ),
        ),
        actions: [
          // Audio button
          // Audio button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ScaleButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                // TODO: Play audio
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: number['accentColor'],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _handleSwipe,
        child: SafeArea(
          child: Column(
          children: [
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(_currentIndex),
                    children: [
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: number['accentColor'].withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swipe_rounded,
                              size: 18,
                              color: number['accentColor'],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Swipe left / right to change',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Hero illustration card
                      Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: number['accentColor'].withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Big emoji illustration
                          Text(
                            number['emoji'],
                            style: const TextStyle(fontSize: 100),
                          ),
                          const SizedBox(height: 24),

                          // Number name
                          Text(
                            number['name'],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: number['accentColor'],
                            ),
                          ),
                          Text(
                            'Number ${number['value']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      ),
                      const SizedBox(height: 32),

                    // Large Ol Chiki number
                      Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            number['accentColor'].withOpacity(0.1),
                            number['accentColor'].withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: number['accentColor'].withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          number['num'],
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: number['accentColor'],
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(height: 24),

                    // Value representation (dots)
                      Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(
                          int.parse(number['value']),
                          (index) => Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: number['accentColor'],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: ScaleButton(
                              onPressed: _goToPreviousNumber,
                              child: _buildNavButton(
                                label: 'Previous',
                                icon: Icons.chevron_left_rounded,
                                accentColor: number['accentColor'],
                                enabled: _currentIndex > 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ScaleButton(
                              onPressed: _goToNextNumber,
                              child: _buildNavButton(
                                label: 'Next',
                                icon: Icons.chevron_right_rounded,
                                accentColor: number['accentColor'],
                                enabled: _currentIndex < numbers.length - 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom pagination
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(numbers.length, (index) {
                  final isActive = index == _currentIndex;
                  return ScaleButton(
                    onPressed: () => _goToNumber(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: isActive ? 44 : 36,
                      height: isActive ? 44 : 36,
                      decoration: BoxDecoration(
                        color: isActive
                            ? number['accentColor']
                            : (isDark ? Colors.white10 : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(isActive ? 14 : 12),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: number['accentColor'].withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          numbers[index]['value'],
                          style: TextStyle(
                            fontSize: isActive ? 18 : 14,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required Color accentColor,
    required bool enabled,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(enabled ? 0.4 : 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: enabled ? accentColor : Colors.grey[400]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: enabled ? accentColor : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
