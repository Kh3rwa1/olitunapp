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

void main(List<String> args) {
  final minimum = _doubleArg(args, '--min=', fallback: 65);
  final enforceAfter = _dateArg(args, '--enforce-after=');
  final pathMinimums = _pathMinimums(args);
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

  if (failed) exit(1);
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
