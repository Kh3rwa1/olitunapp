import type { Bindings } from '../src/env';

declare global {
  namespace Cloudflare {
    interface Env extends Bindings {
      TEST_SCHEMA_SQL: string;
    }
  }
}

export {};
