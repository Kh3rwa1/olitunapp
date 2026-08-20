#!/usr/bin/env node
import fs from "node:fs";

export function validateBackupPayload(rawBackupJson) {
  let parsed;
  try {
    parsed = typeof rawBackupJson === "string" ? JSON.parse(rawBackupJson) : rawBackupJson;
  } catch (err) {
    throw new Error("Invalid JSON backup format: " + err.message);
  }

  if (!parsed || typeof parsed !== "object") {
    throw new Error("Backup payload is not an object");
  }

  if (!parsed.schemaVersion || parsed.schemaVersion < 1) {
    throw new Error("Invalid or missing schemaVersion in backup");
  }

  if (!parsed.createdAt || isNaN(Date.parse(parsed.createdAt))) {
    throw new Error("Invalid or missing createdAt ISO timestamp in backup");
  }

  if (!parsed.collections || typeof parsed.collections !== "object") {
    throw new Error("Missing collections dictionary in backup payload");
  }

  const collections = parsed.collections;
  const verifiedCounts = {};
  let totalDocs = 0;

  for (const [colName, docs] of Object.entries(collections)) {
    if (!Array.isArray(docs)) {
      throw new Error(`Collection "${colName}" must be an array of documents`);
    }
    for (const doc of docs) {
      if (!doc || typeof doc !== "object" || !doc.$id) {
        throw new Error(`Document in "${colName}" missing required $id`);
      }
    }
    verifiedCounts[colName] = docs.length;
    totalDocs += docs.length;
  }

  return {
    valid: true,
    schemaVersion: parsed.schemaVersion,
    createdAt: parsed.createdAt,
    databaseId: parsed.databaseId || "olitun_db",
    collectionCount: Object.keys(collections).length,
    totalDocuments: totalDocs,
    counts: verifiedCounts,
  };
}

export async function restoreBackupDryRun(backupPayload, targetDatabases = null) {
  const meta = validateBackupPayload(backupPayload);
  const collections = typeof backupPayload === "string" ? JSON.parse(backupPayload).collections : backupPayload.collections;

  const restoredLog = [];

  for (const [collectionId, docs] of Object.entries(collections)) {
    for (const doc of docs) {
      // If live databases client provided, execute dry-run or validation
      if (targetDatabases && targetDatabases.validateDocument) {
        await targetDatabases.validateDocument(collectionId, doc);
      }
      restoredLog.push({ collectionId, id: doc.$id, status: "restorable" });
    }
  }

  return {
    success: true,
    meta,
    restoredCount: restoredLog.length,
  };
}

// CLI execution
if (process.argv[1] && import.meta.url.endsWith(process.argv[1].split("/").pop())) {
  const filePath = process.argv[2];
  if (!filePath) {
    console.error("Usage: node scripts/verify_backup_restoration.mjs <backup-file.json>");
    process.exit(1);
  }

  try {
    const raw = fs.readFileSync(filePath, "utf8");
    const result = validateBackupPayload(raw);
    console.log(`✅ Backup verification passed! ${result.totalDocuments} documents across ${result.collectionCount} collections.`);
  } catch (err) {
    console.error("❌ Backup validation failed: " + err.message);
    process.exit(1);
  }
}
