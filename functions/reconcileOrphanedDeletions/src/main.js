import { Client, Databases, Users } from 'node-appwrite';
import { reconcileOrphanedAuthDeletions } from './shared/delete_account_core.js';

export default async ({ req, res, log = console.log, error = console.error }) => {
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID;

  if (!endpoint || !projectId || !apiKey || !databaseId) {
    error('Missing required server configuration for reconcileOrphanedDeletions');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  const databases = new Databases(client);
  const users = new Users(client);

  log('Starting scheduled orphan deletion recovery scanner');

  const stats = await reconcileOrphanedAuthDeletions({
    databases,
    users,
    databaseId,
    log,
    error,
  });

  log(`Orphan deletion recovery completed. Scanned: ${stats.scanned}, Completed: ${stats.completed}, Failed: ${stats.failed}`);

  return res.json({
    ok: true,
    message: 'Orphan deletion recovery process completed',
    stats,
  });
};
