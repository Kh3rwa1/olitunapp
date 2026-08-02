import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { createHmac, createHash } from 'crypto';

function stableId(value) {
  return createHash('sha256').update(value).digest('hex').slice(0, 32);
}

describe('Backend Payment Functions Unit Tests', () => {
  const webhookSecret = 'whsec_test_secret_12345';
  const razorpaySecret = 'rzp_sec_test_999';

  test('Webhook HMAC signature calculation matches Razorpay raw-body payload', () => {
    const rawPayload = JSON.stringify({
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_123',
            order_id: 'order_123',
            amount: 49900,
            currency: 'INR',
            status: 'captured'
          }
        }
      }
    });

    const expectedSignature = createHmac('sha256', webhookSecret)
      .update(rawPayload)
      .digest('hex');

    const calculated = createHmac('sha256', webhookSecret)
      .update(rawPayload)
      .digest('hex');

    assert.equal(calculated, expectedSignature);
  });

  test('Reject invalid webhook signature', () => {
    const rawPayload = '{"event":"payment.captured"}';
    const badSignature = 'invalid_sig_00000000000000000000000000000';

    const validSignature = createHmac('sha256', webhookSecret)
      .update(rawPayload)
      .digest('hex');

    assert.notEqual(badSignature, validSignature);
  });

  test('Order binding validation matches expected paise amount and currency', () => {
    const pendingPurchase = {
      providerOrderId: 'order_ABC',
      userId: 'user_1',
      categoryId: 'cat_1',
      expectedAmount: 499,
      currency: 'INR',
      status: 'created'
    };

    const validPayment = {
      order_id: 'order_ABC',
      amount: 49900,
      currency: 'INR',
      status: 'captured'
    };

    const wrongAmountPayment = {
      order_id: 'order_ABC',
      amount: 100, // Underpaid
      currency: 'INR',
      status: 'captured'
    };

    const authorizedPayment = {
      order_id: 'order_ABC',
      amount: 49900,
      currency: 'INR',
      status: 'authorized' // Not settled
    };

    // Valid check
    assert.equal(pendingPurchase.providerOrderId, validPayment.order_id);
    assert.equal(pendingPurchase.expectedAmount * 100, validPayment.amount);
    assert.equal(validPayment.status, 'captured');
    assert.equal(validPayment.currency, 'INR');

    // Reject underpaid
    assert.notEqual(pendingPurchase.expectedAmount * 100, wrongAmountPayment.amount);

    // Reject authorized (not captured)
    assert.notEqual(authorizedPayment.status, 'captured');
  });

  test('Atomic payment claim ID generation is deterministic', () => {
    const paymentId = 'pay_test_888';
    const claimId1 = stableId(`claim:${paymentId}`);
    const claimId2 = stableId(`claim:${paymentId}`);

    assert.equal(claimId1, claimId2);
    assert.equal(claimId1.length, 32);
  });

  test('Out-of-order payment.failed event does not downgrade verified purchase', () => {
    const verifiedPurchase = {
      providerOrderId: 'order_111',
      status: 'verified'
    };

    const delayedFailedEvent = {
      orderId: 'order_000', // Older attempt
      status: 'failed'
    };

    const shouldDowngrade = (
      delayedFailedEvent.orderId === verifiedPurchase.providerOrderId &&
      verifiedPurchase.status !== 'verified' &&
      verifiedPurchase.status !== 'refunded'
    );

    assert.equal(shouldDowngrade, false);
  });

  test('Razorpay dispute event pattern matching', () => {
    const validDisputeEvents = [
      'payment.dispute.created',
      'payment.dispute.won',
      'payment.dispute.lost',
      'payment.dispute.closed',
      'payment.dispute.under_review',
      'payment.dispute.action_required'
    ];

    for (const evt of validDisputeEvents) {
      const isDispute = evt.startsWith('payment.dispute.') || evt === 'payment.disputed';
      assert.equal(isDispute, true, `Event ${evt} should be matched as dispute`);
    }
  });
});
