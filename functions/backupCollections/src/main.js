import { Client, Databases, Storage, ID, Query } from 'node-appwrite';
import { InputFile } from 'node-appwrite/file';

export const DATABASE_ID = process.env.OLITUN_APPWRITE_DATABASE_ID || process.env.APPWRITE_DATABASE_ID || 'olitun_db';
export const BACKUP_BUCKET_ID = process.env.ADMIN_BACKUP_BUCKET_ID || 'admin_backups';
export const CONTENT_COLLECTIONS = [
  'categories',
  'lessons',
  'quizzes',
  'letters',
  'numbers',
  'words',
  'sentences',
  'rhymes',
  'rhyme_categories',
  'banners',
  'app_settings',
  'bravo_messages',
  'badges',
  'mission_templates',
  'reward_messages',
  'quiz_feedback_messages',
  'gamification_config',
  'bakhed_lyrics',
  'bakhed_vocabulary',
  'bakhed_cultural_notes',
];

export function backupFileName(createdAt) {
  const stamp = createdAt.replaceAll(':', '-').replaceAll('.', '-');
  return `olitun-content-backup-${stamp}.json`;
}

function appwriteClient() {
  const endpoint =
    process.env.APPWRITE_FUNCTION_API_ENDPOINT ||
    process.env.OLITUN_APPWRITE_ENDPOINT;
  const projectId =
    process.env.APPWRITE_FUNCTION_PROJECT_ID ||
    process.env.OLITUN_APPWRITE_PROJECT_ID;
  const apiKey =
    process.env.OLITUN_APPWRITE_API_KEY ||
    process.env.APPWRITE_FUNCTION_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error('Missing Appwrite endpoint, project ID, or API key.');
  }

  return new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
}

export async function listAllDocuments(databases, databaseId, collectionId) {
  const documents = [];
  while (true) {
    const result = await databases.listDocuments(databaseId, collectionId, [
      Query.limit(100),
      Query.offset(documents.length),
    ]);
    documents.push(...result.documents);
    if (result.documents.length < 100) return documents;
  }
}

export default async ({ req, res, log, error }) => {
  try {
    const client = appwriteClient();
    const databases = new Databases(client);
    const storage = new Storage(client);

    const createdAt = new Date().toISOString();
    const fileName = backupFileName(createdAt);
    log(`Starting backup of core collections. File name: ${fileName}`);

    const collectionsData = {};
    const counts = {};

    for (const collectionId of CONTENT_COLLECTIONS) {
      log(`Backing up collection: ${collectionId}`);
      try {
        const docs = await listAllDocuments(databases, DATABASE_ID, collectionId);
        collectionsData[collectionId] = docs;
        counts[collectionId] = docs.length;
      } catch (err) {
        error(`Failed to backup collection ${collectionId}: ${err.message}`);
        collectionsData[collectionId] = [];
        counts[collectionId] = 0;
      }
    }

    const payload = {
      schemaVersion: 1,
      createdAt,
      databaseId: DATABASE_ID,
      collections: collectionsData,
      counts,
    };

    const file = InputFile.fromPlainText(
      JSON.stringify(payload, null, 2),
      fileName
    );

    log(`Uploading backup to bucket ${BACKUP_BUCKET_ID}...`);
    const uploadedFile = await storage.createFile(
      BACKUP_BUCKET_ID,
      ID.unique(),
      file
    );
    log(`Backup file uploaded successfully. File ID: ${uploadedFile.$id}`);

    // Manage Retention (keep last 12 backups)
    log(`Checking backups retention policy (retaining last 12 backups)...`);
    const filesList = await storage.listFiles(BACKUP_BUCKET_ID, [
      Query.limit(100),
      Query.orderDesc('$createdAt'),
    ]);

    const prunedFiles = [];
    if (filesList.files.length > 12) {
      const filesToDelete = filesList.files.slice(12);
      log(`Found ${filesList.files.length} backups. Pruning ${filesToDelete.length} oldest files.`);
      for (const f of filesToDelete) {
        log(`Deleting old backup: ${f.name} (${f.$id})`);
        try {
          await storage.deleteFile(BACKUP_BUCKET_ID, f.$id);
          prunedFiles.push({ id: f.$id, name: f.name });
        } catch (err) {
          error(`Failed to delete backup file ${f.$id}: ${err.message}`);
        }
      }
    }

    return res.json({
      ok: true,
      backup: {
        fileId: uploadedFile.$id,
        fileName,
        counts,
      },
      pruned: prunedFiles,
    });
  } catch (err) {
    const message = err?.message || String(err);
    error('Backup failed: ' + message);
    return res.json({
      ok: false,
      message: 'Weekly content backup failed: ' + message,
    }, 500);
  }
};
