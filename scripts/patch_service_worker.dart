// ignore_for_file: avoid_print
// Build-time helper: prints progress to the Appwrite build log.
import 'dart:io';

void main() {
  final file = File('build/web/flutter_service_worker.js');
  if (!file.existsSync()) {
    print(
      'Error: Service worker file not found at build/web/flutter_service_worker.js',
    );
    exit(1);
  }

  String content = file.readAsStringSync();

  if (content.contains('// ITUN_PATCHED_SW')) {
    if (!content.contains('flutter_bootstrap.js')) {
      print(
        'Verification: patch marker present and flutter_bootstrap.js fully absent.',
      );
    } else {
      print(
        'Warning: patch marker present but flutter_bootstrap.js still found. Re-patching...',
      );
    }
  }

  bool patched = false;

  final resourcesRegex = RegExp(
    r'''["']flutter_bootstrap\.js["']\s*:\s*["'][a-f0-9]+["']\s*,?\s*''',
    caseSensitive: false,
  );
  if (resourcesRegex.hasMatch(content)) {
    content = content.replaceAll(resourcesRegex, '');
    print('  - Removed flutter_bootstrap.js from RESOURCES map.');
    patched = true;
  }

  final coreRegex = RegExp(r'''["']flutter_bootstrap\.js["']\s*,?\s*\n?''');
  if (coreRegex.hasMatch(content)) {
    content = content.replaceAll(coreRegex, '');
    print('  - Removed flutter_bootstrap.js from CORE array.');
    patched = true;
  }

  if (!patched) {
    print(
      'Info: flutter_bootstrap.js not found in RESOURCES or CORE — already absent from service worker.',
    );
    print('  No patching needed; stamping marker for verify step.');
  }

  if (!content.contains('// ITUN_PATCHED_SW')) {
    content = '${content.trim()}\n\n// ITUN_PATCHED_SW\n';
  }

  file.writeAsStringSync(content);
  print('Successfully patched service worker.');
  patchBootstrapLoader();
  exit(0);
}

/// Stops Flutter from registering its own service worker so the custom
/// offline worker (web/sw.js) is the only one controlling the scope.
/// Two competing workers alternated control on every load and each
/// controllerchange reloaded the page — an infinite reload loop.
void patchBootstrapLoader() {
  final bootstrap = File('build/web/flutter_bootstrap.js');
  if (!bootstrap.existsSync()) {
    print(
      'Warning: build/web/flutter_bootstrap.js not found; '
      'skipping loader patch (Flutter may have removed SW registration).',
    );
    return;
  }

  var content = bootstrap.readAsStringSync();
  final versionLiteral = RegExp(r'serviceWorkerVersion\s*:\s*"');
  if (content.contains('// ITUN_PATCHED_BOOTSTRAP') &&
      !versionLiteral.hasMatch(content)) {
    print('Verification: bootstrap loader already patched. Skipping.');
    return;
  }

  final loaderCall = RegExp(
    r'serviceWorkerSettings\s*:\s*\{\s*serviceWorkerVersion\s*:\s*"[^"]*"[^}]*\}',
  );
  if (!loaderCall.hasMatch(content)) {
    print(
      'Error: could not find serviceWorkerSettings in flutter_bootstrap.js. '
      'Failing so a dual-service-worker reload loop cannot ship silently.',
    );
    exit(1);
  }
  content = content.replaceAll(loaderCall, 'serviceWorkerSettings: null');
  if (!content.contains('// ITUN_PATCHED_BOOTSTRAP')) {
    content = '${content.trim()}\n\n// ITUN_PATCHED_BOOTSTRAP\n';
  }
  bootstrap.writeAsStringSync(content);
  print('  - Disabled Flutter service-worker registration in loader.');
}
