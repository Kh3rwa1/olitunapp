import assert from "node:assert/strict";
import test from "node:test";
import {
  parsePubspecVersion,
  parseChangelogLatestVersion,
  verifyReleaseVersion,
} from "../../scripts/verify_release_version.mjs";

test("Version Consistency: parsePubspecVersion extracts semver and monotonic build number", () => {
  const sample1 = "name: itun\nversion: 1.3.0+20\nenvironment:\n  sdk: ^3.9.0";
  const parsed1 = parsePubspecVersion(sample1);
  assert.equal(parsed1.semver, "1.3.0");
  assert.equal(parsed1.buildNumber, 20);

  const sample2 = "version: 2.0.1+105";
  const parsed2 = parsePubspecVersion(sample2);
  assert.equal(parsed2.semver, "2.0.1");
  assert.equal(parsed2.buildNumber, 105);

  assert.throws(() => parsePubspecVersion("version: invalid_semver"));
});

test("Version Consistency: parseChangelogLatestVersion extracts top release header", () => {
  const changelog = "# Changelog\n\n## [1.3.0] (2026-08-09)\n### Features\n- Hardening\n\n## [1.2.2] (2026-08-09)";
  const version = parseChangelogLatestVersion(changelog);
  assert.equal(version, "1.3.0");
});

test("Version Consistency: verifyReleaseVersion validates live repo metadata", () => {
  const result = verifyReleaseVersion();
  assert.equal(result.valid, true);
  assert.equal(result.errors.length, 0);
  assert.equal(result.semver, "1.3.0");
  assert.equal(result.buildNumber, 22);
});

test("Version Consistency: detect release tag drift", () => {
  const matchResult = verifyReleaseVersion({ targetTag: "v1.3.0" });
  assert.equal(matchResult.valid, true);

  const driftResult = verifyReleaseVersion({ targetTag: "v1.4.0" });
  assert.equal(driftResult.valid, false);
  assert.ok(driftResult.errors.some((e) => e.includes("Release tag")));
});
