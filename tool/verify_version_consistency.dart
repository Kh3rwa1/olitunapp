import 'dart:io';

void main() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('❌ Error: pubspec.yaml not found');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(\+[0-9]+)?',
    multiLine: true,
  ).firstMatch(pubspecContent);
  if (versionMatch == null) {
    stderr.writeln('❌ Error: Could not parse version from pubspec.yaml');
    exit(1);
  }

  final pubspecVersion = versionMatch.group(1)!;
  stdout.writeln('📦 Source of truth (pubspec.yaml): $pubspecVersion');

  // 1. Verify CHANGELOG.md
  final changelogFile = File('CHANGELOG.md');
  if (changelogFile.existsSync()) {
    final changelogContent = changelogFile.readAsStringSync();
    final changelogMatch = RegExp(
      r'##\s*\[([0-9]+\.[0-9]+\.[0-9]+)\]',
    ).firstMatch(changelogContent);
    if (changelogMatch != null) {
      final changelogVersion = changelogMatch.group(1)!;
      stdout.writeln('📄 CHANGELOG.md version: $changelogVersion');
      if (pubspecVersion != changelogVersion) {
        stderr.writeln(
          '❌ Version Mismatch! pubspec.yaml ($pubspecVersion) != CHANGELOG.md ($changelogVersion)',
        );
        exit(1);
      }
    }
  }

  // 2. Verify .release-please-manifest.json
  final manifestFile = File('.release-please-manifest.json');
  if (manifestFile.existsSync()) {
    final manifestContent = manifestFile.readAsStringSync();
    final manifestMatch = RegExp(
      r'"\."\s*:\s*"([0-9]+\.[0-9]+\.[0-9]+)"',
    ).firstMatch(manifestContent);
    if (manifestMatch != null) {
      final manifestVersion = manifestMatch.group(1)!;
      stdout.writeln('🏷️ Release Please Manifest version: $manifestVersion');
      if (pubspecVersion != manifestVersion) {
        stderr.writeln(
          '❌ Version Mismatch! pubspec.yaml ($pubspecVersion) != .release-please-manifest.json ($manifestVersion)',
        );
        exit(1);
      }
    }
  }

  // 3. Verify TAG if running on a tag trigger in CI
  final gitTag =
      Platform.environment['GITHUB_REF_NAME'] ??
      Platform.environment['TAG_NAME'];
  if (gitTag != null &&
      (gitTag.startsWith('olitun-v') || gitTag.startsWith('v'))) {
    final cleanTag = gitTag.startsWith('olitun-v')
        ? gitTag.substring('olitun-v'.length)
        : gitTag.substring(1);
    final tagVersion = cleanTag.split('+').first;
    stdout.writeln('🔖 Git Tag version: $tagVersion');
    if (pubspecVersion != tagVersion) {
      stderr.writeln(
        '❌ Version Mismatch! pubspec.yaml ($pubspecVersion) != Git Tag ($tagVersion)',
      );
      exit(1);
    }
  }

  stdout.writeln('✅ Version consistency verification passed successfully!');
}
