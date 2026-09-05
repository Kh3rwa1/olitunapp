from pathlib import Path
import json
changed=set()
def edit(path,old,new,count=1):
    p=Path(path); text=p.read_text()
    assert text.count(old)==count, (path, text.count(old), old[:100])
    p.write_text(text.replace(old,new)); changed.add(path)
def write(path,text):
    p=Path(path); p.parent.mkdir(parents=True,exist_ok=True); p.write_text(text); changed.add(path)

# Apply the already-reviewed workflow-only section, previously not committed.
source=Path('/tmp/review_patch.py').read_text()
start=source.index("p = '.github/workflows/staging-health.yml'")
end=source.index('# 6. Free public translation',start)
exec(compile(source[start:end], 'reviewed_workflow_patch', 'exec'))
edit('.github/workflows/flutter-ci.yml','      - name: Verify Node Dependency Alignment','      - name: Verify function deployment contract\n        run: node scripts/verify_function_deployment.mjs\n      - name: Verify Node Dependency Alignment')
# Stop staging fixtures from ever being executed against the production project.
p='.github/workflows/staging-health.yml'
edit(p,'      - name: Staging Appwrite Smoke Test', '''      - name: Require an isolated staging project
        env:
          STAGING_APPWRITE_PROJECT_ID: ${{ secrets.STAGING_APPWRITE_PROJECT_ID }}
        run: |
          node --input-type=module - <<'JS'
          import fs from 'node:fs';
          const staging = process.env.STAGING_APPWRITE_PROJECT_ID;
          const production = JSON.parse(fs.readFileSync('appwrite.json', 'utf8')).projectId;
          if (!staging || staging === production) throw new Error('A separate non-production Appwrite project is required');
          JS
      - name: Staging Appwrite Smoke Test''')

# Fix analyzer findings, without weakening lint rules.
p='lib/core/ads/ad_service.dart'
edit(p,"        AdConsentError('Ad consent is not available.', 'consent_unavailable'),", "        const AdConsentError('Ad consent is not available.', 'consent_unavailable'),",count=2)
p='lib/core/payments/purchase_repository.dart'
edit(p,'    if (!_disposed)\n      ref.read(entitlementRevisionProvider(userId).notifier).state++;','    if (!_disposed) {\n      ref.read(entitlementRevisionProvider(userId).notifier).state++;\n    }')
edit(p,'      final isStale = meta?.isExpired ?? false;\n','')
edit(p,'        status: isStale\n            ? EntitlementStatus.staleCached\n            : EntitlementStatus.cached,','        status: EntitlementStatus.cached,')
edit(p,'          if (stale != null)\n            return EntitlementResult(', '          if (stale != null) {\n            return EntitlementResult(')
edit(p,"                  'Offline access is limited to 24 hours since verification.',\n            );", "                  'Offline access is limited to 24 hours since verification.',\n            );\n          }")

# Offline persistence tests must mock the remote database, not instantiate a native SDK.
p='test/shared/offline/content_mutation_replay_test.dart'
edit(p,"import 'package:appwrite/appwrite.dart';", "import 'package:appwrite/appwrite.dart';\nimport 'package:mocktail/mocktail.dart';")
edit(p,'class FailingOutbox extends MutationOutboxService {','class MockOfflineDatabases extends Mock implements Databases {}\n\nclass FailingOutbox extends MutationOutboxService {')
edit(p,'Databases(Client())','MockOfflineDatabases()',count=3)

# Translator dynamic keys must actually have the document scopes used by budgets/cache.
a=json.loads(Path('appwrite.json').read_text())
for f in a['functions']:
    if f['name']=='translator': f['scopes']=['documents.read','documents.write']
    if f['name']=='cleanupAnalyticsEvents': f['scopes']=sorted(set(f['scopes']+['documents.read','documents.write']))
b=json.loads(Path('appwrite.config.json').read_text()); b['functions']=a['functions']
write('appwrite.json',json.dumps(a,indent=2)+'\n')
write('appwrite.config.json',json.dumps(b,indent=2)+'\n')
p='scripts/verify_function_deployment.mjs'
edit(p,"console.log('Function manifests, schedules, execution roles and deletion scopes verified.');", '''const translator = canonical.find(f => f.name === 'translator');
for (const scope of ['documents.read', 'documents.write']) {
  assert.ok(translator.scopes.includes(scope), `translator missing ${scope}`);
}
console.log('Function manifests, schedules, execution roles and required scopes verified.');''')

# The existing snapshot mapper omitted its return value. Extract a pure, tested mapper.
write('scripts/lib/schema_attribute.mjs', '''export function schemaAttribute(attr) {
  const spec = { key: attr.key, type: attr.type };
  if (attr.size !== undefined && attr.size !== null) spec.size = attr.size;
  spec.array = attr.array || false;
  spec.required = attr.required || false;
  if (attr.elements?.length) spec.elements = attr.elements;
  if (attr.min !== undefined && attr.min !== null) spec.min = attr.min;
  if (attr.max !== undefined && attr.max !== null) spec.max = attr.max;
  return spec;
}
''')
p='scripts/snapshot_appwrite_schema.mjs'
edit(p,"import { join } from 'path';", "import { join } from 'path';\nimport { schemaAttribute } from './lib/schema_attribute.mjs';")
s=Path(p).read_text(); start=s.index('    const mappedAttributes = rawAttributes.map(attr => {'); end=s.index('\n    // Write fixture JSON',start)
edit(p,s[start:end],'    const mappedAttributes = rawAttributes.map(schemaAttribute);\n')
write('functions/test/schema_attribute.test.js', '''import test from 'node:test';
import assert from 'node:assert/strict';
import { schemaAttribute } from '../../scripts/lib/schema_attribute.mjs';
test('schema snapshots serialize actual attributes rather than null entries', () => {
  assert.deepEqual([{ key: 'name', type: 'string', size: 100, required: true }].map(schemaAttribute),
    [{ key: 'name', type: 'string', size: 100, array: false, required: true }]);
});
test('schema snapshots preserve zero bounds and enum values but omit server metadata', () => {
  assert.deepEqual(schemaAttribute({key:'count',type:'integer',min:0,max:0,$id:'server'}),
    {key:'count',type:'integer',array:false,required:false,min:0,max:0});
  assert.deepEqual(schemaAttribute({key:'state',type:'enum',elements:['open'],array:true}),
    {key:'state',type:'enum',array:true,required:false,elements:['open']});
});
''')
# The root suite already includes translator/test/*.test.js; avoid running it twice.
p=Path('functions/test/translation_resource_budget.test.js'); p.unlink(); changed.add(str(p))
Path('/tmp/final_changed_paths.json').write_text(json.dumps(sorted(changed)))
print('Finalized',len(changed),'files')
