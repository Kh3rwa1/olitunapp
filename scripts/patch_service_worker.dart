import 'dart:io';

void main() {
  final file = File('build/web/flutter_service_worker.js');
  if (!file.existsSync()) {
    print('Error: Service worker file not found at build/web/flutter_service_worker.js');
    exit(1);
  }

  String content = file.readAsStringSync();
  
  if (content.contains('// ITUN_PATCHED_SW')) {
    if (!content.contains('flutter_bootstrap.js')) {
      print('Verification: patch marker present and flutter_bootstrap.js fully absent. Exiting successfully.');
      exit(0);
    }
    print('Warning: patch marker present but flutter_bootstrap.js still found. Re-patching...');
  }

  bool patched = false;

  final resourcesRegex = RegExp(r'''["']flutter_bootstrap\.js["']\s*:\s*["'][a-f0-9]+["']\s*,?\s*''', caseSensitive: false);
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
    print('Info: flutter_bootstrap.js not found in RESOURCES or CORE — already absent from service worker.');
    print('  No patching needed; stamping marker for verify step.');
  }

  if (!content.contains('// ITUN_PATCHED_SW')) {
    content = content.trim() + '\n\n// ITUN_PATCHED_SW\n';
  }

  file.writeAsStringSync(content);
  print('Successfully patched service worker.');
  exit(0);
}
