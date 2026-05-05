import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Skip onboarding - go directly to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/');
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
