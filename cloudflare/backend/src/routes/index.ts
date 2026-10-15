import type { App } from '../env';
import { registerRootRoutes } from './root';
import { registerContentRoutes } from './content';
import { registerTranslateRoutes } from './translate';
import { registerMistakeRoutes } from './mistakes';
import { registerBakhedProgressRoutes } from './bakhed_progress';
import { registerGamificationSummaryRoutes } from './gamification_summary';
import { registerLessonAuthorizeRoutes } from './lessons_authorize';
import { registerPaymentRoutes } from './payments';
import { registerVoiceRoutes } from './voice';
import { registerStudioRoutes } from './studio';
import { registerAdminJobRoutes } from './admin_jobs';
import { registerPaidMediaRoutes } from './paid_media';
import { registerReviewRoutes } from './review';
import { registerAccountRoutes } from './account';
import { registerAnalyticsRoutes } from './analytics';
import { registerWaitlistRoutes } from './waitlist';
import { registerLearnerContentRoutes } from './learner_content';
import { registerMediaRoutes } from './media';
import { registerGamificationCmsRoutes } from './gamification_cms';
import { registerAdminContentRoutes } from './admin_content';
import { registerAdminPurchaseRoutes } from './admin_purchases';
import { registerAdminMaintenanceRoutes } from './admin_maintenance';
import { registerAdminAccessRoutes } from './admin_access';
import { registerAdminReviewRoutes } from './admin_review';
import { registerAdminDashboardRoutes } from './admin_dashboard';

// All route modules. Registration order matters (Hono matches in order) and
// mirrors the original single-file layout: the core API routes first, then the
// feature modules. Auth for the core routes is registered in index.ts before
// this runs; feature modules apply their own auth middleware (requireUser /
// optionalUser / requireAdmin from ../auth) before their handlers.
// Registered before the SPA fallback in index.ts.
export function registerRoutes(app: App): void {
  registerRootRoutes(app);
  registerContentRoutes(app);
  registerTranslateRoutes(app);
  registerMistakeRoutes(app);
  registerBakhedProgressRoutes(app);
  registerGamificationSummaryRoutes(app);
  registerLessonAuthorizeRoutes(app);
  registerPaymentRoutes(app);
  registerVoiceRoutes(app);
  registerStudioRoutes(app);
  registerAdminJobRoutes(app);
  registerPaidMediaRoutes(app);
  registerReviewRoutes(app);
  registerAnalyticsRoutes(app);
  registerWaitlistRoutes(app);
  registerAccountRoutes(app);
  registerLearnerContentRoutes(app);
  registerMediaRoutes(app);
  registerGamificationCmsRoutes(app);
  registerAdminContentRoutes(app);
  registerAdminPurchaseRoutes(app);
  registerAdminMaintenanceRoutes(app);
  registerAdminAccessRoutes(app);
  registerAdminReviewRoutes(app);
  registerAdminDashboardRoutes(app);
}
