import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/app_experience_scope.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

void main() {
  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets('preserves the OS text scaler at ${scale}x', (tester) async {
      final scaler = TextScaler.linear(scale);
      MediaQueryData? observed;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [reduceVisualEffectsProvider.overrideWithValue(false)],
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: scaler, boldText: true),
              child: AppExperienceScope(
                child: Builder(
                  builder: (context) {
                    observed = MediaQuery.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(identical(observed!.textScaler, scaler), isTrue);
      expect(observed!.textScaler.scale(20), 20 * scale);
      expect(observed!.boldText, isTrue);
    });
  }

  for (final system in [false, true]) {
    for (final preference in [false, true]) {
      testWidgets('motion respects OS=$system and user=$preference', (
        tester,
      ) async {
        bool? observed;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              reduceVisualEffectsProvider.overrideWithValue(preference),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(disableAnimations: system),
                child: AppExperienceScope(
                  child: Builder(
                    builder: (context) {
                      observed = MediaQuery.disableAnimationsOf(context);
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        expect(observed, system || preference);
      });
    }
  }
}
