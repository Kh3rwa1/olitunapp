import fs from 'fs';

try {
  const content = fs.readFileSync('appwrite.json', 'utf8');
  const appwrite = JSON.parse(content);
  
  let hasError = false;

  if (appwrite.sites && Array.isArray(appwrite.sites)) {
    for (const site of appwrite.sites) {
      if (site.ignore && site.ignore.includes('scripts')) {
        console.error(`❌ FAIL: Site "${site.name}" (${site.$id}) has "scripts" in its ignore array.`);
        console.error(`   The Appwrite cloud builder must have access to the "scripts/" directory to run build_web.sh.`);
        hasError = true;
      }

      if (!site.buildCommand || !site.buildCommand.includes('scripts/build_web.sh')) {
         console.error(`❌ FAIL: Site "${site.name}" (${site.$id}) does not use scripts/build_web.sh in its buildCommand.`);
         console.error(`   It must use this script to patch the Service Worker. Found: ${site.buildCommand}`);
         hasError = true;
      }
    }
  }

  if (hasError) {
    process.exit(1);
  } else {
    console.log(`✅ Appwrite configuration is valid and deployable.`);
  }

} catch(err) {
  console.error(`❌ FAIL: Could not read or parse appwrite.json: ${err.message}`);
  process.exit(1);
}
