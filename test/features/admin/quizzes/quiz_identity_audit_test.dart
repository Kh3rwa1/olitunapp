// Read-only audit of bundled quiz content against the verified corpus.
//
// Reports: total questions, attributed canonical, explicit non-memory,
// unattributed, invalid IDs, aliases, tombstoned, both-ID, type mismatches.
// Blocks publication-shaped regressions: no unattributed MEMORY questions
// may exist in bundled content (auto-linking by text is forbidden —
// invalid items must be explicitly marked non-memory or hand-linked).

import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/domain/quiz_identity_validation.dart';
import 'package:itun/features/review/domain/review_corpus_identity.dart';
import 'package:itun/shared/quiz_engine/quiz_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled quiz identity audit', () async {
    final corpusMap = await ReviewCorpusIdentityMap.loadBundled();

    var total = 0;
    var attributed = 0;
    var explicitNonMemory = 0;
    final unattributed = <String>[];
    final invalid = <String>[];
    final aliases = <String>[];
    final tombstoned = <String>[];
    final bothIds = <String>[];
    final typeMismatches = <String>[];

    for (final quiz in QuizCatalog.defaultQuizzes) {
      for (var i = 0; i < quiz.questions.length; i++) {
        final question = quiz.questions[i];
        final label = '${quiz.id}#Q${i + 1}';
        total++;
        final v = validateQuestionIdentity(question, corpusMap: corpusMap);
        switch (v.status) {
          case QuizIdentityStatus.valid:
            attributed++;
            if (v.resolvedViaAlias) aliases.add(label);
            break;
          case QuizIdentityStatus.explicitNonMemory:
            explicitNonMemory++;
            break;
          case QuizIdentityStatus.missingAttribution:
            unattributed.add(label);
            break;
          case QuizIdentityStatus.bothIds:
            bothIds.add(label);
            break;
          case QuizIdentityStatus.tombstonedId:
            tombstoned.add(label);
            break;
          case QuizIdentityStatus.typeMismatch:
            typeMismatches.add(label);
            break;
          default:
            invalid.add('$label (${v.status.name})');
        }
      }
    }

    // ignore: avoid_print
    print(
      'QUIZ AUDIT total=$total attributed=$attributed '
      'nonMemory=$explicitNonMemory unattributed=${unattributed.length} '
      'invalid=${invalid.length} aliases=${aliases.length} '
      'tombstoned=${tombstoned.length} bothIds=${bothIds.length} '
      'typeMismatch=${typeMismatches.length}',
    );
    if (unattributed.isNotEmpty) {
      // ignore: avoid_print
      print('UNATTRIBUTED: $unattributed');
    }
    if (invalid.isNotEmpty) {
      // ignore: avoid_print
      print('INVALID: $invalid');
    }

    // Bundled content must never ship unattributed MEMORY questions:
    // link them by hand or mark explicitly non-memory.
    expect(unattributed, isEmpty, reason: 'Unattributed memory questions');
    expect(invalid, isEmpty);
    expect(bothIds, isEmpty);
    expect(tombstoned, isEmpty);
    expect(typeMismatches, isEmpty);
  });
}
