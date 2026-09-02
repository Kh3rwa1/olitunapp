import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

bool get _isTesting {
  try {
    final binding = WidgetsBinding.instance.runtimeType.toString();
    if (binding.contains('Test') || binding.contains('Integration')) {
      return true;
    }
  } catch (_) {}
  if (!kIsWeb) {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    } catch (_) {}
  }
  return false;
}

class QuizCompleteTrophy extends StatelessWidget {
  const QuizCompleteTrophy({
    super.key,
    required this.isPassing,
    required this.reduceEffects,
  });

  final bool isPassing;
  final bool reduceEffects;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Builder(
        builder: (context) {
          final trophy = Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              gradient: isPassing
                  ? AppColors.premiumGreen
                  : AppColors.premiumOrange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (isPassing
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              isPassing ? Icons.emoji_events_rounded : Icons.refresh_rounded,
              size: 64,
              color: Colors.white,
            ),
          );

          if (_isTesting || reduceEffects) {
            return trophy;
          }

          return trophy
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.06, 1.06),
                duration: 1200.ms,
                curve: Curves.easeInOutSine,
              );
        },
      ),
    );
  }
}
