import 'dart:io';
import 'dart:convert';

void main() {
  final root = Directory.current.path;
  final webDir = '${root}/web';
  final buildDir = '${root}/build/web';
  final failures = <String>[];

  String? check(String file, String label) {
    final f = File(file);
    if (!f.existsSync()) {
      failures.add('${label} missing: ${f.path}');
      return null;
    }
    return f.readAsStringSync();
  }

  check('${webDir}/sw.js', 'Custom service worker');
  check('${webDir}/offline.html', 'Offline fallback page');
  final manifestSrc = check('${webDir}/manifest.json', 'Web manifest');
  check('${webDir}/pwa_runtime.js', 'PWA runtime');
  check('${webDir}/pwa_install.js', 'PWA install handler');

  if (manifestSrc != null) {
    try {
      final manifest = jsonDecode(manifestSrc);
      if (manifest['start_url'] != '/') {
        failures.add('manifest start_url must be "/" for offline launch');
      }
      if (manifest['scope'] != '/') {
        failures.add('manifest scope must be "/"');
      }
    } catch (e) {
      failures.add('manifest.json is not valid JSON: ${e}');
    }
  }

  final runtimeF = File('${webDir}/pwa_runtime.js');
  final runtimeSrc = runtimeF.existsSync() ? runtimeF.readAsStringSync() : '';
  if (!runtimeSrc.contains("register('sw.js'") &&
      !runtimeSrc.contains('register("sw.js"')) {
    failures.add('pwa_runtime.js must register sw.js for offline support');
  }

  final swF = File('${webDir}/sw.js');
  final swSrc = swF.existsSync() ? swF.readAsStringSync() : '';
  if (!swSrc.contains('olitun-media-v1') ||
      !swSrc.contains('isCacheableAppwriteMedia')) {
    failures.add('sw.js must cache Appwrite artwork in the olitun-media cache');
  }

  if (Directory(buildDir).existsSync()) {
    check('${buildDir}/sw.js', 'Built service worker');
    check('${buildDir}/offline.html', 'Built offline fallback');
  }

  if (failures.isNotEmpty) {
    print('PWA offline verification failed:');
    for (var f in failures) print('  - ${f}');
    exit(1);
  }

  print('PWA offline verification passed.');
  exit(0);
}
