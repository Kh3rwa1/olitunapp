import type { App, Bindings } from '../env';
import { adminUserId, auditStatement, readJsonBody } from './admin_common';

// POST /api/v1/admin/access — port of the Appwrite `manageAdminAccess`
// function without an Appwrite server key. Calls go to the Appwrite Teams
// *client* API with the calling admin's own JWT, so:
// - summary works for every admin-team member;
// - remove_admin works when the caller holds the team `owner` role
//   (Appwrite answers 401 otherwise, surfaced as a 403);
// - add_admin and reset_password need server privileges (adding a member
//   without an email-invite round trip, changing another user's password),
//   so they answer 501 UNAVAILABLE and the admin uses the Appwrite Console.

const UNAVAILABLE_ACTIONS: Record<string, string> = {
  add_admin:
    'Adding admins is unavailable in the app: it needs an Appwrite server key. Add the user to the admin team in the Appwrite Console.',
  reset_password:
    "Resetting another admin's password is unavailable in the app: it needs an Appwrite server key. Use the Appwrite Console.",
};

type Membership = {
  membershipId: string;
  userId: string;
  userName: string;
  userEmail: string;
  roles: string[];
  joinedAt: string;
  confirm: boolean;
};

class TeamsError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}

function teamId(env: Bindings): string {
  return env.ADMIN_TEAM_ID || 'admins';
}

async function teamsFetch(env: Bindings, jwt: string, path: string, init: RequestInit = {}): Promise<any> {
  const endpoint = env.APPWRITE_ENDPOINT.replace(/\/+$/, '');
  let res: Response;
  try {
    res = await fetch(`${endpoint}${path}`, {
      ...init,
      headers: {
        'X-Appwrite-Project': env.APPWRITE_PROJECT_ID,
        'X-Appwrite-JWT': jwt,
        Accept: 'application/json',
        ...(init.headers || {}),
      },
    });
  } catch (_) {
    throw new TeamsError('Appwrite Teams is unreachable. Try again shortly.', 503);
  }
  if (res.status === 401 || res.status === 403) {
    throw new TeamsError('Your Appwrite account needs the owner role on the admin team for this action.', 403);
  }
  if (res.status === 404) throw new TeamsError('Admin team or membership not found.', 404);
  if (!res.ok) throw new TeamsError(`Appwrite Teams request failed (HTTP ${res.status}).`, 502);
  if (res.status === 204) return null;
  return res.json().catch(() => null);
}

function safeMembership(m: any): Membership {
  return {
    membershipId: String(m?.$id || ''),
    userId: String(m?.userId || ''),
    userName: String(m?.userName || ''),
    userEmail: String(m?.userEmail || ''),
    roles: Array.isArray(m?.roles) ? m.roles.map(String) : [],
    joinedAt: String(m?.joined || m?.$createdAt || ''),
    confirm: m?.confirm === true,
  };
}

export async function adminSummary(env: Bindings, jwt: string) {
  const id = encodeURIComponent(teamId(env));
  const limit = encodeURIComponent(JSON.stringify({ method: 'limit', values: [100] }));
  const [team, list] = await Promise.all([
    teamsFetch(env, jwt, `/teams/${id}`),
    teamsFetch(env, jwt, `/teams/${id}/memberships?queries[]=${limit}`),
  ]);
  const memberships: any[] = Array.isArray(list?.memberships) ? list.memberships : [];
  return {
    team: { teamId: String(team?.$id || teamId(env)), name: String(team?.name || ''), total: Number(list?.total ?? memberships.length) },
    admins: memberships.map(safeMembership),
  };
}

export function registerAdminAccessRoutes(app: App): void {
  app.post('/api/v1/admin/access', async (c) => {
    const body = await readJsonBody(c);
    if (!body) return c.json({ ok: false, message: 'Invalid JSON body.' }, 400);
    const action = typeof body.action === 'string' ? body.action.trim() : 'summary';
    const actor = adminUserId(c);
    const jwt = c.get('jwt') || '';

    if (UNAVAILABLE_ACTIONS[action]) {
      return c.json({ ok: false, error: 'UNAVAILABLE', message: UNAVAILABLE_ACTIONS[action] }, 501);
    }
    if (action !== 'summary' && action !== 'remove_admin') {
      return c.json({ ok: false, message: 'Unsupported admin access action.' }, 400);
    }
    if (!jwt) {
      return c.json({ ok: false, message: 'Admin access management needs a signed-in admin session.' }, 403);
    }

    try {
      if (action === 'summary') {
        return c.json({ ok: true, ...(await adminSummary(c.env, jwt)) });
      }

      const targetUserId = String(body.targetUserId || body.userId || '').trim();
      if (!targetUserId) return c.json({ ok: false, message: 'Provide the admin user ID to remove.' }, 400);
      if (targetUserId === actor) {
        return c.json({ ok: false, message: 'You cannot remove your own admin access here.' }, 400);
      }
      const before = await adminSummary(c.env, jwt);
      const membership = before.admins.find((m) => m.userId === targetUserId);
      if (!membership) return c.json({ ok: false, message: 'User is not in the admin team.' }, 400);
      if (before.admins.length <= 1) return c.json({ ok: false, message: 'At least one admin must remain.' }, 400);

      await teamsFetch(
        c.env,
        jwt,
        `/teams/${encodeURIComponent(teamId(c.env))}/memberships/${encodeURIComponent(membership.membershipId)}`,
        { method: 'DELETE' },
      );
      await auditStatement(c.env.DB, {
        actor,
        action: 'admin_access_revoked',
        targetId: targetUserId,
        details: { email: membership.userEmail, membershipId: membership.membershipId },
      }).run();
      return c.json({ ok: true, changed: true, ...(await adminSummary(c.env, jwt)) });
    } catch (err: any) {
      if (err instanceof TeamsError) return c.json({ ok: false, message: err.message }, err.status as any);
      console.error(`admin access ${action} failed: ${err?.message || err}`);
      return c.json({ ok: false, message: 'Admin access operation failed.' }, 500);
    }
  });
}
