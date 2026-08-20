import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve('.');

function auditNodeDependencies() {
  console.log('🔍 Auditing Node.js & node-appwrite dependency alignment across repository...');

  const rootPkgPath = resolve(repoRoot, 'package.json');
  const transPkgPath = resolve(repoRoot, 'functions/translator/package.json');
  const transLockPath = resolve(repoRoot, 'functions/translator/package-lock.json');
  const ciWorkflowPath = resolve(repoRoot, '.github/workflows/flutter-ci.yml');

  if (!existsSync(rootPkgPath) || !existsSync(transPkgPath) || !existsSync(transLockPath)) {
    throw new Error('Required package.json or package-lock.json files are missing.');
  }

  const rootPkg = JSON.parse(readFileSync(rootPkgPath, 'utf8'));
  const transPkg = JSON.parse(readFileSync(transPkgPath, 'utf8'));
  const transLock = JSON.parse(readFileSync(transLockPath, 'utf8'));
  const ciWorkflow = readFileSync(ciWorkflowPath, 'utf8');

  const rootAppwrite = rootPkg.dependencies?.['node-appwrite'];
  const transAppwrite = transPkg.dependencies?.['node-appwrite'];

  if (!transAppwrite) {
    throw new Error('functions/translator/package.json must declare node-appwrite dependency.');
  }

  const lockAppwrite =
    transLock.packages?.['node_modules/node-appwrite']?.version ||
    transLock.dependencies?.['node-appwrite']?.version;
  if (!lockAppwrite) {
    throw new Error('functions/translator/package-lock.json must contain resolved node-appwrite package.');
  }

  console.log(`📦 Translator package.json node-appwrite: ${transAppwrite}`);
  console.log(`📦 Translator package-lock.json node-appwrite: ${lockAppwrite}`);

  if (rootAppwrite) {
    console.log(`📦 Root package.json node-appwrite: ${rootAppwrite}`);
    const rootMajor = rootAppwrite.replace(/^[\^~]/, '').split('.')[0];
    const transMajor = transAppwrite.replace(/^[\^~]/, '').split('.')[0];
    if (rootMajor !== transMajor) {
      throw new Error(
        `SDK major version mismatch: root is ${rootAppwrite} (v${rootMajor}), but translator is ${transAppwrite} (v${transMajor}).`
      );
    }
  }

  // Verify CI runs translator tests from functions/translator
  if (
    !ciWorkflow.includes('npm ci --prefix functions/translator') ||
    !ciWorkflow.includes('npm test --prefix functions/translator')
  ) {
    throw new Error('.github/workflows/flutter-ci.yml must install and test translator using --prefix functions/translator.');
  }

  console.log('✅ Node dependency alignment audit passed: Root and Translator SDKs are fully aligned with zero drift.');
}

try {
  auditNodeDependencies();
} catch (err) {
  console.error(`❌ Node dependency alignment audit failed: ${err.message}`);
  process.exit(1);
}
