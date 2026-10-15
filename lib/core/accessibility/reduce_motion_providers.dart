import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/widgets.dart'
    show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_service.dart';

/// Reduce-motion / reduced-visual-effects preference: the user's explicit
/// toggle (persisted in SharedPreferences) OR'd with the OS accessibility
/// "disable animations" flag.

final userReduceVisualEffectsProvider = StateProvider<bool>((ref) {
  return ref.read(sharedPreferencesProvider).getBool('reduce_visual_effects') ??
      false;
});

class SystemReduceMotionNotifier extends Notifier<bool>
    with WidgetsBindingObserver {
  bool _observing = false;

  void _updateState() {
    try {
      state =
          PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;
    } catch (_) {
      // Accessibility features may be unreadable before binding init or in
      // tests; treating it as "no reduce-motion" is the safe default.
      state = false;
    }
  }

  @override
  bool build() {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    });
    _updateState();
    return state;
  }

  @override
  void didChangeAccessibilityFeatures() {
    _updateState();
  }
}

final systemReduceMotionProvider =
    NotifierProvider<SystemReduceMotionNotifier, bool>(
      SystemReduceMotionNotifier.new,
    );

final reduceVisualEffectsProvider = Provider<bool>((ref) {
  final userPref = ref.watch(userReduceVisualEffectsProvider);
  final systemPref = ref.watch(systemReduceMotionProvider);
  return userPref || systemPref;
});

void toggleReduceVisualEffects(WidgetRef ref) {
  final current = ref.read(userReduceVisualEffectsProvider);
  ref
      .read(sharedPreferencesProvider)
      .setBool('reduce_visual_effects', !current);
  ref.read(userReduceVisualEffectsProvider.notifier).state = !current;
}
