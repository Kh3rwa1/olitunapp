import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve('.');

function auditSigningConfiguration() {
  console.log('🔍 Auditing Release Signing Path Consistency across repository...');

  // 1. Check build.gradle.kts
  const gradlePath = resolve(repoRoot, 'android/app/build.gradle.kts');
  const gradleContent = readFileSync(gradlePath, 'utf8');
  if (!gradleContent.includes('val keystorePropertiesFile = rootProject.file("key.properties")')) {
    throw new Error('android/app/build.gradle.kts must resolve key.properties via rootProject.file("key.properties")');
  }
  if (!gradleContent.includes('storeFile = keystoreProperties["storeFile"]?.let { file(it) }')) {
    throw new Error('android/app/build.gradle.kts must resolve storeFile relative to app module via file(it)');
  }

  // 2. Check build-apk.yml
  const buildApkPath = resolve(repoRoot, '.github/workflows/build-apk.yml');
  const buildApkContent = readFileSync(buildApkPath, 'utf8');
  if (!buildApkContent.includes('android/app/upload-keystore.jks')) {
    throw new Error('.github/workflows/build-apk.yml must write keystore to android/app/upload-keystore.jks');
  }
  if (!buildApkContent.includes('storeFile=upload-keystore.jks')) {
    throw new Error('.github/workflows/build-apk.yml must configure storeFile=upload-keystore.jks in key.properties');
  }

  // 3. Check release-checklist.yml
  const releaseChecklistPath = resolve(repoRoot, '.github/workflows/release-checklist.yml');
  const releaseChecklistContent = readFileSync(releaseChecklistPath, 'utf8');
  if (!releaseChecklistContent.includes('android/app/upload-keystore.jks')) {
    throw new Error('.github/workflows/release-checklist.yml must write keystore to android/app/upload-keystore.jks');
  }
  if (!releaseChecklistContent.includes('storeFile=upload-keystore.jks')) {
    throw new Error('.github/workflows/release-checklist.yml must configure storeFile=upload-keystore.jks in key.properties');
  }

  console.log('✅ Signing configuration audit passed: All workflows and Gradle definitions resolve canonical android/app/upload-keystore.jks path consistently.');
}

try {
  auditSigningConfiguration();
} catch (err) {
  console.error(`❌ Signing configuration audit failed: ${err.message}`);
  process.exit(1);
}
