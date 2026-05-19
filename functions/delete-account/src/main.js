import { Client, Users } from 'node-appwrite';

// DELETE-ACCOUNT FUNCTION
// ─────────────────────────────────────────────────────────────────────────────
// Permanently removes the calling user from Appwrite using the server-side
// Admin SDK.  The Flutter client cannot call Users.delete() directly — only
// the server SDK with an API key can do so.
//
// Required environment variables (set in Appwrite Console → Function → Settings):
//   APPWRITE_ENDPOINT   – e.g. https://sgp.cloud.appwrite.io/v1
//   APPWRITE_PROJECT_ID – your project ID
//   APPWRITE_API_KEY    – a server API key with "users.write" scope
// ─────────────────────────────────────────────────────────────────────────────

export default async ({ req, res, log, error }) => {
  // Only accept POST requests.
  if (req.method !== 'POST') {
    return res.json({ ok: false, message: 'Method not allowed' }, 405);
  }

  // The JWT of the calling user is forwarded by the Appwrite SDK automatically.
  // Appwrite sets req.headers['x-appwrite-user-id'] on authenticated calls.
  const userId = req.headers['x-appwrite-user-id'];
  if (!userId) {
    return res.json({ ok: false, message: 'Unauthenticated' }, 401);
  }

  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID;
  const apiKey = process.env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    error('Missing environment variables');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  const users = new Users(client);

  try {
    log(`Deleting user ${userId}`);
    await users.delete(userId);
    log(`User ${userId} deleted ✅`);
    return res.json({ ok: true });
  } catch (err) {
    error(`Failed to delete user ${userId}: ${err.message}`);
    return res.json({ ok: false, message: err.message }, 500);
  }
};
