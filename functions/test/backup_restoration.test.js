import assert from "node:assert/strict";
import test from "node:test";
import {
  validateBackupPayload,
  restoreBackupDryRun,
} from "../../scripts/verify_backup_restoration.mjs";

test("Backup Restoration: valid backup payload passes schema & document verification", async () => {
  const sampleBackup = {
    schemaVersion: 1,
    createdAt: new Date().toISOString(),
    databaseId: "olitun_db",
    collections: {
      categories: [
        { $id: "cat_alphabets", titleLatin: "Alphabets", totalLessons: 5 },
        { $id: "cat_numbers", titleLatin: "Numbers", totalLessons: 2 },
      ],
      lessons: [
        { $id: "lesson_1", categoryId: "cat_alphabets", titleLatin: "Lesson 1" },
      ],
    },
    counts: { categories: 2, lessons: 1 },
  };

  const validation = validateBackupPayload(sampleBackup);
  assert.equal(validation.valid, true);
  assert.equal(validation.collectionCount, 2);
  assert.equal(validation.totalDocuments, 3);

  const dryRun = await restoreBackupDryRun(sampleBackup);
  assert.equal(dryRun.success, true);
  assert.equal(dryRun.restoredCount, 3);
});

test("Backup Restoration: corrupt or invalid format fails validation cleanly", () => {
  assert.throws(() => validateBackupPayload("invalid-json"));
  assert.throws(() => validateBackupPayload({ schemaVersion: 0 }));
  assert.throws(() => validateBackupPayload({ schemaVersion: 1, createdAt: "invalid-date", collections: {} }));
  assert.throws(() => validateBackupPayload({
    schemaVersion: 1,
    createdAt: new Date().toISOString(),
    collections: {
      categories: [{ missing_id: true }]
    }
  }));
});
