import type { App } from '../env';
import { registerAccountRoutes } from './account';
import { registerAnalyticsRoutes } from './analytics';
import { registerWaitlistRoutes } from './waitlist';

// Feature route modules. Each module applies its own auth middleware
// (requireUser / optionalUser / requireAdmin from ../auth) before its
// handlers. Registered before the SPA fallback in index.ts.
export function registerRoutes(app: App): void {
  registerAnalyticsRoutes(app);
  registerWaitlistRoutes(app);
  registerAccountRoutes(app);
}
