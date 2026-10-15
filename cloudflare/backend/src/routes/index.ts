import type { App } from '../env';
import { registerPaidMediaRoutes } from './paid_media';

// Feature route modules. Each module applies its own auth middleware
// (requireUser / optionalUser / requireAdmin from ../auth) before its
// handlers. Registered before the SPA fallback in index.ts.
export function registerRoutes(app: App): void {
  registerPaidMediaRoutes(app);
}
