import { describe, expect, it } from 'vitest';
import { call, callJson, env, insertCategory, insertLesson, makeUser, uid } from './helpers';

describe('public learner routes', () => {
  it('/lessons strips blocks from paid lessons but keeps free and preview ones', async () => {
    const free = await insertCategory({ unlockMode: 'free' });
    const paid = await insertCategory({ unlockMode: 'paid', priceInr: 99 });
    const freeLesson = await insertLesson(free);
    const paidLesson = await insertLesson(paid, { heroMediaUrl: 'https://x/secret.mp4', data: { secret: true } });
    const previewLesson = await insertLesson(paid, { isPreview: true });

    const { status, body, res } = await callJson('/api/v1/lessons');
    expect(status).toBe(200);
    expect(res.headers.get('cache-control')).toContain('public');
    const byId = new Map(body.lessons.map((l: any) => [l.id, l]));
    expect((byId.get(freeLesson) as any).blocks).toHaveLength(1);
    expect((byId.get(previewLesson) as any).blocks).toHaveLength(1);
    const locked: any = byId.get(paidLesson);
    expect(locked).toMatchObject({ blocks: [], isLocked: true });
    expect(locked.heroMediaUrl).toBeUndefined();
    expect(locked.data).toBeUndefined();
    expect(JSON.stringify(body)).not.toContain('https://x/secret.mp4');
  });

  it('/lessons/authorize lists paid lessons as locked for anonymous callers', async () => {
    const paid = await insertCategory({ unlockMode: 'paid', priceInr: 99 });
    const lessonId = await insertLesson(paid);
    const { body } = await callJson('/api/v1/lessons/authorize');
    expect(body.lessons.find((l: any) => l.id === lessonId).isLocked).toBe(true);
    const single = await callJson(`/api/v1/lessons/authorize?action=get_lesson&lessonId=${lessonId}`);
    expect(single.body.lesson.blocks).toEqual([]);
  });

  it('/categories lists active categories only', async () => {
    const active = await insertCategory();
    const inactive = await insertCategory({ isActive: false });
    const ids = (await callJson('/api/v1/categories')).body.categories.map((c: any) => c.id);
    expect(ids).toContain(active);
    expect(ids).not.toContain(inactive);
  });

  it('/content/:kind/:id returns an item and 404s unknown ids', async () => {
    const categoryId = await insertCategory();
    const found = await callJson(`/api/v1/content/category/${categoryId}`);
    expect(found.status).toBe(200);
    expect(found.body.item.id).toBe(categoryId);
    const missing = await callJson('/api/v1/content/category/does_not_exist');
    expect(missing.status).toBe(404);
    expect(missing.body.error).toBe('NOT_FOUND');
  });

  it('/content/:kind/:id refuses unknown kinds, including lessons', async () => {
    expect((await call('/api/v1/content/widget/1')).status).toBe(400);
    expect((await call('/api/v1/content/lesson/1')).status).toBe(400);
  });

  it('answers unknown API paths with a JSON 404', async () => {
    const { status, body } = await callJson('/api/v1/nope');
    expect(status).toBe(404);
    expect(body.error).toBe('NOT_FOUND');
  });

  it('health check is public', async () => {
    expect((await callJson('/health')).body.status).toBe('ok');
  });
});

describe('admin content CRUD', () => {
  it('round-trips a category and lesson to the learner routes', async () => {
    const admin = makeUser('admin');
    const categoryId = uid('cat');
    const lessonId = uid('lesson');

    const created = await callJson(`/api/v1/admin/content/categories/${categoryId}`, {
      method: 'PUT',
      as: admin,
      json: { titleLatin: 'Greetings', isActive: true, unlockMode: 'free', order: 3, $permissions: ['x'] },
    });
    expect(created.status).toBe(200);
    expect(created.body.created).toBe(true);
    expect(created.body.item.$permissions).toBeUndefined();

    await callJson(`/api/v1/admin/content/lessons/${lessonId}`, {
      method: 'PUT',
      as: admin,
      json: { categoryId, titleLatin: 'Hello', blocks: [{ type: 'text', text: 'johar' }] },
    });

    const category = await callJson(`/api/v1/content/category/${categoryId}`);
    expect(category.body.item).toMatchObject({ titleLatin: 'Greetings', unlockMode: 'free' });
    const lessons = (await callJson(`/api/v1/lessons?category_id=${categoryId}`)).body.lessons;
    expect(lessons).toHaveLength(1);
    expect(lessons[0].blocks).toEqual([{ type: 'text', text: 'johar' }]);

    // Update merges onto the stored document.
    const updated = await callJson(`/api/v1/admin/content/categories/${categoryId}`, {
      method: 'PUT',
      as: admin,
      json: { titleLatin: 'Greetings 2' },
    });
    expect(updated.body.created).toBe(false);
    expect(updated.body.item).toMatchObject({ titleLatin: 'Greetings 2', unlockMode: 'free', order: 3 });

    const audit = await env.DB.prepare('SELECT action, admin_user_id FROM admin_audit_logs WHERE target_id = ? ORDER BY timestamp').bind(`categories/${categoryId}`).all<any>();
    expect(audit.results.map((r) => r.action)).toEqual(['content.create', 'content.update']);
    expect(audit.results[0].admin_user_id).toBe(admin.id);

    const deleted = await callJson(`/api/v1/admin/content/categories/${categoryId}`, { method: 'DELETE', as: admin });
    expect(deleted.body.deleted).toBe(true);
    expect((await call(`/api/v1/content/category/${categoryId}`)).status).toBe(404);
    expect((await call(`/api/v1/admin/content/categories/${categoryId}`, { method: 'DELETE', as: admin })).status).toBe(404);
  });

  it('validates table, id and body', async () => {
    const admin = makeUser('admin');
    expect((await call('/api/v1/admin/content/users/x', { method: 'PUT', as: admin, json: {} })).status).toBe(400);
    expect((await call('/api/v1/admin/content/categories/a%20b', { method: 'PUT', as: admin, json: {} })).status).toBe(400);
    expect((await call('/api/v1/admin/content/categories/abc', { method: 'PUT', as: admin, json: { id: 'other' } })).status).toBe(400);
    expect((await call('/api/v1/admin/content/categories/abc', { method: 'PUT', as: admin, json: [1] })).status).toBe(400);
  });

  it('settings written by an admin are served by /settings', async () => {
    const admin = makeUser('admin');
    const key = uid('flag');
    const put = await callJson(`/api/v1/admin/settings/${key}`, { method: 'PUT', as: admin, json: { settingValue: 'on' } });
    expect(put.status).toBe(200);
    expect((await callJson('/api/v1/settings')).body.settings[key]).toBe('on');
    expect((await call(`/api/v1/admin/settings/${key}`, { method: 'PUT', as: admin, json: { settingValue: 1 } })).status).toBe(400);
  });
});

describe('content change feed', () => {
  it('reports admin writes after `since`, oldest first', async () => {
    const admin = makeUser('admin');
    const since = (await callJson('/api/v1/content/changes')).body.latest as number;
    const id = uid('word');
    const put = await callJson(`/api/v1/admin/content/words/${id}`, { method: 'PUT', as: admin, json: { wordLatin: 'dak' } });
    await callJson(`/api/v1/admin/content/words/${id}`, { method: 'DELETE', as: admin });

    const { body } = await callJson(`/api/v1/content/changes?since=${since}`);
    const mine = body.changes.filter((c: any) => c.id === id);
    expect(mine.map((c: any) => c.op)).toEqual(['upsert', 'delete']);
    expect(mine[0].seq).toBe(put.body.seq);
    expect(mine[0].table).toBe('words');
    expect(body.latest).toBeGreaterThanOrEqual(mine[1].seq);
  });

  it('pages 500 changes at a time', async () => {
    const since = (await callJson('/api/v1/content/changes')).body.latest as number;
    const at = new Date().toISOString();
    const prefix = uid('w');
    const stmts = Array.from({ length: 501 }, (_, i) =>
      env.DB.prepare('INSERT INTO content_changes (table_name, row_id, op, changed_at) VALUES (?, ?, ?, ?)').bind('words', `${prefix}_${i}`, 'upsert', at),
    );
    await env.DB.batch(stmts);

    const first = (await callJson(`/api/v1/content/changes?since=${since}`)).body;
    expect(first.changes).toHaveLength(500);
    expect(first.hasMore).toBe(true);
    const last = first.changes[499].seq;
    const second = (await callJson(`/api/v1/content/changes?since=${last}`)).body;
    expect(second.changes.length).toBeGreaterThanOrEqual(1);
    expect(second.changes.every((c: any) => c.seq > last)).toBe(true);
    const seen = new Set([...first.changes, ...second.changes].map((c: any) => c.id));
    for (let i = 0; i < 501; i++) expect(seen.has(`${prefix}_${i}`)).toBe(true);
  });

  it('rejects a non-numeric since', async () => {
    expect((await call('/api/v1/content/changes?since=-1')).status).toBe(400);
    expect((await call('/api/v1/content/changes?since=1%20OR%201=1')).status).toBe(400);
  });
});
