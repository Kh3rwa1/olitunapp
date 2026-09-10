import { readFileSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve('.');
const governedNodeAppwriteVersion = '25.1.0';

function listedDependabotPath(source, path) {
  const escaped = path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`^\\s*-\\s*["']?${escaped}["']?\\s*$`, 'm').test(source);
}

function auditNodeDependencies() {
  console.log('🔍 Auditing Node.js dependency governance...');

  const rootPkgPath = resolve(repoRoot, 'package.json');
  const transPkgPath = resolve(repoRoot, 'functions/translator/package.json');
  const transLockPath = resolve(
    repoRoot,
    'functions/translator/package-lock.json',
  );
  const ciWorkflowPath = resolve(
    repoRoot,
    '.github/workflows/flutter-ci.yml',
  );
  const dependabotPath = resolve(repoRoot, '.github/dependabot.yml');

  for (const path of [
    rootPkgPath,
    transPkgPath,
    transLockPath,
    ciWorkflowPath,
    dependabotPath,
  ]) {
    if (!existsSync(path)) throw new Error(`Required file is missing: ${path}`);
  }

  const rootPkg = JSON.parse(readFileSync(rootPkgPath, 'utf8'));
  const transPkg = JSON.parse(readFileSync(transPkgPath, 'utf8'));
  const transLock = JSON.parse(readFileSync(transLockPath, 'utf8'));
  const ciWorkflow = readFileSync(ciWorkflowPath, 'utf8');
  const dependabot = readFileSync(dependabotPath, 'utf8');

  const rootAppwrite = rootPkg.dependencies?.['node-appwrite'];
  const transAppwrite = transPkg.dependencies?.['node-appwrite'];
  const lockAppwrite =
    transLock.packages?.['node_modules/node-appwrite']?.version ||
    transLock.dependencies?.['node-appwrite']?.version;

  if (rootAppwrite !== governedNodeAppwriteVersion) {
    throw new Error(
      `Root node-appwrite must remain exactly ${governedNodeAppwriteVersion}; found ${rootAppwrite ?? 'missing'}.`,
    );
  }
  if (transAppwrite !== governedNodeAppwriteVersion) {
    throw new Error(
      `Translator node-appwrite must remain exactly ${governedNodeAppwriteVersion}; found ${transAppwrite ?? 'missing'}.`,
    );
  }
  if (lockAppwrite !== governedNodeAppwriteVersion) {
    throw new Error(
      `Translator lockfile must resolve node-appwrite ${governedNodeAppwriteVersion}; found ${lockAppwrite ?? 'missing'}.`,
    );
  }

  if (listedDependabotPath(dependabot, '/functions/*')) {
    throw new Error(
      'Dependabot must list function directories explicitly so the governed translator package is excluded.',
    );
  }
  if (listedDependabotPath(dependabot, '/functions/translator')) {
    throw new Error(
      'Dependabot must not update the governed translator package.',
    );
  }

  if (
    !ciWorkflow.includes('npm ci --prefix functions/translator') ||
    !ciWorkflow.includes('npm test --prefix functions/translator')
  ) {
    throw new Error(
      'Flutter CI must install and test the translator package independently.',
    );
  }

  console.log(
    `✅ node-appwrite ${governedNodeAppwriteVersion} is pinned and protected from automated upgrades.`,
  );
}

try {
  auditNodeDependencies();
} catch (error) {
  console.error(`❌ Node dependency governance failed: ${error.message}`);
  process.exit(1);
}
