import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final path = _requiredArg(args, '--path=');
  final budgetKey = _requiredArg(args, '--budget-key=');
  final baselinePath =
      _arg(args, '--baseline=') ?? 'tool/performance_budgets.json';
  final maxGrowth = _doubleArg(args, '--max-growth=', fallback: 5);

  final target =
      FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
      ? Directory(path)
      : File(path);
  if (!target.existsSync()) {
    stderr.writeln('Size budget target does not exist: $path');
    exit(1);
  }

  final baselineFile = File(baselinePath);
  if (!baselineFile.existsSync()) {
    stderr.writeln('Baseline budget file does not exist: $baselinePath');
    exit(1);
  }

  final baseline = jsonDecode(baselineFile.readAsStringSync());
  if (baseline is! Map || baseline[budgetKey] is! num) {
    stderr.writeln('Budget key "$budgetKey" missing from $baselinePath.');
    exit(1);
  }

  final baselineBytes = (baseline[budgetKey] as num).round();
  final currentBytes = _sizeBytes(target);
  final allowedBytes = (baselineBytes * (1 + maxGrowth / 100)).round();
  final growth = baselineBytes == 0
      ? 0.0
      : (currentBytes - baselineBytes) / baselineBytes * 100;

  stdout.writeln(
    '$budgetKey size: ${_mb(currentBytes)} MB, baseline '
    '${_mb(baselineBytes)} MB, max ${_mb(allowedBytes)} MB '
    '(${maxGrowth.toStringAsFixed(1)}% growth allowed).',
  );

  if (currentBytes > allowedBytes) {
    stderr.writeln(
      '$budgetKey grew by ${growth.toStringAsFixed(1)}%, above the '
      '${maxGrowth.toStringAsFixed(1)}% performance budget.',
    );
    exit(1);
  }
}

int _sizeBytes(FileSystemEntity entity) {
  if (entity is File) return entity.lengthSync();
  final directory = entity as Directory;
  var total = 0;
  for (final child in directory.listSync(recursive: true, followLinks: false)) {
    if (child is File) total += child.lengthSync();
  }
  return total;
}

String _requiredArg(List<String> args, String prefix) {
  final value = _arg(args, prefix);
  if (value == null || value.isEmpty) {
    stderr.writeln('Missing required argument $prefix');
    exit(1);
  }
  return value;
}

String? _arg(List<String> args, String prefix) {
  final arg = args.firstWhere(
    (arg) => arg.startsWith(prefix),
    orElse: () => '',
  );
  return arg.isEmpty ? null : arg.substring(prefix.length);
}

double _doubleArg(
  List<String> args,
  String prefix, {
  required double fallback,
}) {
  final value = _arg(args, prefix);
  if (value == null) return fallback;
  return double.parse(value);
}

String _mb(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(2);
