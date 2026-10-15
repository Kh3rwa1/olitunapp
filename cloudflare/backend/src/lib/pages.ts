

// Helper to proxy non-API web traffic to Cloudflare Pages SPA
export async function proxyToPages(c: any) {
  const url = new URL(c.req.url);
  let pathname = url.pathname;
  if (pathname.startsWith('/admin/') && /\.(js|mjs|wasm|png|jpg|jpeg|gif|svg|json|ttf|woff|woff2|ico|css|map)$/i.test(pathname)) {
    pathname = pathname.replace(/^\/admin/, '');
  }
  const pagesUrl = new URL(pathname + url.search, 'https://olitunapp.pages.dev');
  try {
    let upstream = await fetch(pagesUrl.toString(), {
      method: c.req.method,
      headers: c.req.raw.headers,
      body: c.req.method !== 'GET' && c.req.method !== 'HEAD' ? c.req.raw.body : undefined,
    });
    // If upstream Pages returned 404 on an SPA route (no file extension), serve index.html with 200
    if (upstream.status === 404 && !/\.[a-zA-Z0-9]+$/.test(pathname)) {
      const indexUrl = new URL('/index.html', 'https://olitunapp.pages.dev');
      upstream = await fetch(indexUrl.toString(), {
        method: c.req.method,
        headers: c.req.raw.headers,
      });
    }
    return upstream;
  } catch (err: any) {
    return c.text('Gateway Error: ' + (err.message || 'Unknown error'), 502);
  }
}
