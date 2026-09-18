import 'dart:io';

void main() {
  final file = File('build/web/flutter_service_worker.js');
  if (!file.existsSync()) {
    print('Error: Service worker file not found.');
    exit(1);
  }

  final content = file.readAsStringSync();
  final failures = <String>[];

  final resourcesMatch = RegExp(r'const\s+RESOURCES\s*=\s*\{([^}]+)\}').firstMatch(content);
  if (resourcesMatch != null && resourcesMatch.group(1)!.contains('flutter_bootstrap.js')) {
    failures.add('flutter_bootstrap.js is still present in the RESOURCES cache manifest');
  }

  final coreMatch = RegExp(r'const\s+CORE\s*=\s*\[([^\]]*)\]').firstMatch(content);
  if (coreMatch != null && coreMatch.group(1)!.contains('flutter_bootstrap.js')) {
    failures.add('flutter_bootstrap.js is still present in the CORE shell files array');
  }

  if (!content.contains('// ITUN_PATCHED_SW')) {
    failures.add('ITUN_PATCHED_SW marker is missing — patch may not have run');
  }

  if (failures.isNotEmpty) {
    print('Verification Failure:');
    for (var f in failures) print('  - ${f}');
    exit(1);
  }

  print('Verification Success: flutter_bootstrap.js is not cached by the service worker.');
  exit(0);
}
