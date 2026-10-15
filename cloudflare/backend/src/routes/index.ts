import type { App } from '../env';
import { registerPaidMediaRoutes } from './paid_media';
import { registerReviewRoutes } from './review';
import { registerAccountRoutes } from './account';
import { registerAnalyticsRoutes } from './analytics';
import { registerWaitlistRoutes } from './waitlist';
import { registerLearnerContentRoutes } from './learner_content';
import { registerAdminPurchaseRoutes } from './admin_purchases';
import { registerAdminMaintenanceRoutes } from './admin_maintenance';
import { registerAdminAccessRoutes } from './admin_access';
import { registerAdminReviewRoutes } from './admin_review';
import { registerAdminDashboardRoutes } from './admin_dashboard';
import { registerContentChangesRoutes } from './content_changes';

// Feature route modules. Each module applies its own auth middleware
// (requireUser / optionalUser / requireAdmin from ../auth) before its
// handlers. Registered before the SPA fallback in index.ts.
export function registerRoutes(app: App): void {
  registerPaidMediaRoutes(app);
  registerReviewRoutes(app);
  registerAnalyticsRoutes(app);
  registerWaitlistRoutes(app);
  registerAccountRoutes(app);
  registerLearnerContentRoutes(app);
  registerAdminPurchaseRoutes(app);
  registerAdminMaintenanceRoutes(app);
  registerAdminAccessRoutes(app);
  registerAdminReviewRoutes(app);
  registerAdminDashboardRoutes(app);
  registerContentChangesRoutes(app);
}
