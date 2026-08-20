#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

export function parsePubspecVersion(pubspecContent) {
  const match = pubspecContent.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(\+([0-9]+))?/m);
  if (!match) {
    throw new Error("Could not find valid version in pubspec.yaml (expected format X.Y.Z or X.Y.Z+N)");
  }
  return {
    fullVersion: match[0].replace(/^version:\s*/, "").trim(),
    semver: match[1],
    buildNumber: match[3] ? parseInt(match[3], 10) : null,
  };
}

export function parseChangelogLatestVersion(changelogContent) {
  const match = changelogContent.match(/##\s*\[([0-9]+\.[0-9]+\.[0-9]+)\]/m);
  if (!match) {
    throw new Error("Could not find latest release version in CHANGELOG.md (expected format ## [X.Y.Z])");
  }
  return match[1];
}

export function verifyReleaseVersion({ pubspecPath = "pubspec.yaml", changelogPath = "CHANGELOG.md", targetTag = null } = {}) {
  const pubspecRaw = fs.readFileSync(pubspecPath, "utf8");
  const changelogRaw = fs.readFileSync(changelogPath, "utf8");

  const pubspec = parsePubspecVersion(pubspecRaw);
  const changelogVersion = parseChangelogLatestVersion(changelogRaw);

  const errors = [];

  if (pubspec.semver !== changelogVersion) {
    errors.push(`Version drift detected: pubspec.yaml semver is "${pubspec.semver}", but CHANGELOG.md latest release is "${changelogVersion}".`);
  }

  if (pubspec.buildNumber === null || isNaN(pubspec.buildNumber) || pubspec.buildNumber <= 0) {
    errors.push(`Invalid Android build number in pubspec.yaml: "${pubspec.buildNumber}". Expected positive integer.`);
  }

  if (targetTag) {
    const normalizedTag = targetTag.replace(/^olitun-v|^v/, "");
    if (normalizedTag !== pubspec.semver) {
      errors.push(`Release tag "${targetTag}" does not match pubspec.yaml version "${pubspec.semver}".`);
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    semver: pubspec.semver,
    buildNumber: pubspec.buildNumber,
    changelogVersion,
  };
}

// CLI execution
if (process.argv[1] && import.meta.url.endsWith(path.basename(process.argv[1]))) {
  const targetTagArgIndex = process.argv.indexOf("--target-tag");
  const targetTag = targetTagArgIndex !== -1 ? process.argv[targetTagArgIndex + 1] : process.env.GITHUB_REF_NAME;

  try {
    const result = verifyReleaseVersion({ targetTag });
    if (!result.valid) {
      console.error("❌ Release version verification failed:\n" + result.errors.map(e => "  - " + e).join("\n"));
      process.exit(1);
    }
    console.log(`✅ Release version consistent: ${result.semver} (Build ${result.buildNumber}) matches CHANGELOG.md`);
  } catch (err) {
    console.error("❌ Version check error: " + err.message);
    process.exit(1);
  }
}
