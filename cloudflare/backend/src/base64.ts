// Decodes base64 the way Node's Buffer.from(value, 'base64') does, without
// relying on the Node Buffer global: accepts the URL-safe alphabet, skips
// characters outside the alphabet, and stops at the first '=' padding.
export function base64ToBytes(value: string): Uint8Array<ArrayBuffer> {
  let clean = value.split('=')[0].replace(/-/g, '+').replace(/_/g, '/').replace(/[^A-Za-z0-9+/]/g, '');
  if (clean.length % 4 === 1) clean = clean.slice(0, -1);
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
