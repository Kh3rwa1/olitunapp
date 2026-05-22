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
  final minArg = args.firstWhere(
    (arg) => arg.startsWith('--min='),
    orElse: () => '--min=65',
  );
  final minimum = double.parse(minArg.substring('--min='.length));
  final file = File('coverage/lcov.info');

  if (!file.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run flutter test --coverage.',
    );
    exit(1);
  }

  var currentFile = '';
  var include = false;
  var found = 0;
  var hit = 0;

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      include = criticalLearningPaths.any(currentFile.contains);
      continue;
    }

    if (!include || !line.startsWith('DA:')) continue;

    final data = line.substring(3).split(',');
    if (data.length < 2) continue;
    found += 1;
    if ((int.tryParse(data[1]) ?? 0) > 0) {
      hit += 1;
    }
  }

  if (found == 0) {
    stderr.writeln('No critical learning coverage lines found.');
    exit(1);
  }

  final percent = hit / found * 100;
  stdout.writeln(
    'Critical learning coverage: ${percent.toStringAsFixed(1)}% '
    '($hit/$found lines), minimum ${minimum.toStringAsFixed(1)}%',
  );

  if (percent < minimum) {
    stderr.writeln(
      'Coverage ${percent.toStringAsFixed(1)}% is below '
      '${minimum.toStringAsFixed(1)}%.',
    );
    exit(1);
  }
}
