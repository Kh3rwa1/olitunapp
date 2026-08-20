import fs from 'node:fs';
import path from 'node:path';

const WORKFLOWS_DIR = path.resolve('.github/workflows');

if (!fs.existsSync(WORKFLOWS_DIR)) {
  console.error(`Error: Workflows directory not found at ${WORKFLOWS_DIR}`);
  process.exit(1);
}

const workflowFiles = fs
  .readdirSync(WORKFLOWS_DIR)
  .filter((file) => file.endsWith('.yml') || file.endsWith('.yaml'));

let totalActions = 0;
let violations = [];

const SHA_REGEX = /@([a-f0-9]{40})/i;

for (const file of workflowFiles) {
  const filePath = path.join(WORKFLOWS_DIR, file);
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  lines.forEach((line, index) => {
    const trimmed = line.trim();
    if (trimmed.startsWith('- uses:') || trimmed.startsWith('uses:')) {
      const match = trimmed.match(/uses:\s*([^\s#]+)/);
      if (match) {
        const actionRef = match[1];
        // Ignore local workflow references or docker actions
        if (actionRef.startsWith('./') || actionRef.startsWith('docker://')) {
          return;
        }

        totalActions++;
        const atIndex = actionRef.indexOf('@');
        if (atIndex === -1) {
          violations.push({
            file,
            line: index + 1,
            action: actionRef,
            reason: 'Missing @ version or SHA specifier',
          });
          return;
        }

        const ref = actionRef.substring(atIndex + 1);
        if (!/^[a-f0-9]{40}$/i.test(ref)) {
          violations.push({
            file,
            line: index + 1,
            action: actionRef,
            reason: `Action is pinned to mutable tag/branch "${ref}" instead of a 40-character commit SHA`,
          });
        }
      }
    }
  });
}

console.log(`Audited ${totalActions} action references across ${workflowFiles.length} workflow files.`);

if (violations.length > 0) {
  console.error('\n❌ Security Violation: Found unpinned GitHub Actions:');
  for (const v of violations) {
    console.error(`  - ${v.file}:${v.line} -> ${v.action} (${v.reason})`);
  }
  process.exit(1);
} else {
  console.log('✅ All GitHub Actions are immutably pinned to 40-character commit SHAs.');
  process.exit(0);
}
