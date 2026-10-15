// Parses web/_headers (Cloudflare Pages) into { path: { header: value } }.
// Not a test file itself; imported by the *_test.mjs files beside it.
import fs from 'node:fs';

export const headersPath = new URL('../../web/_headers', import.meta.url);

export function readPagesHeaders() {
  const rules = {};
  let current = null;
  for (const raw of fs.readFileSync(headersPath, 'utf8').split('\n')) {
    if (!raw.trim() || raw.trim().startsWith('#')) continue;
    if (!/^\s/.test(raw)) {
      current = raw.trim();
      if (rules[current]) throw new Error(`Duplicate _headers rule: ${current}`);
      rules[current] = {};
      continue;
    }
    if (!current) throw new Error(`Header outside a rule: ${raw}`);
    const index = raw.indexOf(':');
    const name = raw.slice(0, index).trim();
    if (Object.hasOwn(rules[current], name)) {
      throw new Error(`Duplicate header ${name} in ${current}`);
    }
    rules[current][name] = raw.slice(index + 1).trim();
  }
  return rules;
}

export function cspDirectives(policy) {
  return new Map(
    policy
      .split(';')
      .map((part) => part.trim().split(/\s+/))
      .filter(([name]) => name)
      .map(([name, ...values]) => [name, values]),
  );
}
