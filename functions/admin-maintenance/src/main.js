import {
  Client,
  Databases,
  ID,
  Query,
  Storage,
  Users,
} from 'node-appwrite';
import { InputFile } from 'node-appwrite/file';

export const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
export const ADMIN_TEAM_ID = process.env.ADMIN_TEAM_ID || 'admins';
export const BACKUP_BUCKET_ID =
  process.env.ADMIN_BACKUP_BUCKET_ID || 'admin_backups';
export const CONTENT_COLLECTIONS = [
  'quizzes',
  'sentences',
  'words',
  'numbers',
  'letters',
  'lessons',
  'categories',
];

const ACTIONS = new Set(['backup_content', 'wipe_content']);

export function parseBody(body) {
  if (!body) return {};
  if (typeof body === 'object') return body;
  return JSON.parse(body);
}

export function requireConfig(env = process.env) {
  const endpoint = env.APPWRITE_FUNCTION_API_ENDPOINT || env.APPWRITE_ENDPOINT;
  const projectId = env.APPWRITE_FUNCTION_PROJECT_ID || env.APPWRITE_PROJECT_ID;
  const apiKey = env.APPWRITE_FUNCTION_API_KEY || env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error(
      'Missing Appwrite function configuration: endpoint, project, or API key.',
    );
  }

  return { endpoint, projectId, apiKey };
}

export function validateRequest({ method, userId, body }) {
  if (method !== 'POST') {
    return { status: 405, message: 'Method not allowed.' };
  }

  if (!userId) {
    return { status: 401, message: 'Authentication required.' };
  }

  if (!ACTIONS.has(body.action)) {
    return {
      status: 400,
      message: 'Unsupported admin maintenance action.',
    };
  }

  if (body.action === 'wipe_content' && body.confirmation !== 'WIPE ALL') {
    return { status: 400, message: 'Invalid confirmation phrase.' };
  }

  return null;
}

export async function userIsAdmin(users, userId) {
  try {
    const memberships = await users.listMemberships(userId);
    return memberships.memberships.some(
      (membership) => membership.teamId === ADMIN_TEAM_ID,
    );
  } catch {
    return false;
  }
}

export async function listAllDocuments(databases, collectionId) {
  const documents = [];

  while (true) {
    const result = await databases.listDocuments(DATABASE_ID, collectionId, [
      Query.limit(100),
      Query.offset(documents.length),
    ]);

    documents.push(...result.documents);
    if (result.documents.length < 100) return documents;
  }
}

export async function buildBackupPayload(databases, actorUserId, createdAt) {
  const collections = {};
  const counts = {};

  for (const collectionId of CONTENT_COLLECTIONS) {
    const documents = await listAllDocuments(databases, collectionId);
    collections[collectionId] = documents;
    counts[collectionId] = documents.length;
  }

  return {
    schemaVersion: 1,
    createdAt,
    actorUserId,
    databaseId: DATABASE_ID,
    collections,
    counts,
  };
}

export function backupFileName(createdAt) {
  const stamp = createdAt.replaceAll(':', '-').replaceAll('.', '-');
  return `olitun-content-backup-${stamp}.json`;
}

export async function createContentBackup({
  databases,
  storage,
  actorUserId,
  createdAt = new Date().toISOString(),
}) {
  const payload = await buildBackupPayload(databases, actorUserId, createdAt);
  const fileName = backupFileName(createdAt);
  const file = InputFile.fromPlainText(
    JSON.stringify(payload, null, 2),
    fileName,
  );
  const uploaded = await storage.createFile(
    BACKUP_BUCKET_ID,
    ID.unique(),
    file,
  );

  return {
    bucketId: BACKUP_BUCKET_ID,
    fileId: uploaded.$id,
    fileName,
    counts: payload.counts,
  };
}

export async function deleteCollectionDocuments(databases, collectionId) {
  let deleted = 0;

  while (true) {
    const result = await databases.listDocuments(DATABASE_ID, collectionId, [
      Query.limit(100),
    ]);

    if (result.documents.length === 0) {
      return deleted;
    }

    for (const document of result.documents) {
      await databases.deleteDocument(DATABASE_ID, collectionId, document.$id);
      deleted += 1;
    }
  }
}

function json(res, status, payload) {
  return res.json(payload, status);
}

export default async ({ req, res, log, error }) => {
  try {
    const body = parseBody(req.body);
    const userId = req.headers['x-appwrite-user-id'];
    const invalid = validateRequest({ method: req.method, userId, body });
    if (invalid) {
      return json(res, invalid.status, {
        success: false,
        message: invalid.message,
      });
    }

    const { endpoint, projectId, apiKey } = requireConfig();
    const client = new Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey);
    const users = new Users(client);

    if (!(await userIsAdmin(users, userId))) {
      return json(res, 403, {
        success: false,
        message: 'Admin team membership required.',
      });
    }

    const databases = new Databases(client);
    const storage = new Storage(client);
    const backup = await createContentBackup({
      databases,
      storage,
      actorUserId: userId,
    });

    if (body.action === 'backup_content') {
      log(
        `Admin maintenance backup_content completed by ${userId}: ${backup.fileId}.`,
      );
      return json(res, 200, {
        success: true,
        backup,
      });
    }

    const deleted = {};
    for (const collectionId of CONTENT_COLLECTIONS) {
      deleted[collectionId] = await deleteCollectionDocuments(
        databases,
        collectionId,
      );
    }

    log(
      `Admin maintenance wipe_content completed by ${userId}; backup ${backup.fileId}.`,
    );
    return json(res, 200, {
      success: true,
      backup,
      deleted,
    });
  } catch (err) {
    error(err.message || String(err));
    return json(res, 500, {
      success: false,
      message: 'Admin maintenance failed.',
    });
  }
};
