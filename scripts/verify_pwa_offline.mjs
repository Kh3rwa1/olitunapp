import fs from 'fs';
import path from 'path';

const root = process.cwd();
const webDir = path.resolve(root, 'web');
const buildDir = path.resolve(root, 'build/web');
const failures = [];

function check(file, label) {
  if (!fs.existsSync(file)) {
    failures.push(`${label} missing: ${path.relative(root, file)}`);
    return null;
  }
  return fs.readFileSync(file, 'utf8');
}

// 1. Source files must exist.
check(path.join(webDir, 'sw.js'), 'Custom service worker');
check(path.join(webDir, 'offline.html'), 'Offline fallback page');
const manifestSrc = check(path.join(webDir, 'manifest.json'), 'Web manifest');
check(path.join(webDir, 'pwa_runtime.js'), 'PWA runtime');
check(path.join(webDir, 'pwa_install.js'), 'PWA install handler');

// 2. Manifest must be offline-safe: start_url "/" (no query), scope "/".
if (manifestSrc) {
  try {
    const manifest = JSON.parse(manifestSrc);
    if (manifest.start_url !== '/') {
      failures.push(
        `manifest start_url must be "/" for offline launch (found "${manifest.start_url}")`,
      );
    }
    if (manifest.scope !== '/') {
      failures.push(`manifest scope must be "/" (found "${manifest.scope}")`);
    }
    const icons = manifest.icons || [];
    const has512Any = icons.some(
      (i) => i.sizes === '512x512' && String(i.purpose || 'any').includes('any'),
    );
    const hasMaskable = icons.some((i) =>
      String(i.purpose || '').includes('maskable'),
    );
    if (!has512Any) failures.push('manifest needs a 512x512 purpose "any" icon');
    if (!hasMaskable) failures.push('manifest needs a maskable icon');
  } catch (e) {
    failures.push(`manifest.json is not valid JSON: ${e.message}`);
  }
}

// 3. Runtime must register our worker, not only the deprecated Flutter stub.
const runtimeSrc = fs.existsSync(path.join(webDir, 'pwa_runtime.js'))
  ? fs.readFileSync(path.join(webDir, 'pwa_runtime.js'), 'utf8')
  : '';
if (!runtimeSrc.includes("register('sw.js'") && !runtimeSrc.includes('register("sw.js"')) {
  failures.push('pwa_runtime.js must register sw.js for offline support');
}

// 4. Worker must runtime-cache Appwrite artwork (Bakhed thumbnails, lesson
// covers) in an unversioned media cache, and must never wipe it on activate.
const swSrc = fs.existsSync(path.join(webDir, 'sw.js'))
  ? fs.readFileSync(path.join(webDir, 'sw.js'), 'utf8')
  : '';
if (!swSrc.includes('olitun-media-v1') || !swSrc.includes('isCacheableAppwriteMedia')) {
  failures.push('sw.js must cache Appwrite artwork in the olitun-media cache');
}

// 5. If a build exists, the output must contain the worker + fallback.
if (fs.existsSync(buildDir)) {
  check(path.join(buildDir, 'sw.js'), 'Built service worker');
  check(path.join(buildDir, 'offline.html'), 'Built offline fallback');
}

if (failures.length > 0) {
  console.error('PWA offline verification failed:');
  failures.forEach((f) => console.error(`  - ${f}`));
  process.exit(1);
}

console.log('PWA offline verification passed: sw.js, offline.html, manifest start_url, runtime registration all look good.');
