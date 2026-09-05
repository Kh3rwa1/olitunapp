import { Client, Databases } from 'node-appwrite';
import { reconcileStuckPaymentAttempts, reconcileDisputedPurchases } from './shared/payment_reconcile.js';
import { withPaymentStateGuard } from './shared/payment_state.js';

export default async ({ req, res, log = console.log, error = console.error }) => {
  const endpoint = process.env.APPWRITE_FUNCTION_API_ENDPOINT || process.env.APPWRITE_ENDPOINT;
  const projectId = process.env.APPWRITE_FUNCTION_PROJECT_ID || process.env.APPWRITE_PROJECT_ID;
  const apiKey = process.env.APPWRITE_FUNCTION_API_KEY || process.env.APPWRITE_API_KEY;
  const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
  const razorpayKeyId = process.env.RAZORPAY_KEY_ID;
  const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!endpoint || !projectId || !apiKey) {
    error('Missing Appwrite server configuration');
    return res.json({ ok: false, message: 'Server misconfiguration' }, 500);
  }

  const client = new Client()
    .setEndpoint(endpoint)
    .setProject(projectId)
    .setKey(apiKey);

  const rawDatabases = new Databases(client);
  const databases = withPaymentStateGuard(rawDatabases);
  const disputeDatabases = withPaymentStateGuard(rawDatabases, { event: 'reconcile.dispute' });

  log('Starting scheduled payment attempt and dispute reconciliation');

  const attemptStats = await reconcileStuckPaymentAttempts({
    databases,
    databaseId,
    razorpayKeyId,
    razorpayKeySecret,
    log,
    error,
  });

  const disputeStats = await reconcileDisputedPurchases({
    databases: disputeDatabases,
    databaseId,
    razorpayKeyId,
    razorpayKeySecret,
    log,
    error,
  });

  const combinedStats = {
    attempts: attemptStats,
    disputes: disputeStats,
    scanned: attemptStats.scanned + disputeStats.scanned,
    reconciled: attemptStats.reconciled + disputeStats.won + disputeStats.lost,
    failed: attemptStats.failed + disputeStats.failed,
  };

  log(`Reconciliation completed. Attempts: scanned ${attemptStats.scanned}, reconciled ${attemptStats.reconciled}, failed ${attemptStats.failed}. Disputes: scanned ${disputeStats.scanned}, won ${disputeStats.won}, lost ${disputeStats.lost}, pending ${disputeStats.pending}, failed ${disputeStats.failed}`);

  return res.json({
    ok: true,
    message: 'Reconciliation process completed',
    stats: combinedStats,
  });
};
