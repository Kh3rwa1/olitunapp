import { Client, Databases, ID, Query, Teams, Users } from 'node-appwrite';

const ADMIN_TEAM_ID = process.env.ADMIN_TEAM_ID || 'admins';
const DATABASE_ID = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
const AUDIT_COLLECTION_ID = 'admin_audit_logs';

function parseBody(req) {
  try {
    return JSON.parse(req.body || '{}');
  } catch (_) {
    return {};
  }
}

function json(res, status, payload) {
  return res.json(payload, status);
}

function requireConfig() {
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;

  if (!endpoint || !projectId || !apiKey) {
    throw new Error('Missing Appwrite function configuration.');
  }

  return { endpoint, projectId, apiKey };
}

function safeMembership(membership) {
  return {
    membershipId: membership.$id,
    userId: membership.userId,
    userName: membership.userName || '',
    userEmail: membership.userEmail || '',
    roles: membership.roles || [],
    joinedAt: membership.joined || membership.$createdAt || '',
    confirm: membership.confirm === true,
  };
}

function safeUser(user) {
  return {
    userId: user.$id,
    email: user.email || '',
    name: user.name || '',
    status: user.status === true,
    emailVerification: user.emailVerification === true,
    passwordUpdate: user.passwordUpdate || '',
    registration: user.registration || user.$createdAt || '',
  };
}

function validatePassword(password) {
  if (typeof password !== 'string' || password.length < 16) {
    return 'Password must be at least 16 characters.';
  }
  if (!/[a-z]/.test(password) || !/[A-Z]/.test(password) || !/[0-9]/.test(password)) {
    return 'Password must include lowercase, uppercase, and a number.';
  }
  return null;
}

async function userIsAdmin(users, userId) {
  try {
    const memberships = await users.listMemberships(userId);
    return memberships.memberships.some((membership) => membership.teamId === ADMIN_TEAM_ID);
  } catch (_) {
    return false;
  }
}

async function findUser(users, body) {
  const userId = String(body.userId || body.targetUserId || '').trim();
  if (userId) return users.get(userId);

  const email = String(body.email || body.targetEmail || '').trim().toLowerCase();
  if (!email) throw new Error('Provide an email address or user ID.');

  const result = await users.list({
    queries: [Query.equal('email', email)],
    total: false,
  });
  const exact = result.users.find((user) => String(user.email || '').toLowerCase() === email);
  if (!exact) throw new Error('No Appwrite user exists for that email.');
  return exact;
}

async function findAdminMembership(users, targetUserId) {
  const memberships = await users.listMemberships(targetUserId);
  return memberships.memberships.find((membership) => membership.teamId === ADMIN_TEAM_ID);
}

async function listAdmins(teams) {
  const team = await teams.get(ADMIN_TEAM_ID);
  const memberships = await teams.listMemberships(ADMIN_TEAM_ID, [Query.limit(100)], undefined, false);
  return {
    team: {
      teamId: team.$id,
      name: team.name,
      total: memberships.total,
    },
    admins: memberships.memberships.map(safeMembership),
  };
}

async function writeAudit(databases, actorUserId, action, targetId, metadata = {}) {
  try {
    await databases.createDocument(DATABASE_ID, AUDIT_COLLECTION_ID, ID.unique(), {
      actorUserId,
      action,
      targetType: 'admin_access',
      targetId,
      metadata,
      success: true,
      createdAt: new Date().toISOString(),
    });
  } catch (_) {
    // Audit logging should not block access repair operations.
  }
}

export default async ({ req, res, error }) => {
  if (req.method !== 'POST') {
    return json(res, 405, { ok: false, message: 'Method not allowed.' });
  }

  const actorUserId = req.headers['x-appwrite-user-id'];
  if (!actorUserId) {
    return json(res, 401, { ok: false, message: 'Authentication required.' });
  }

  const body = parseBody(req);
  const action = String(body.action || 'summary').trim();

  try {
    const { endpoint, projectId, apiKey } = requireConfig();
    const client = new Client().setEndpoint(endpoint).setProject(projectId).setKey(apiKey);
    const users = new Users(client);
    const teams = new Teams(client);
    const databases = new Databases(client);

    if (!(await userIsAdmin(users, actorUserId))) {
      return json(res, 403, { ok: false, message: 'Admin team membership required.' });
    }

    if (action === 'summary') {
      const summary = await listAdmins(teams);
      return json(res, 200, { ok: true, ...summary });
    }

    if (action === 'add_admin') {
      const target = await findUser(users, body);
      const existing = await findAdminMembership(users, target.$id);
      if (!existing) {
        await teams.createMembership(ADMIN_TEAM_ID, ['admin'], undefined, target.$id);
        await writeAudit(databases, actorUserId, 'admin_access_granted', target.$id, {
          email: target.email || '',
        });
      }
      const summary = await listAdmins(teams);
      return json(res, 200, {
        ok: true,
        changed: !existing,
        user: safeUser(target),
        ...summary,
      });
    }

    if (action === 'remove_admin') {
      const target = await findUser(users, body);
      const membership = await findAdminMembership(users, target.$id);
      if (!membership) {
        return json(res, 400, { ok: false, message: 'User is not in the admin team.' });
      }
      if (target.$id === actorUserId) {
        return json(res, 400, { ok: false, message: 'You cannot remove your own admin access here.' });
      }
      const summaryBefore = await listAdmins(teams);
      if (summaryBefore.admins.length <= 1) {
        return json(res, 400, { ok: false, message: 'At least one admin must remain.' });
      }
      await teams.deleteMembership(ADMIN_TEAM_ID, membership.$id);
      await writeAudit(databases, actorUserId, 'admin_access_revoked', target.$id, {
        email: target.email || '',
      });
      const summary = await listAdmins(teams);
      return json(res, 200, { ok: true, changed: true, ...summary });
    }

    if (action === 'reset_password') {
      const target = await findUser(users, body);
      const membership = await findAdminMembership(users, target.$id);
      if (!membership) {
        return json(res, 400, { ok: false, message: 'Only admin team member passwords can be reset here.' });
      }

      const password = String(body.password || body.newPassword || '');
      const passwordError = validatePassword(password);
      if (passwordError) {
        return json(res, 400, { ok: false, message: passwordError });
      }

      await users.updatePassword(target.$id, password);
      if (body.revokeSessions !== false) {
        await users.deleteSessions(target.$id);
      }
      await writeAudit(databases, actorUserId, 'admin_password_reset', target.$id, {
        email: target.email || '',
        sessionsRevoked: body.revokeSessions !== false,
      });
      const summary = await listAdmins(teams);
      return json(res, 200, {
        ok: true,
        changed: true,
        user: safeUser(target),
        ...summary,
      });
    }

    return json(res, 400, { ok: false, message: 'Unsupported admin access action.' });
  } catch (err) {
    error(`manageAdminAccess failed: ${err.message || String(err)}`);
    return json(res, 500, {
      ok: false,
      message: 'Admin access operation failed. Check function logs for details.',
    });
  }
};
