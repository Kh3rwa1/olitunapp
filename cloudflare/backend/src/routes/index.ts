import type { App } from '../env';
import { registerPaidMediaRoutes } from './paid_media';
import { registerReviewRoutes } from './review';
import { registerAccountRoutes } from './account';
import { registerAnalyticsRoutes } from './analytics';
import { registerWaitlistRoutes } from './waitlist';
import { registerLearnerContentRoutes } from './learner_content';
import { registerMediaRoutes } from './media';

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
  registerMediaRoutes(app);
}
