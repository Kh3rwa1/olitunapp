import { describe, expect, it } from 'vitest';
import { base64ToBytes } from '../src/base64';

// Expected values are what Node's Buffer.from(input, 'base64') returns, which
// the studio routes used before this helper replaced it.
describe('base64ToBytes', () => {
  it.each([
    ['QUJD', [65, 66, 67]],
    ['QUJ', [65, 66]],
    ['QU', [65]],
    ['Q', []],
    ['QQ==QQ==', [65]],
    ['QU JD\n', [65, 66, 67]],
    ['QUJD-_', [65, 66, 67, 251]],
    ['a b!c@d', [105, 183, 29]],
    ['', []],
  ])('%j', (input, expected) => {
    expect(Array.from(base64ToBytes(input))).toEqual(expected);
  });
});
