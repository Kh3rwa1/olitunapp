import { describe, expect, it } from 'vitest';
import { call, callJson, env, grantPurchase, hmacHex, insertCategory, insertLesson, makeUser, outbound, uid } from './helpers';

const KEY_SECRET = 'rzp_test_secret';
const WEBHOOK_SECRET = 'rzp_webhook_secret';

async function createOrder(user: { jwt: string }, categoryId: string, extra: Record<string, unknown> = {}) {
  return callJson('/api/v1/payments/order', { as: user, json: { categoryId, ...extra } });
}

async function paidCategory(priceInr = 199) {
  return insertCategory({ unlockMode: 'paid', priceInr });
}

async function capturedPayment(orderId: string, amount: number, overrides: Record<string, unknown> = {}) {
  const paymentId = uid('pay');
  outbound.razorpayPayments.set(paymentId, { id: paymentId, order_id: orderId, amount, currency: 'INR', status: 'captured', ...overrides } as any);
  return paymentId;
}

async function entitlements(user: { jwt: string }) {
  return (await callJson('/api/v1/payments/entitlements', { as: user })).body.categoryIds as string[];
}

describe('POST /payments/order', () => {
  it('charges the server-side price and ignores a client amount', async () => {
    const user = makeUser();
    const categoryId = await paidCategory(249);
    const { status, body } = await createOrder(user, categoryId, { amount: 100, priceInr: 1 });
    expect(status).toBe(200);
    expect(body.amount).toBe(24900);
    expect(body.isDuplicateRetry).toBe(false);
    const sent = JSON.parse(outbound.callsTo('razorpay.test/v1/orders')[0].body);
    expect(sent.amount).toBe(24900);
    expect(sent.notes.userId).toBe(user.id);
    const row = await env.DB.prepare('SELECT user_id, amount, status FROM payment_orders WHERE order_id = ?').bind(body.orderId).first<any>();
    expect(row).toMatchObject({ user_id: user.id, amount: 24900, status: 'created' });
  });

  it('reuses a recent unpaid order instead of creating another', async () => {
    const user = makeUser();
    const categoryId = await paidCategory();
    const first = await createOrder(user, categoryId);
    const second = await createOrder(user, categoryId);
    expect(second.body.orderId).toBe(first.body.orderId);
    expect(second.body.isDuplicateRetry).toBe(true);
    expect(outbound.callsTo('razorpay.test/v1/orders')).toHaveLength(1);
  });

  it('refuses free categories', async () => {
    const { status } = await createOrder(makeUser(), await insertCategory({ unlockMode: 'free', priceInr: 99 }));
    expect(status).toBe(400);
  });

  it('refuses a paid category without a valid price', async () => {
    const { status } = await createOrder(makeUser(), await insertCategory({ unlockMode: 'paid', priceInr: null }));
    expect(status).toBe(400);
  });

  it('404s unknown or inactive categories', async () => {
    expect((await createOrder(makeUser(), 'cat_missing')).status).toBe(404);
    const inactive = await insertCategory({ unlockMode: 'paid', priceInr: 99, isActive: false });
    expect((await createOrder(makeUser(), inactive)).status).toBe(404);
  });

  it('refuses a category the user already owns', async () => {
    const user = makeUser();
    const categoryId = await paidCategory();
    await grantPurchase(user.id, categoryId);
    expect((await createOrder(user, categoryId)).status).toBe(409);
    expect(outbound.callsTo('razorpay.test')).toHaveLength(0);
  });

  it('fails closed without Razorpay credentials', async () => {
    const { status } = await callJson('/api/v1/payments/order', {
      as: makeUser(),
      json: { categoryId: await paidCategory() },
      env: { RAZORPAY_KEY_SECRET: '' },
    });
    expect(status).toBe(503);
  });
});

describe('POST /payments/verify', () => {
  async function setup(price = 199) {
    const user = makeUser();
    const categoryId = await paidCategory(price);
    const order = (await createOrder(user, categoryId)).body;
    return { user, categoryId, orderId: order.orderId as string, amount: order.amount as number };
  }

  const verify = async (user: { jwt: string }, orderId: string, paymentId: string, signature?: string) =>
    callJson('/api/v1/payments/verify', {
      as: user,
      json: { orderId, paymentId, signature: signature ?? (await hmacHex(KEY_SECRET, `${orderId}|${paymentId}`)) },
    });

  it('rejects a bad signature', async () => {
    const { user, orderId, amount, categoryId } = await setup();
    const paymentId = await capturedPayment(orderId, amount);
    const { status } = await verify(user, orderId, paymentId, 'deadbeef'.repeat(8));
    expect(status).toBe(400);
    expect(await entitlements(user)).not.toContain(categoryId);
  });

  it("refuses another user's order", async () => {
    const { orderId, amount, categoryId } = await setup();
    const attacker = makeUser();
    const paymentId = await capturedPayment(orderId, amount);
    const { status } = await verify(attacker, orderId, paymentId);
    expect(status).toBe(404);
    expect(await entitlements(attacker)).not.toContain(categoryId);
  });

  it('refuses an underpaid payment', async () => {
    const { user, orderId, amount } = await setup();
    const paymentId = await capturedPayment(orderId, amount - 100);
    expect((await verify(user, orderId, paymentId)).status).toBe(400);
  });

  it('refuses a payment that is not captured', async () => {
    const { user, orderId, amount } = await setup();
    const paymentId = await capturedPayment(orderId, amount, { status: 'authorized' });
    const { status, body } = await verify(user, orderId, paymentId);
    expect(status).toBe(400);
    expect(body.message).toMatch(/not captured/);
  });

  it('refuses a payment that belongs to a different order', async () => {
    const { user, orderId, amount } = await setup();
    const paymentId = await capturedPayment('order_someone_else', amount);
    expect((await verify(user, orderId, paymentId)).status).toBe(400);
  });

  it('unlocks the category for a valid captured payment and is idempotent on retry', async () => {
    const { user, orderId, amount, categoryId } = await setup();
    const paymentId = await capturedPayment(orderId, amount);
    const first = await verify(user, orderId, paymentId);
    expect(first.status).toBe(200);
    expect(first.body.verified).toBe(true);
    expect(await entitlements(user)).toContain(categoryId);

    const retry = await verify(user, orderId, paymentId);
    expect(retry.status).toBe(200);
    expect(retry.body.isRetry).toBe(true);

    const otherPayment = await capturedPayment(orderId, amount);
    expect((await verify(user, orderId, otherPayment)).status).toBe(409);

    const purchases = await env.DB.prepare('SELECT COUNT(*) AS n FROM course_purchases WHERE user_id = ? AND category_id = ?').bind(user.id, categoryId).first<any>();
    expect(purchases.n).toBe(1);
  });

  it('unlocks paid lesson bodies only after purchase', async () => {
    const { user, orderId, amount, categoryId } = await setup();
    const lessonId = await insertLesson(categoryId);
    const before = await callJson(`/api/v1/lessons/authorize?action=get_lesson&lessonId=${lessonId}`, { as: user });
    expect(before.body.locked).toBe(true);
    expect(before.body.lesson.blocks).toEqual([]);

    await verify(user, orderId, await capturedPayment(orderId, amount));
    const after = await callJson(`/api/v1/lessons/authorize?action=get_lesson&lessonId=${lessonId}`, { as: user });
    expect(after.body.locked).toBe(false);
    expect(after.body.lesson.blocks).toHaveLength(1);
  });
});

describe('POST /payments/webhook', () => {
  async function orderFor(price = 199) {
    const user = makeUser();
    const categoryId = await paidCategory(price);
    const order = (await createOrder(user, categoryId)).body;
    return { user, categoryId, orderId: order.orderId as string, amount: order.amount as number };
  }

  const event = (orderId: string, amount: number, paymentId = uid('pay')) =>
    JSON.stringify({ event: 'payment.captured', payload: { payment: { entity: { id: paymentId, order_id: orderId, amount, currency: 'INR' } } } });

  const send = async (raw: string, signature?: string | null) =>
    call('/api/v1/payments/webhook', {
      method: 'POST',
      body: raw,
      headers: signature === null ? {} : { 'x-razorpay-signature': signature ?? (await hmacHex(WEBHOOK_SECRET, raw)) },
    });

  it('rejects an unsigned webhook', async () => {
    const { user, orderId, amount, categoryId } = await orderFor();
    expect((await send(event(orderId, amount), null)).status).toBe(401);
    expect(await entitlements(user)).not.toContain(categoryId);
  });

  it('rejects a webhook signed with the wrong secret', async () => {
    const { orderId, amount } = await orderFor();
    const raw = event(orderId, amount);
    expect((await send(raw, await hmacHex('wrong-secret', raw))).status).toBe(401);
  });

  it('rejects a body altered after signing', async () => {
    const { orderId, amount } = await orderFor();
    const signature = await hmacHex(WEBHOOK_SECRET, event(orderId, amount, 'pay_a'));
    expect((await send(event(orderId, amount, 'pay_b'), signature)).status).toBe(401);
  });

  it('unlocks on a correctly signed capture for the full amount', async () => {
    const { user, orderId, amount, categoryId } = await orderFor();
    const res = await send(event(orderId, amount));
    expect(res.status).toBe(200);
    expect(await entitlements(user)).toContain(categoryId);
  });

  it('ignores an underpaid capture', async () => {
    const { user, orderId, amount, categoryId } = await orderFor();
    expect((await send(event(orderId, amount - 1))).status).toBe(200);
    expect(await entitlements(user)).not.toContain(categoryId);
  });

  it('does not restore a refunded purchase on redelivery', async () => {
    const { user, orderId, amount, categoryId } = await orderFor();
    const raw = event(orderId, amount);
    await send(raw);
    await env.DB.prepare("UPDATE course_purchases SET status = 'refunded' WHERE user_id = ? AND category_id = ?").bind(user.id, categoryId).run();
    await send(raw);
    expect(await entitlements(user)).not.toContain(categoryId);
  });

  it('503s when the webhook secret is not configured', async () => {
    const res = await call('/api/v1/payments/webhook', { method: 'POST', body: '{}', env: { RAZORPAY_WEBHOOK_SECRET: '' } });
    expect(res.status).toBe(503);
  });
});

describe('entitlements', () => {
  it('sync is read-only and ignores category ids in the body', async () => {
    const user = makeUser();
    const owned = await paidCategory();
    const wanted = await paidCategory();
    await grantPurchase(user.id, owned);
    const { status, body } = await callJson('/api/v1/payments/entitlements/sync', {
      as: user,
      json: { userId: user.id, categoryIds: [wanted], categoryId: wanted },
    });
    expect(status).toBe(200);
    expect(body.categoryIds).toEqual([owned]);
    expect(await entitlements(user)).toEqual([owned]);
  });

  it('only counts completed or verified purchases', async () => {
    const user = makeUser();
    const refunded = await paidCategory();
    const verified = await paidCategory();
    await grantPurchase(user.id, refunded, 'refunded');
    await grantPurchase(user.id, verified, 'verified');
    expect(await entitlements(user)).toEqual([verified]);
  });
});
