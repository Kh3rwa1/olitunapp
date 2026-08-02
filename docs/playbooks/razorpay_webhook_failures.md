# Operational Playbook: Razorpay Webhook & Verification Failure Recovery

## Trigger Conditions
- Webhook signature verification failure alert.
- Customer payment succeeds on Razorpay dashboard but course remains locked in app.

## Incident Response Steps
1. **Locate Payment Document**:
   - Query `course_purchases` collection in Appwrite using `providerOrderId` or `userId`.
   - Inspect purchase status (`created`, `pending`, `verified`, `failed`).
2. **Re-Verify Payment via Appwrite Function**:
   - Execute `verifyCoursePurchase` Appwrite server function manually with `razorpayOrderId` and `razorpayPaymentId`.
   - The function queries `https://api.razorpay.com/v1/payments/{paymentId}` using basic auth server secrets, confirms `status === 'captured'`, validates `paidAmount >= expectedAmount`, and updates purchase status to `verified`.
3. **Handle Edge Cases**:
   - **Payment Amount Mismatch**: If `paidAmount < expectedAmount`, flag purchase status as `disputed` and initiate automatic or manual refund via Razorpay Dashboard.
   - **Duplicate Webhook Replays**: Confirm function returns `ok: true` without creating duplicate records.
4. **Notify Customer**:
   - Trigger user entitlement cache invalidation (`entitlements:production:{userId}`) so course unlocks seamlessly upon next app open.
