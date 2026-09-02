import 'dart:io';

const criticalLearningPaths = [
  'lib/core/analytics/',
  'lib/shared/quiz_engine/',
  'lib/features/quiz/presentation/providers/quiz_session_notifier.dart',
  'lib/features/lessons/presentation/providers/lesson_notifier.dart',
  'lib/features/profile/domain/entities/',
  'lib/features/profile/data/models/',
  'lib/shared/providers/local_settings_provider.dart',
  'lib/features/home/presentation/widgets/next_best_action_card.dart',
  'lib/features/home/presentation/providers/mission_providers.dart',
];

/// Files/patterns exempt from the untested-files gate: generated code,
/// the app entrypoint, and pure static data tables that carry no logic.
const untestedExclusionPatterns = [
  'lib/main.dart',
  'lib/l10n/generated/',
  '.g.dart',
  '.freezed.dart',
  'lib/features/lessons/data/ol_chiki_strokes.dart',
  // Bundled Indic dictionary/translation data tables (no logic).
  'lib/core/languages/indic_translations',
  'lib/core/languages/ol_chiki_char_maps.dart',
];

void main(List<String> args) {
  final minimum = _doubleArg(args, '--min=', fallback: 65);
  final enforceAfter = _dateArg(args, '--enforce-after=');
  final pathMinimums = _pathMinimums(args);
  final untestedEnforceAfter = _dateArg(args, '--enforce-untested-after=');
  final allowInvisible = _stringArgs(args, '--allow-invisible=');
  final file = File('coverage/lcov.info');

  if (!file.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run flutter test --coverage.',
    );
    exit(1);
  }

  final files = _parseLcov(file);
  var failed = false;

  failed |= !_checkGroup(
    name: 'Critical learning',
    coverage: _coverageFor(
      files,
      (path) => criticalLearningPaths.any(path.contains),
    ),
    minimum: minimum,
    enforce: true,
  );

  final enforcePathMinimums =
      enforceAfter == null || !DateTime.now().toUtc().isBefore(enforceAfter);

  for (final minimum in pathMinimums) {
    failed |= !_checkGroup(
      name: minimum.label,
      coverage: _coverageFor(files, (path) => path.contains(minimum.pathMatch)),
      minimum: minimum.minimum,
      enforce: enforcePathMinimums,
      enforceAfter: enforceAfter,
    );
  }

  // The lcov denominator only contains files imported by at least one test;
  // never-imported files silently escape every threshold above. Surface them
  // explicitly so they cannot hide from the coverage gate. Structural files
  // (export-only barrels, pure-abstract repository interfaces, conditional
  // web stubs not selected on the VM) emit no lcov entry even when imported
  // by tests — exempt them via --allow-invisible=<path-substring>.
  failed |= !_checkUntestedFiles(
    untested: _findUntestedFiles(files, allowInvisible),
    enforce:
        untestedEnforceAfter != null &&
        !DateTime.now().toUtc().isBefore(untestedEnforceAfter),
    enforceAfter: untestedEnforceAfter,
  );

  if (failed) exit(1);
}

/// Parses every `--allow-invisible=<substring>` argument.
List<String> _stringArgs(List<String> args, String prefix) {
  return args
      .where((arg) => arg.startsWith(prefix))
      .map((arg) => arg.substring(prefix.length))
      .toList();
}

List<String> _findUntestedFiles(
  Map<String, _LineCoverage> files,
  List<String> allowInvisible,
) {
  final covered = files.keys.toSet();
  final untested = <String>[];

  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (untestedExclusionPatterns.any(path.contains)) continue;
    if (allowInvisible.any(path.contains)) continue;
    if (!covered.contains(path)) untested.add(path);
  }

  untested.sort();
  return untested;
}

bool _checkUntestedFiles({
  required List<String> untested,
  required bool enforce,
  DateTime? enforceAfter,
}) {
  if (untested.isEmpty) {
    stdout.writeln('Untested files: none (every lib/ file ran under test).');
    return true;
  }

  final status = enforce ? 'FAIL' : 'WARN';
  stdout.writeln(
    'Untested files: ${untested.length} lib/ file(s) were never imported by '
    'any test and are invisible to all coverage thresholds [$status]',
  );
  for (final path in untested.take(40)) {
    stderr.writeln('  untested: $path');
  }
  if (untested.length > 40) {
    stderr.writeln('  ... and ${untested.length - 40} more');
  }

  if (!enforce) {
    final date = enforceAfter == null ? 'later' : _dateKey(enforceAfter);
    stdout.writeln('Untested-files gate becomes blocking on $date.');
    return true;
  }

  stderr.writeln(
    '${untested.length} lib/ file(s) have no test coverage at all.',
  );
  return false;
}

Map<String, _LineCoverage> _parseLcov(File file) {
  final files = <String, _LineCoverage>{};
  var currentFile = '';

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      files.putIfAbsent(
        currentFile,
        () => const _LineCoverage(found: 0, hit: 0),
      );
      continue;
    }

    if (currentFile.isEmpty || !line.startsWith('DA:')) continue;

    final data = line.substring(3).split(',');
    if (data.length < 2) continue;
    final current = files[currentFile]!;
    final covered = (int.tryParse(data[1]) ?? 0) > 0 ? 1 : 0;
    files[currentFile] = _LineCoverage(
      found: current.found + 1,
      hit: current.hit + covered,
    );
  }

  return files;
}

_LineCoverage _coverageFor(
  Map<String, _LineCoverage> files,
  bool Function(String path) include,
) {
  var found = 0;
  var hit = 0;
  for (final entry in files.entries) {
    if (!include(entry.key)) continue;
    found += entry.value.found;
    hit += entry.value.hit;
  }
  return _LineCoverage(found: found, hit: hit);
}

bool _checkGroup({
  required String name,
  required _LineCoverage coverage,
  required double minimum,
  required bool enforce,
  DateTime? enforceAfter,
}) {
  if (coverage.found == 0) {
    stderr.writeln('No coverage lines found for $name.');
    return !enforce;
  }

  final percent = coverage.percent;
  final status = percent >= minimum ? 'PASS' : (enforce ? 'FAIL' : 'WARN');
  stdout.writeln(
    '$name coverage: ${percent.toStringAsFixed(1)}% '
    '(${coverage.hit}/${coverage.found} lines), minimum '
    '${minimum.toStringAsFixed(1)}% [$status]',
  );

  if (percent >= minimum) return true;
  if (!enforce) {
    final date = enforceAfter == null ? 'later' : _dateKey(enforceAfter);
    stdout.writeln('$name threshold becomes blocking on $date.');
    return true;
  }

  stderr.writeln(
    '$name coverage ${percent.toStringAsFixed(1)}% is below '
    '${minimum.toStringAsFixed(1)}%.',
  );
  return false;
}

double _doubleArg(
  List<String> args,
  String prefix, {
  required double fallback,
}) {
  final arg = args.firstWhere(
    (arg) => arg.startsWith(prefix),
    orElse: () => '',
  );
  if (arg.isEmpty) return fallback;
  return double.parse(arg.substring(prefix.length));
}

DateTime? _dateArg(List<String> args, String prefix) {
  final arg = args.firstWhere(
    (arg) => arg.startsWith(prefix),
    orElse: () => '',
  );
  if (arg.isEmpty) return null;
  final date = DateTime.tryParse(arg.substring(prefix.length));
  if (date == null) {
    stderr.writeln('Invalid date for $prefix. Use YYYY-MM-DD.');
    exit(1);
  }
  return DateTime.utc(date.year, date.month, date.day);
}

List<_PathMinimum> _pathMinimums(List<String> args) {
  final result = <_PathMinimum>[];
  for (final arg in args.where((arg) => arg.startsWith('--path-min='))) {
    final value = arg.substring('--path-min='.length);
    final splitAt = value.lastIndexOf(':');
    if (splitAt <= 0 || splitAt == value.length - 1) {
      stderr.writeln('Invalid --path-min value "$value". Use path:minimum.');
      exit(1);
    }
    final path = value.substring(0, splitAt);
    final minimum = double.tryParse(value.substring(splitAt + 1));
    if (minimum == null) {
      stderr.writeln('Invalid --path-min minimum in "$value".');
      exit(1);
    }
    result.add(_PathMinimum(pathMatch: path, minimum: minimum));
  }
  return result;
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _PathMinimum {
  const _PathMinimum({required this.pathMatch, required this.minimum});

  final String pathMatch;
  final double minimum;

  String get label => 'Path "$pathMatch"';
}

class _LineCoverage {
  const _LineCoverage({required this.found, required this.hit});

  final int found;
  final int hit;

  double get percent => found == 0 ? 0 : hit / found * 100;
}
