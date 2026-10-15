

// Helper for edge-cached JSON responses (reduces database reads to practically zero)
// Content is now edited through the admin CMS, so lists must not stay stale
// for long; clients also poll /content/changes for immediate refreshes.
export const cachedJson = (c: any, data: any, maxAge = 300) => {
  return c.json(data, 200, {
    'Cache-Control': `public, max-age=${maxAge}, stale-while-revalidate=3600`,
  });
};
