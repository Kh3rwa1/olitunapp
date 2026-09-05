"""Bounded diagnostics for the experience PR; never commits or deploys code."""
import json
import os
from pathlib import Path
import subprocess

DART_FILES = [
    "lib/core/accessibility/app_experience_scope.dart",
    "lib/core/motion/pressable_scale.dart",
    "lib/shared/widgets/bento_grid.dart",
    "lib/shared/widgets/buttons/pressable_button.dart",
    "lib/features/lessons/presentation/lessons_screen.dart",
    "lib/features/lessons/presentation/widgets/bento_category_card.dart",
    "lib/features/lessons/presentation/widgets/hero_category_card.dart",
    "lib/main.dart",
    "test/core/accessibility/app_experience_scope_test.dart",
    "test/core/motion/pressable_scale_accessibility_test.dart",
    "test/shared/widgets/experience_controls_test.dart",
    "test/features/lessons/lessons_experience_test.dart",
    "integration_test/experience_performance_test.dart",
]
TEST_FILES = [path for path in DART_FILES if path.startswith("test/")]


def run(command, timeout=180):
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
        return result.returncode, result.stdout + result.stderr
    except subprocess.TimeoutExpired as error:
        partial = error.stdout or ""
        if isinstance(partial, bytes):
            partial = partial.decode("utf-8", errors="replace")
        return 124, partial + "\nCommand timed out; this check did not pass."


def clip(text, limit):
    return text if len(text) <= limit else text[:limit] + "\n[truncated; see CI logs]"


def main():
    output = Path("build/experience-diagnostics")
    output.mkdir(parents=True, exist_ok=True)
    format_code, format_log = run(["dart", "format", *DART_FILES])
    _, patch = run(["git", "diff", "--", *DART_FILES])
    format_ok = format_code == 0 and not patch
    analyze_code, analyze_log = run(["flutter", "analyze", "--no-pub", "--fatal-infos"])
    test_code, test_log = run(["flutter", "test", "--no-pub", "--machine", *TEST_FILES], timeout=240)
    errors = []
    names = {}
    messages = {}
    for line in test_log.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(event, dict):
            continue
        if event.get("type") == "testStart":
            names[event["test"]["id"]] = event["test"]["name"]
        elif event.get("type") == "print":
            messages.setdefault(event.get("testID"), []).append(str(event.get("message", "")))
        elif event.get("type") == "error":
            errors.append(event)
    details = []
    for error in errors:
        test_id = error.get("testID")
        detail = "\n".join(messages.get(test_id, []))
        detail += "\n" + str(error.get("error", "")) + "\n" + str(error.get("stackTrace", ""))
        details.append(names.get(test_id, "Test error") + "\n" + clip(detail, 2800))
    test_detail = "Selected Flutter tests passed." if test_code == 0 else "\n\n".join(details) or test_log
    head = os.environ.get("TESTED_HEAD", "unrecorded")
    body = (
        f"<!-- experience-diagnostics:{head} -->\n"
        f"## Experience diagnostics — `{head[:12]}`\n\n"
        "Formatting happens only in the disposable CI checkout. No source is auto-committed. "
        "These checks do not replace visual/device evaluation or the existing release gates.\n\n"
        f"### Formatting: {'passed' if format_ok else 'needs correction'}\n"
        f"```diff\n{clip(patch or format_log, 28000)}\n```\n\n"
        f"### Analyzer: {'passed' if analyze_code == 0 else 'failed'}\n"
        f"```text\n{clip(analyze_log, 7000)}\n```\n\n"
        f"### Targeted Flutter tests: {'passed' if test_code == 0 else 'failed'}\n"
        f"```text\n{clip(test_detail, 18000)}\n```\n"
    )
    (output / "comment.json").write_text(json.dumps({"body": body}), encoding="utf-8")
    (output / "format.patch").write_text(patch, encoding="utf-8")
    (output / "analyze.log").write_text(analyze_log, encoding="utf-8")
    (output / "tests.jsonl").write_text(test_log, encoding="utf-8")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(body)
    return 0 if format_ok and analyze_code == 0 and test_code == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
