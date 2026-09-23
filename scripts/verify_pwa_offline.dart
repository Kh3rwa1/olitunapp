// ignore_for_file: avoid_print
// Build-time helper: prints progress to the Appwrite build log.
import 'dart:io';
import 'dart:convert';

void main() {
  final root = Directory.current.path;
  final webDir = '$root/web';
  final buildDir = '$root/build/web';
  final failures = <String>[];

  String? check(String file, String label, {bool read = false}) {
    final f = File(file);
    if (!f.existsSync()) {
      failures.add('$label missing: ${f.path}');
      return null;
    }
    return read ? f.readAsStringSync() : '';
  }

  check('$webDir/sw.js', 'Custom service worker');
  check('$webDir/offline.html', 'Offline fallback page');
  final manifestSrc = check(
    '$webDir/manifest.json',
    'Web manifest',
    read: true,
  );
  check('$webDir/pwa_runtime.js', 'PWA runtime');
  check('$webDir/pwa_install.js', 'PWA install handler');

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
      failures.add('manifest.json is not valid JSON: $e');
    }
  }

  final runtimeF = File('$webDir/pwa_runtime.js');
  final runtimeSrc = runtimeF.existsSync() ? runtimeF.readAsStringSync() : '';
  if (!runtimeSrc.contains("register('sw.js'") &&
      !runtimeSrc.contains('register("sw.js"')) {
    failures.add('pwa_runtime.js must register sw.js for offline support');
  }

  final swF = File('$webDir/sw.js');
  final swSrc = swF.existsSync() ? swF.readAsStringSync() : '';
  if (!swSrc.contains('olitun-media-v1') ||
      !swSrc.contains('isCacheableAppwriteMedia')) {
    failures.add('sw.js must cache Appwrite artwork in the olitun-media cache');
  }
  if (!swSrc.contains('/pwa_runtime.js') ||
      !swSrc.contains('/pwa_install.js')) {
    failures.add(
      'sw.js must precache pwa_runtime.js and pwa_install.js in APP_SHELL',
    );
  }
  if (!swSrc.contains('/canvaskit/canvaskit.js') ||
      !swSrc.contains('/canvaskit/canvaskit.wasm')) {
    failures.add('sw.js must precache canvaskit in APP_SHELL');
  }

  if (Directory(buildDir).existsSync()) {
    check('$buildDir/sw.js', 'Built service worker');
    check('$buildDir/offline.html', 'Built offline fallback');
    check('$buildDir/pwa_runtime.js', 'Built PWA runtime');
    check('$buildDir/pwa_install.js', 'Built PWA install handler');
    check('$buildDir/canvaskit/canvaskit.js', 'Built CanvasKit JS');
    check('$buildDir/canvaskit/canvaskit.wasm', 'Built CanvasKit WASM');
  }

  if (failures.isNotEmpty) {
    print('PWA offline verification failed:');
    for (var f in failures) {
      print('  - $f');
    }
    exit(1);
  }

  print('PWA offline verification passed.');
  exit(0);
}
