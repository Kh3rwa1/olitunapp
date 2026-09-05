"""Bounded diagnostics for the experience PR; never commits or deploys code."""
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

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
    "test/core/accessibility/semantics_and_a11y_test.dart",
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


def outcome(code):
    return "passed" if code == 0 else "not run" if code is None else "failed"


def coverage_command():
    """Reuse the current CI coverage policy verbatim, without invoking a shell."""
    lines = Path(".github/workflows/flutter-ci.yml").read_text().splitlines()
    index = lines.index("      - name: Enforce coverage threshold")
    if lines[index + 1].strip() != "run: |":
        raise ValueError("Coverage policy is no longer a literal command; review it manually.")
    body = []
    for line in lines[index + 2:]:
        if not line.startswith("          "):
            break
        body.append(line[10:])
    command = shlex.split("\n".join(body).replace("\\\n", " "))
    if command[:3] != ["dart", "run", "tool/enforce_coverage.dart"]:
        raise ValueError("Unexpected coverage command; refusing to substitute policy.")
    return command


def main(full=False):
    output = Path("build/experience-diagnostics")
    output.mkdir(parents=True, exist_ok=True)
    format_code, format_log = run(["dart", "format", *DART_FILES])
    _, patch = run(["git", "diff", "--", *DART_FILES])
    format_ok = format_code == 0 and not patch
    analyze_code, analyze_log = run(["flutter", "analyze", "--no-pub", "--fatal-infos"])
    test_command = ["flutter", "test", "--no-pub", "--machine"]
    test_command += ["--coverage", "--concurrency=4"] if full else TEST_FILES
    test_code, test_log = run(test_command, timeout=660 if full else 240)
    coverage_code = smoke_code = None
    coverage_log = smoke_log = "Not run because an earlier required stage did not pass."
    if full and test_code == 0:
        try:
            coverage_code, coverage_log = run(coverage_command())
        except (ValueError, OSError) as error:
            coverage_code, coverage_log = 2, str(error)
        if coverage_code == 0:
            smoke_code, smoke_log = run(["flutter", "test", "--no-pub", "test/smoke"])
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
    suite = "Full Flutter suite" if full else "Targeted Flutter tests"
    test_detail = f"{suite} passed." if test_code == 0 else "\n\n".join(details) or test_log
    head = os.environ.get("TESTED_HEAD", "unrecorded")
    body = (
        f"<!-- experience-diagnostics:{head} -->\n"
        f"## Experience diagnostics — `{head[:12]}`\n\n"
        "Formatting happens only in the disposable CI checkout. No source is auto-committed. "
        "These checks do not replace visual/device evaluation or the existing release gates.\n\n"
        f"### Formatting: {'passed' if format_ok else 'needs correction'}\n"
        f"```diff\n{clip(patch or format_log, 18000)}\n```\n\n"
        f"### Analyzer: {outcome(analyze_code)}\n"
        f"```text\n{clip(analyze_log, 5000)}\n```\n\n"
        f"### {suite}: {outcome(test_code)}\n"
        f"```text\n{clip(test_detail, 18000)}\n```\n"
    )
    if full:
        body += (
            f"\n### Coverage gate: {outcome(coverage_code)}\n"
            f"```text\n{clip(coverage_log, 4500)}\n```\n"
            f"\n### Smoke tests: {outcome(smoke_code)}\n"
            f"```text\n{clip(smoke_log, 3000)}\n```\n"
        )
    (output / "comment.json").write_text(json.dumps({"body": body}), encoding="utf-8")
    (output / "format.patch").write_text(patch, encoding="utf-8")
    (output / "analyze.log").write_text(analyze_log, encoding="utf-8")
    (output / "tests.jsonl").write_text(test_log, encoding="utf-8")
    (output / "coverage.log").write_text(coverage_log, encoding="utf-8")
    (output / "smoke.log").write_text(smoke_log, encoding="utf-8")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as handle:
            handle.write(body)
    passed = format_ok and analyze_code == 0 and test_code == 0
    if full:
        passed = passed and coverage_code == 0 and smoke_code == 0
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main(full="--full" in sys.argv))
