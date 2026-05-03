import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'motion_tokens.dart';

/// Page-transition helpers for GoRouter. Replaces hard cuts with the
/// Material 3 "shared axis" / "fade through" patterns so navigation
/// reads as a continuous spatial flow.
class AppPageTransitions {
  AppPageTransitions._();

  /// Forward shared-axis Z transition: outgoing scales down + fades
  /// out, incoming scales up + fades in. Default for detail routes
  /// (lesson, letter, word, number, sentence, quiz).
  static CustomTransitionPage<T> sharedAxisZ<T>({
    required LocalKey? key,
    required Widget child,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: MotionTokens.medium,
      reverseTransitionDuration: MotionTokens.short,
      transitionsBuilder: (context, animation, secondary, child) {
        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.3, 1.0, curve: MotionTokens.emphasized),
        );
        final scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: MotionTokens.emphasized),
        );
        final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: secondary,
            curve: const Interval(0.0, 0.4, curve: MotionTokens.standard),
          ),
        );
        final scaleOut = Tween<double>(begin: 1.0, end: 1.06).animate(
          CurvedAnimation(parent: secondary, curve: MotionTokens.standard),
        );
        return FadeTransition(
          opacity: fadeOut,
          child: ScaleTransition(
            scale: scaleOut,
            child: FadeTransition(
              opacity: fadeIn,
              child: ScaleTransition(scale: scaleIn, child: child),
            ),
          ),
        );
      },
    );
  }

  /// Fade-through: outgoing fades out fully before incoming fades in.
  /// Best for lateral / peer navigations like switching tabs or top
  /// shell routes.
  static CustomTransitionPage<T> fadeThrough<T>({
    required LocalKey? key,
    required Widget child,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: MotionTokens.medium,
      reverseTransitionDuration: MotionTokens.short,
      transitionsBuilder: (context, animation, secondary, child) {
        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1.0, curve: MotionTokens.standard),
        );
        final fadeOut = CurvedAnimation(
          parent: secondary,
          curve: const Interval(0.0, 0.35, curve: MotionTokens.standard),
        );
        return FadeTransition(
          opacity: ReverseAnimation(fadeOut),
          child: FadeTransition(opacity: fadeIn, child: child),
        );
      },
    );
  }

  /// Modal-style fade-up: incoming slides up slightly while fading in.
  /// Use for translator, login, modal-feeling routes.
  static CustomTransitionPage<T> fadeUp<T>({
    required LocalKey? key,
    required Widget child,
    Object? arguments,
    String? restorationId,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      arguments: arguments,
      restorationId: restorationId,
      transitionDuration: MotionTokens.medium,
      reverseTransitionDuration: MotionTokens.short,
      transitionsBuilder: (context, animation, secondary, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: MotionTokens.emphasized),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}
