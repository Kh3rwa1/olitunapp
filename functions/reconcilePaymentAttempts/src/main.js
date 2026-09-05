import { Client, Databases } from 'node-appwrite';
import { reconcileStuckPaymentAttempts } from './shared/payment_reconcile.js';
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

  const databases = withPaymentStateGuard(new Databases(client));

  log('Starting scheduled payment attempt reconciliation');

  const stats = await reconcileStuckPaymentAttempts({
    databases,
    databaseId,
    razorpayKeyId,
    razorpayKeySecret,
    log,
    error,
  });

  log(`Reconciliation completed. Scanned: ${stats.scanned}, Reconciled: ${stats.reconciled}, Failed: ${stats.failed}`);

  return res.json({
    ok: true,
    message: 'Reconciliation process completed',
    stats,
  });
};
