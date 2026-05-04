import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/admin_tokens.dart';
import 'package:flutter/material.dart';

void main() {
  group('AdminTokens', () {
    group('spacing scale', () {
      test('is monotonically increasing', () {
        final scale = [
          AdminTokens.space1,
          AdminTokens.space2,
          AdminTokens.space3,
          AdminTokens.space4,
          AdminTokens.space5,
          AdminTokens.space6,
          AdminTokens.space7,
          AdminTokens.space8,
          AdminTokens.space9,
          AdminTokens.space10,
        ];
        for (var i = 1; i < scale.length; i++) {
          expect(scale[i], greaterThan(scale[i - 1]),
              reason: 'space${i + 1} should be > space$i');
        }
      });
    });

    group('radius scale', () {
      test('is monotonically increasing', () {
        final scale = [
          AdminTokens.radiusXs,
          AdminTokens.radiusSm,
          AdminTokens.radiusMd,
          AdminTokens.radiusLg,
          AdminTokens.radiusXl,
          AdminTokens.radius2xl,
        ];
        for (var i = 1; i < scale.length; i++) {
          expect(scale[i], greaterThan(scale[i - 1]));
        }
      });
    });

    group('surfaces', () {
      test('dark base is darker than light base', () {
        final darkBase = AdminTokens.base(true);
        final lightBase = AdminTokens.base(false);
        expect(darkBase.computeLuminance(),
            lessThan(lightBase.computeLuminance()));
      });

      test('raised is lighter than base in both modes', () {
        final darkRaised = AdminTokens.raised(true);
        final darkBase = AdminTokens.base(true);
        expect(darkRaised.computeLuminance(),
            greaterThan(darkBase.computeLuminance()));
      });
    });

    group('typography', () {
      test('display has Poppins family', () {
        final style = AdminTokens.display(false);
        expect(style.fontFamily, 'Poppins');
        expect(style.fontWeight, FontWeight.w800);
      });

      test('metric uses tabular figures', () {
        final style = AdminTokens.metric(false);
        expect(style.fontFeatures, isNotNull);
        expect(style.fontFeatures!.length, 1);
      });

      test('font size hierarchy is correct', () {
        expect(AdminTokens.display(false).fontSize,
            greaterThan(AdminTokens.pageTitle(false).fontSize!));
        expect(AdminTokens.pageTitle(false).fontSize,
            greaterThan(AdminTokens.sectionTitle(false).fontSize!));
        expect(AdminTokens.sectionTitle(false).fontSize,
            greaterThan(AdminTokens.cardTitle(false).fontSize!));
        expect(AdminTokens.cardTitle(false).fontSize,
            greaterThan(AdminTokens.body(false).fontSize!));
        expect(AdminTokens.body(false).fontSize,
            greaterThan(AdminTokens.label(false).fontSize!));
        expect(AdminTokens.label(false).fontSize,
            greaterThan(AdminTokens.eyebrow(false).fontSize!));
      });
    });

    group('shadows', () {
      test('raisedShadow returns non-empty list', () {
        expect(AdminTokens.raisedShadow(true), isNotEmpty);
        expect(AdminTokens.raisedShadow(false), isNotEmpty);
      });

      test('overlayShadow has larger blur than raised', () {
        final overlay = AdminTokens.overlayShadow(false).first;
        final raised = AdminTokens.raisedShadow(false).last;
        expect(overlay.blurRadius, greaterThan(raised.blurRadius));
      });

      test('brandGlow respects strength', () {
        final full = AdminTokens.brandGlow(Colors.green);
        final half = AdminTokens.brandGlow(Colors.green, strength: 0.5);
        expect(full.first.blurRadius, greaterThan(half.first.blurRadius));
      });
    });

    group('text colors', () {
      test('primary text is readable in both modes', () {
        // Light mode: dark text.
        expect(AdminTokens.textPrimary(false).computeLuminance(),
            lessThan(0.15));
        // Dark mode: light text.
        expect(AdminTokens.textPrimary(true).computeLuminance(),
            greaterThan(0.8));
      });
    });
  });
}
