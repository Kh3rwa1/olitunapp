# CI Failure Root Cause Analysis: Commit `0beed0dfb53e19d71a3e3b10ba93a7318336347b`

## 1. Overview & Failure Metadata

- **Workflow Run:** https://github.com/Kh3rwa1/olitunapp/actions/runs/32361358001
- **Failed Job URL:** https://github.com/Kh3rwa1/olitunapp/actions/runs/32361358001/job/96401418322
- **Job Name:** `Web Application Integration Tests (Chrome)`
- **Runner:** `ubuntu-latest`
- **Failing Step:** `Launch Chromedriver and Run Web Journeys`
- **Failing Command:**
  ```bash
  $CHROMEWEBDRIVER/chromedriver --port=4444 &
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/all_tests.dart \
    -d web-server \
    --browser-name=chrome \
    --headless
  ```

---

## 2. First Relevant Error & Stack Trace

```text
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "You
scored 2 out of 2": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
dart-sdk/lib/_internal/js_dev_runtime/private/ddc_runtime/errors.dart 274:3       throw_
package:matcher/src/expect/expect.dart 187:31                                     fail
package:matcher/src/expect/expect.dart 182:3                                      _expect
package:matcher/src/expect/expect.dart 65:3                                       expect$
package:flutter_test/src/widget_tester.dart 473:18                                expect$
quiz_flow_test.dart 108:5                                                         <fn>
```

---

## 3. Root Cause Analysis

1. **Option Finder Ambiguity in `quiz_flow_test.dart`:**
   - In `integration_test/quiz_flow_test.dart`, question 1 and question 2 used `find.text('O').last` and `find.text('T').last`.
   - The string `'T'` was present in both `QuizQuestionCard` (the prompt) and `QuizOptionTile` (the option).
   - In Flutter web headless rendering, the widget tree traversal order resulted in tapping an unclickable or non-option element, causing the second question selection to not register before the "Continue" action was pressed.
   - Consequently, the quiz was not marked with 2/2 score, and the specific localized score string was not matched.

2. **Why Earlier Attempts Failed:**
   - Earlier PR runs attempted modifying animation durations and settled pumps without resolving the fundamental finder ambiguity in `quiz_flow_test.dart`.
   - Furthermore, `QuizCompleteScreen` contained an infinite pulse animation on the trophy icon that prevented `pumpAndSettle()` from settling when test environment detection failed on web (`kIsWeb == true`).

---

## 4. Selected Fix

1. Target `QuizOptionTile` explicitly by type and index (`find.byType(QuizOptionTile).at(index)`) rather than fuzzy text matches (`find.text(...).last`).
2. Verify completion using unambiguous completion indicators: `QuizCompleteScreen`, `'100%'`, `'2 / 2'`, and star rewards.
3. Ensure `_isTesting` in `QuizCompleteScreen` detects `WidgetsBinding` test harnesses across both web and native environments so animations do not run indefinitely during testing.

---

## 5. Local Reproduction Command

```bash
flutter test test/features/quiz/quiz_screen_test.dart
```
