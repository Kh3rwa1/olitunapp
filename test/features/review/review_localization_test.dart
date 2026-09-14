// P4 regression guard: every review/notification key exists in all 5
// locales with matching placeholders, and the tap payload is stable.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/notifications/notification_service.dart';

const _locales = ['en', 'hi', 'bn', 'or', 'sat'];

const _keys = [
  'reviewToday',
  'reviewLoading',
  'reviewDueOne',
  'reviewDueOther',
  'reviewDueSubtitle',
  'reviewStart',
  'reviewCaughtUp',
  'reviewCaughtUpRetained',
  'reviewCaughtUpEmpty',
  'reviewContinueLearning',
  'reviewLearnNew',
  'reviewRetained',
  'reviewExit',
  'reviewSessionTitle',
  'reviewSessionTitleBare',
  'reviewComplete',
  'reviewCorrectFeedback',
  'reviewWrongFeedback',
  'reviewCorrectAnswer',
  'reviewHintTyping',
  'reviewHintListening',
  'reviewHintRecognition',
  'reviewRepromptListen',
  'reviewRepromptWrite',
  'reviewRepromptMeaning',
  'reviewPlayAudio',
  'reviewReplayAudio',
  'reviewCheck',
  'reviewFinish',
  'reviewBackHome',
  'reviewDone',
  'reviewCaughtUpShort',
  'reviewSummaryScore',
  'reviewSummaryMastered',
  'reviewSummaryRecovery',
  'reviewLoadError',
  'reviewLoadErrorBody',
  'notifReviewTitleOne',
  'notifReviewTitleOther',
  'notifReviewBodyOne',
  'notifReviewBodyOther',
  'notifStruggleTitle',
  'notifStruggleBodyOne',
  'notifStruggleBodyOther',
  'notifGentleTitle',
  'notifGentleBody',
];

Map<String, dynamic> _arb(String locale) {
  final file = File('lib/l10n/arb/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('review localization coverage', () {
    test('every review key exists in all 5 locales, non-empty', () {
      for (final locale in _locales) {
        final arb = _arb(locale);
        for (final key in _keys) {
          expect(
            arb[key],
            isNotNull,
            reason: '$key missing in app_$locale.arb',
          );
          expect(
            (arb[key] as String).trim().isNotEmpty,
            isTrue,
            reason: '$key empty in app_$locale.arb',
          );
        }
      }
    });

    test('placeholder parity across locales (no missing {count})', () {
      final en = _arb('en');
      final placeholderKeys = _keys.where((k) => en['@$k'] != null);
      for (final key in placeholderKeys) {
        final enPlaceholders = (en['@$key'] as Map)['placeholders'] as Map;
        for (final locale in _locales.skip(1)) {
          final arb = _arb(locale);
          expect(arb['@$key'], isNotNull, reason: '@$key missing in $locale');
          final placeholders = (arb['@$key'] as Map)['placeholders'] as Map;
          expect(
            placeholders.keys.toSet(),
            enPlaceholders.keys.toSet(),
            reason: 'placeholder mismatch for $key in $locale',
          );
          for (final name in enPlaceholders.keys) {
            expect(
              (arb[key] as String).contains('{$name}'),
              isTrue,
              reason: '{$name} missing in $key ($locale)',
            );
          }
        }
      }
    });
  });

  group('notification tap contract', () {
    test('review payload is stable and non-empty', () {
      expect(NotificationService.reviewNotificationPayload, 'review');
    });

    test('tap handler is installable and receives payloads', () {
      String? received;
      NotificationService.onNotificationTap = (payload) {
        received = payload;
      };
      NotificationService.onNotificationTap!(
        NotificationService.reviewNotificationPayload,
      );
      expect(received, 'review');
      NotificationService.onNotificationTap = null;
    });
  });
}
