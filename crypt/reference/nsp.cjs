#!/usr/bin/env node
// Public reference: NSP-7/NSP-8 capsule AEAD + NSPF1 file container.
// Experimental construction; host reference only. Not for real data.
// The product port must be raw NaN16/0xNaN; this file is the vector/format
// reference and a usable host CLI for files.
const U = 0xffffffffffffffffn, MASK64 = U;
const SIGN = 1n << 63n, QUIET = 1n << 51n;
const u64 = x => x & MASK64;
const rotl = (x, r) => { r &= 63n; if (r === 0n) return u64(x); return u64((x << r) | (x >> (64n - r))); };
const rotr = (x, r) => rotl(x, 64n - (r & 63n));
function bswap(x) {
  x = u64(x);
  x = ((x & 0x00FF00FF00FF00FFn) << 8n) | ((x >> 8n) & 0x00FF00FF00FF00FFn);
  x = ((x & 0x0000FFFF0000FFFFn) << 16n) | ((x >> 16n) & 0x0000FFFF0000FFFFn);
  return u64(((x & 0xffffffffn) << 32n) | (x >> 32n));
}
const ctl = (x, b) => (((x >> b) & 1n) !== 0n) ? MASK64 : 0n;
function qs_fwd(s) {
  const n = 8;
  for (let i = 0; i < n; i += 2) {
    let m = ctl(s[i], 63n); s[(i + 1) % n] = rotl(u64(s[(i+1)%n]), BigInt(17 + (i % 3))) & m | s[(i+1)%n] & ~m;
    m = ctl(s[i], 51n); s[(i + 2) % n] = u64((s[(i+2)%n] & ~m) | (bswap(s[(i+2)%n]) & m));
    m = ctl(s[(i + 1) % n], 63n); s[(i + 3) % n] = rotl(u64(s[(i+3)%n]), BigInt(29 + (i % 5))) & m | s[(i+3)%n] & ~m;
    m = ctl(s[(i + 1) % n], 51n); s[i] = u64((s[i] & ~m) | (bswap(s[i]) & m));
  }
  for (let i = 0; i < n; i++) {
    const m = ctl(s[i] ^ s[(i + 1) % n], 63n);
    s[(i + 2) % n] = u64(s[(i + 2) % n] ^ (s[(i + 3) % n] & m));
  }
}
function qs_inv(s) {
  const n = 8;
  for (let i = n - 1; i >= 0; i--) {
    const m = ctl(s[i] ^ s[(i + 1) % n], 63n);
    s[(i + 2) % n] = u64(s[(i + 2) % n] ^ (s[(i + 3) % n] & m));
  }
  for (let i = n - 2; i >= 0; i -= 2) {
    let m = ctl(s[(i + 1) % n], 51n);
    s[i] = u64((s[i] & ~m) | (bswap(s[i]) & m));
    m = ctl(s[(i + 1) % n], 63n);
    s[(i + 3) % n] = rotl(u64(s[(i+3)%n]), 64n - BigInt(29 + (i % 5))) & m | s[(i+3)%n] & ~m;
    m = ctl(s[i], 51n); s[(i + 2) % n] = u64((s[(i+2)%n] & ~m) | (bswap(s[(i+2)%n]) & m));
    m = ctl(s[i], 63n);
    s[(i + 1) % n] = rotl(u64(s[(i+1)%n]), 64n - BigInt(17 + (i % 3))) & m | s[(i+1)%n] & ~m;
  }
}
function RC(i) {
  let z = u64(BigInt(i) * 0x9E3779B97F4A7C15n + 0x2545F4914F6CDD1Dn);
  z = u64((z ^ (z >> 30n)) * 0xBF58476D1CE4E5B9n);
  z = u64((z ^ (z >> 27n)) * 0x94D049BB133111EBn);
  return u64(z ^ (z >> 31n));
}
const RC7 = i => RC(i * 11 + 0x5A);
function perm512(state, rounds = 14, temporal = true, t = 0, use_dbl = true, use_qs = true) {
  const x = state.map(u64); const base = temporal ? t * rounds : 0;
  for (let r = 0; r < rounds; r++) {
    x[0] ^= RC7(base + r); x[4] ^= RC7(base + r + 3);
    for (let j = 0; j < 3; j++) {
      const ra = BigInt([32, 24, 16, 8][j]), rb = BigInt([17, 29, 41, 7][j]);
      for (let k = 0; k < 8; k += 2) {
        const a = k, b = (k + 1) % 8, c = (k + 2) % 8, d = (k + 4) % 8;
        x[a] = u64(x[a] + x[b]); x[c] = rotl(x[c] ^ x[a], ra);
        x[b] = u64(x[b] + x[c]); x[d] = rotl(x[d] ^ x[b], rb);
      }
    }
    if (use_dbl) for (let i = 0; i < 8; i += 2) x[i] = bswap(x[i]);
    if (use_qs) qs_fwd(x);
    for (let i = 0; i < 8; i++) x[(i + 1) % 8] = u64(x[(i + 1) % 8] ^ rotl(x[i], BigInt((7 + 5 * i) & 63)));
    const tmp = [x[1], x[3], x[5], x[7]];
    x[1] = tmp[1]; x[3] = tmp[2]; x[5] = tmp[3]; x[7] = tmp[0];
  }
  return x;
}
function perm512_inv(state, rounds = 14, temporal = true, t = 0, use_dbl = true, use_qs = true) {
  const x = state.map(u64); const base = temporal ? t * rounds : 0;
  for (let r = rounds - 1; r >= 0; r--) {
    const tmp = [x[7], x[1], x[3], x[5]];
    x[1] = tmp[0]; x[3] = tmp[1]; x[5] = tmp[2]; x[7] = tmp[3];
    for (let i = 7; i >= 0; i--) x[(i + 1) % 8] = u64(x[(i + 1) % 8] ^ rotl(x[i], BigInt((7 + 5 * i) & 63)));
    if (use_qs) qs_inv(x);
    if (use_dbl) for (let i = 0; i < 8; i += 2) x[i] = bswap(x[i]);
    for (let j = 2; j >= 0; j--) {
      const ra = BigInt([32, 24, 16][j]), rb = BigInt([17, 29, 41][j]);
      for (let k = 6; k >= 0; k -= 2) {
        const a = k, b = (k + 1) % 8, c = (k + 2) % 8, d = (k + 4) % 8;
        x[d] = x[b] ^ rotr(x[d], rb); x[b] = u64(x[b] - x[c]);
        x[c] = x[a] ^ rotr(x[c], ra); x[a] = u64(x[a] - x[b]);
      }
    }
    x[4] ^= RC7(base + r + 3); x[0] ^= RC7(base + r);
  }
  return x;
}
function initS(key, nonce) {
  const s = [nonce[0], nonce[1], key[0] ^ RC7(1), key[1] ^ RC7(2), key[2] ^ RC7(3),
    key[3] ^ RC7(4), bswap(nonce[0]) ^ RC7(5), bswap(nonce[1]) ^ RC7(6)];
  return perm512(s, 14, true, 0);
}
function seal(key, nonce, ad, pt) {
  let s = initS(key, nonce); let t = 1; const out = [];
  s[0] = u64(s[0] ^ 0xA1n); s = perm512(s, 14, true, t); t++;
  s[0] = u64(s[0] ^ 0x41n); s[1] = u64(s[1] ^ BigInt(ad.length)); s[2] = u64(s[2] ^ 0n);
  s = perm512(s, 14, true, t); t++;
  for (let i = 0; i < ad.length; i += 2) {
    for (let j = 0; j < 2; j++) if (i + j < ad.length) s[j] = u64(s[j] ^ u64(ad[i + j]));
    s = perm512(s, 14, true, t); t++;
  }
  s[0] = u64(s[0] ^ 0x42n); s[1] = u64(s[1] ^ BigInt(ad.length));
  s = perm512(s, 14, true, t); t++;
  for (let i = 0; i < pt.length; i += 2) {
    const take = Math.min(2, pt.length - i);
    for (let j = 0; j < take; j++) { s[j] = u64(s[j] ^ u64(pt[i + j])); out.push(s[j]); }
    s[1] = u64(s[1] ^ BigInt(take)); s[2] = u64(s[2] ^ BigInt(i + take));
    s = perm512(s, 14, true, t); t++;
  }
  s[0] = u64(s[0] ^ 0x81n); s[1] = u64(s[1] ^ BigInt(pt.length)); s[2] = u64(s[2] ^ 0x7Fn);
  s = perm512(s, 14, true, t); t++;
  for (let j = 0; j < 4; j++) s[j] = u64(s[j] ^ u64(key[j]));
  s = perm512(s, 14, true, t);
  return [out, s.slice(0, 6)];
}
function open_(key, nonce, ad, ct, tag) {
  let s = initS(key, nonce); let t = 1; const out = [];
  s[0] = u64(s[0] ^ 0xA1n); s = perm512(s, 14, true, t); t++;
  s[0] = u64(s[0] ^ 0x41n); s[1] = u64(s[1] ^ BigInt(ad.length)); s[2] = u64(s[2] ^ 0n);
  s = perm512(s, 14, true, t); t++;
  for (let i = 0; i < ad.length; i += 2) {
    for (let j = 0; j < 2; j++) if (i + j < ad.length) s[j] = u64(s[j] ^ u64(ad[i + j]));
    s = perm512(s, 14, true, t); t++;
  }
  s[0] = u64(s[0] ^ 0x42n); s[1] = u64(s[1] ^ BigInt(ad.length));
  s = perm512(s, 14, true, t); t++;
  for (let i = 0; i < ct.length; i += 2) {
    const take = Math.min(2, ct.length - i);
    for (let j = 0; j < take; j++) { const c = u64(ct[i + j]); out.push(u64(c ^ s[j])); s[j] = c; }
    s[1] = u64(s[1] ^ BigInt(take)); s[2] = u64(s[2] ^ BigInt(i + take));
    s = perm512(s, 14, true, t); t++;
  }
  s[0] = u64(s[0] ^ 0x81n); s[1] = u64(s[1] ^ BigInt(ct.length)); s[2] = u64(s[2] ^ 0x7Fn);
  s = perm512(s, 14, true, t); t++;
  for (let j = 0; j < 4; j++) s[j] = u64(s[j] ^ u64(key[j]));
  s = perm512(s, 14, true, t);
  if (tag.length !== 6 || tag.some((w, i) => u64(w) !== s[i])) return null;
  return out;
}
function open_(key, nonce, ad, ct, tag) {
  const s = initS(key, nonce); let t = 1; const out = [];
  s[0] ^= 0xA1n; let p = perm512(s, 14, true, t); t++;
  p[0] ^= 0x41n; p[1] ^= BigInt(ad.length); p[2] ^= 0n; p = perm512(p, 14, true, t); t++;
  for (let i = 0; i < ad.length; i += 2) {
    for (let j = 0; j < 2; j++) if (i + j < ad.length) p[j] = u64(p[j] ^ u64(ad[i + j]));
    p = perm512(p, 14, true, t); t++;
  }
  p[0] ^= 0x42n; p[1] ^= BigInt(ad.length); p = perm512(p, 14, true, t); t++;
  for (let i = 0; i < ct.length; i += 2) {
    const take = Math.min(2, ct.length - i);
    for (let j = 0; j < take; j++) { const c = u64(ct[i + j]); out.push(u64(c ^ p[j])); p[j] = c; }
    p[1] ^= BigInt(take); p[2] ^= BigInt(i + take);
    p = perm512(p, 14, true, t); t++;
  }
  p[0] ^= 0x81n; p[1] ^= BigInt(ct.length); p[2] ^= 0x7Fn; p = perm512(p, 14, true, t); t++;
  for (let j = 0; j < 4; j++) p[j] = u64(p[j] ^ u64(key[j]));
  p = perm512(p, 14, true, t);
  if (tag.length !== 6 || tag.some((w, i) => u64(w) !== p[i])) return null;
  return out;
}
const hex = ws => ws.map(w => u64(w).toString(16).padStart(16, "0")).join("");
const words = h => { h = h.trim(); const o = []; for (let i = 0; i < h.length; i += 16) o.push(BigInt("0x" + h.slice(i, i + 16))); return o; };
const leWord = (a, off) => { let w = 0n; for (let i = 0; i < 8; i++) w |= BigInt(a[off+i] & 255) << BigInt(8*i); return w; };
const pushLE = (out, w) => { for (let i = 0; i < 8; i++) out.push(Number((w >> BigInt(8*i)) & 255n)); };
function xof(tag, bytes, outlen = 32) {
  let s = Array(8).fill(0n);
  s[0] = 0xB1n; s[1] = BigInt(tag);
  s = perm512(s, 14, false);
  const len = bytes.length;
  const padlen = Math.ceil((len + 2) / 16) * 16;
  const m = new Array(padlen).fill(0);
  for (let i = 0; i < len; i++) m[i] = bytes[i] & 255;
  m[len] = 0x01; m[padlen - 1] = 0x80;
  for (let off = 0; off < padlen; off += 16) {
    s[0] = u64(s[0] ^ leWord(m, off));
    s[1] = u64(s[1] ^ leWord(m, off + 8));
    s = perm512(s, 14, false);
  }
  const out = [];
  const rounds = Math.ceil(outlen / 16);
  for (let k = 0; k < rounds; k++) {
    pushLE(out, s[0]); pushLE(out, s[1]);
    if (k + 1 < rounds) s = perm512(s, 14, false);
  }
  return out.slice(0, outlen);
}

// ---- NSP-8 capsule/duplex reference (candidate v0.1) ---------------------
// Same capsule framing as NSP-7; 16-round QST permutation; rate lanes 0/1
// are typed (0 message, 1 AD/preamble, 2 final, 3 tag); capacity lanes 0.
const QA8 = [7, 11, 17, 29], QB8 = [37, 41, 52, 63];
function p8_qstOp(x, i, p, s) {
  if (s === 0) x[i] = u64(x[i] ^ rotl(x[p], BigInt(QA8[0])));
  else if (s === 1) x[i] = bswap(x[i]);
  else if (s === 2) x[i] = u64(x[i] ^ rotl(x[p], BigInt(QB8[0])));
  else x[i] = u64(~x[i]);
}
function p8_laneRot(x, sel, inv) {
  const QINV = [0, 3, 2, 1];
  for (let q = 0; q < 2; q++) {
    let s = (sel >> (2 * q)) & 3;
    if (inv) s = QINV[s];
    const b = q * 4, tt = x.slice(b, b + 4);
    for (let k = 0; k < 4; k++) x[b + k] = tt[(k + s) % 4];
  }
}
function p8_qstR(x, types, inv) {
  if (!inv) {
    for (let t = 0; t < 4; t++) for (let s = 0; s < 4; s++)
      for (let i = 0; i < 8; i++) if (types[i] === t) p8_qstOp(x, i, (i + 1 + (t & 1)) & 7, s);
    p8_laneRot(x, 0x1B, false);
  } else {
    p8_laneRot(x, 0x1B, true);
    for (let t = 3; t >= 0; t--) for (let s = 3; s >= 0; s--)
      for (let i = 0; i < 8; i++) if (types[i] === t) p8_qstOp(x, i, (i + 1 + (t & 1)) & 7, s);
  }
}
function p8_arx(x, inv) {
  if (!inv) {
    for (let j = 0; j < 3; j++) {
      const ra = BigInt([32, 24, 16][j]), rb = BigInt([17, 29, 41][j]);
      for (let k = 0; k < 8; k += 2) {
        const a = k, b = (k + 1) % 8, c = (k + 2) % 8, d = (k + 4) % 8;
        x[a] = u64(x[a] + x[b]); x[c] = rotl(u64(x[c] ^ x[a]), ra);
        x[b] = u64(x[b] + x[c]); x[d] = rotl(u64(x[d] ^ x[b]), rb);
      }
    }
  } else {
    for (let j = 2; j >= 0; j--) {
      const ra = BigInt([32, 24, 16][j]), rb = BigInt([17, 29, 41][j]);
      for (let k = 6; k >= 0; k -= 2) {
        const a = k, b = (k + 1) % 8, c = (k + 2) % 8, d = (k + 4) % 8;
        x[d] = u64(x[b] ^ rotr(x[d], rb)); x[b] = u64(x[b] - x[c]);
        x[c] = u64(x[a] ^ rotr(x[c], ra)); x[a] = u64(x[a] - x[b]);
      }
    }
  }
}
function p8_ff(x, inv) {
  if (!inv) { for (let i = 0; i < 8; i++) x[(i + 1) % 8] = u64(x[(i + 1) % 8] ^ rotl(x[i], BigInt((7 + 5 * i) & 63))); }
  else { for (let i = 7; i >= 0; i--) x[(i + 1) % 8] = u64(x[(i + 1) % 8] ^ rotl(x[i], BigInt((7 + 5 * i) & 63))); }
}
function p8_cyc(x, inv) {
  if (!inv) { const t = [x[1], x[3], x[5], x[7]]; x[1] = t[1]; x[3] = t[2]; x[5] = t[3]; x[7] = t[0]; }
  else { const t = [x[7], x[1], x[3], x[5]]; x[1] = t[0]; x[3] = t[1]; x[5] = t[2]; x[7] = t[3]; }
}
function p8_perm(x, types, inv = false) {
  if (!inv) {
    for (let r = 0; r < 16; r++) {
      x[0] = u64(x[0] ^ RC7(r)); x[4] = u64(x[4] ^ RC7(r + 3));
      p8_arx(x, false);
      for (let i = 0; i < 8; i += 2) x[i] = bswap(x[i]);
      p8_qstR(x, types, false);
      p8_ff(x, false);
      p8_cyc(x, false);
    }
  } else {
    for (let r = 15; r >= 0; r--) {
      p8_cyc(x, true);
      p8_ff(x, true);
      p8_qstR(x, types, true);
      for (let i = 0; i < 8; i += 2) x[i] = bswap(x[i]);
      p8_arx(x, true);
      x[4] = u64(x[4] ^ RC7(r + 3)); x[0] = u64(x[0] ^ RC7(r));
    }
  }
}
function initS8(key, nonce) {
  const s = [u64(nonce[0]), u64(nonce[1]),
    u64(key[0] ^ RC7(1)), u64(key[1] ^ RC7(2)),
    u64(key[2] ^ RC7(3)), u64(key[3] ^ RC7(4)),
    u64(bswap(nonce[0]) ^ RC7(5)), u64(bswap(nonce[1]) ^ RC7(6))];
  p8_perm(s, [0, 0, 0, 0, 0, 0, 0, 0]);
  return s;
}
const types8 = t => [t, t, 0, 0, 0, 0, 0, 0];
function seal8(key, nonce, ad, pt) {
  let s = initS8(key, nonce);
  const out = [];
  s[0] = u64(s[0] ^ 0xA1n); p8_perm(s, types8(1));
  s[0] = u64(s[0] ^ 0x41n); s[1] = u64(s[1] ^ BigInt(ad.length)); s[2] = u64(s[2] ^ 0n);
  p8_perm(s, types8(1));
  for (let i = 0; i < ad.length; i += 2) {
    for (let j = 0; j < 2; j++) if (i + j < ad.length) s[j] = u64(s[j] ^ u64(ad[i + j]));
    p8_perm(s, types8(1));
  }
  s[0] = u64(s[0] ^ 0x42n); s[1] = u64(s[1] ^ BigInt(ad.length));
  p8_perm(s, types8(1));
  for (let i = 0; i < pt.length; i += 2) {
    const take = Math.min(2, pt.length - i);
    for (let j = 0; j < take; j++) { s[j] = u64(s[j] ^ u64(pt[i + j])); out.push(s[j]); }
    s[1] = u64(s[1] ^ BigInt(take)); s[2] = u64(s[2] ^ BigInt(i + take));
    p8_perm(s, types8(0));
  }
  s[0] = u64(s[0] ^ 0x81n); s[1] = u64(s[1] ^ BigInt(pt.length)); s[2] = u64(s[2] ^ 0x7Fn);
  p8_perm(s, types8(2));
  for (let j = 0; j < 4; j++) s[j] = u64(s[j] ^ u64(key[j]));
  p8_perm(s, types8(2));
  p8_perm(s, [3, 3, 3, 3, 3, 3, 0, 0]);
  return [out, s.slice(0, 6)];
}
function open8(key, nonce, ad, ct, tag) {
  let s = initS8(key, nonce);
  const out = [];
  s[0] = u64(s[0] ^ 0xA1n); p8_perm(s, types8(1));
  s[0] = u64(s[0] ^ 0x41n); s[1] = u64(s[1] ^ BigInt(ad.length)); s[2] = u64(s[2] ^ 0n);
  p8_perm(s, types8(1));
  for (let i = 0; i < ad.length; i += 2) {
    for (let j = 0; j < 2; j++) if (i + j < ad.length) s[j] = u64(s[j] ^ u64(ad[i + j]));
    p8_perm(s, types8(1));
  }
  s[0] = u64(s[0] ^ 0x42n); s[1] = u64(s[1] ^ BigInt(ad.length));
  p8_perm(s, types8(1));
  for (let i = 0; i < ct.length; i += 2) {
    const take = Math.min(2, ct.length - i);
    for (let j = 0; j < take; j++) { const c = u64(ct[i + j]); out.push(u64(c ^ s[j])); s[j] = c; }
    s[1] = u64(s[1] ^ BigInt(take)); s[2] = u64(s[2] ^ BigInt(i + take));
    p8_perm(s, types8(0));
  }
  s[0] = u64(s[0] ^ 0x81n); s[1] = u64(s[1] ^ BigInt(ct.length)); s[2] = u64(s[2] ^ 0x7Fn);
  p8_perm(s, types8(2));
  for (let j = 0; j < 4; j++) s[j] = u64(s[j] ^ u64(key[j]));
  p8_perm(s, types8(2));
  p8_perm(s, [3, 3, 3, 3, 3, 3, 0, 0]);
  if (tag.length !== 6 || tag.some((w, i) => u64(w) !== s[i])) return null;
  return out;
}
// ---- file container (suite-selected, chunked, authenticated) --------------
const FMAGIC = 0x4E53504631n; // "NSPF1"
const FCHUNK = 64;            // 64 x 64-bit words = 512 bytes per chunk
function fpush(out, w) {
  for (let j = 0; j < 8; j++) out.push(Number((u64(w) >> BigInt(8 * j)) & 255n));
}
function fnonce(n, i) {
  const lo = u64(n[0] + BigInt(i));
  const hi = u64(n[1] + (lo < n[0] ? 1n : 0n));
  return [lo, hi];
}
function fwords(buf) {
  const out = [];
  for (let off = 0; off < buf.length; off += 8) {
    let w = 0n;
    for (let j = 0; j < 8 && off + j < buf.length; j++) w |= BigInt(buf[off + j]) << BigInt(8 * j);
    out.push(w);
  }
  return out;
}
function fbytes(ws) {
  const out = [];
  for (const w of ws) for (let j = 0; j < 8; j++) out.push(Number((u64(w) >> BigInt(8 * j)) & 255n));
  return Buffer.from(out);
}
function fileSeal(suite, key, nonce, data) {
  if (suite !== 1 && suite !== 2) return null;
  const count = Math.max(1, Math.ceil(data.length / (FCHUNK * 8)));
  const header = [FMAGIC, (1n << 16n) | BigInt(suite), BigInt(FCHUNK),
    BigInt(data.length), BigInt(count), nonce[0], nonce[1]];
  const out = [];
  for (const h of header) fpush(out, h);
  for (let i = 0; i < count; i++) {
    const part = data.subarray(i * FCHUNK * 8, Math.min(data.length, (i + 1) * FCHUNK * 8));
    const pt = fwords(part);
    const cn = fnonce(nonce, i);
    const ad = header.concat([BigInt(i), BigInt(pt.length), BigInt(part.length)]);
    const [ct, tag] = suite === 1 ? seal(key, cn, ad, pt) : seal8(key, cn, ad, pt);
    fpush(out, BigInt(pt.length));
    for (const w of ct) fpush(out, w);
    for (const w of tag) fpush(out, w);
  }
  return Buffer.from(out);
}
function fileOpen(key, blob) {
  if (blob.length < 56) return null;
  const h = [];
  for (let i = 0; i < 7; i++) h.push(leWord(blob, i * 8));
  if (h[0] !== FMAGIC) return null;
  const ver = Number(h[1] >> 16n), suite = Number(h[1] & 0xffffn);
  if (ver !== 1 || (suite !== 1 && suite !== 2)) return null;
  const chunk = Number(h[2]), total = Number(h[3]), count = Number(h[4]);
  if (chunk !== FCHUNK || count < 1 || count > 65536) return null;
  const nonce = [h[5], h[6]];
  const out = [];
  let off = 56;
  for (let i = 0; i < count; i++) {
    if (off + 8 > blob.length) return null;
    const len = Number(leWord(blob, off)); off += 8;
    if (len > FCHUNK) return null;
    const need = (len + 6) * 8;
    if (off + need > blob.length) return null;
    const ct = [];
    for (let j = 0; j < len; j++) { ct.push(leWord(blob, off)); off += 8; }
    const tag = [];
    for (let j = 0; j < 6; j++) { tag.push(leWord(blob, off)); off += 8; }
    const cn = fnonce(nonce, i);
    const ad = h.concat([BigInt(i), BigInt(len), BigInt(Math.min(FCHUNK * 8, total - i * FCHUNK * 8))]);
    const pt = suite === 1 ? open_(key, cn, ad, ct, tag) : open8(key, cn, ad, ct, tag);
    if (pt === null) return null;
    out.push(...pt);
  }
  if (off !== blob.length) return null;
  const data = fbytes(out);
  if (data.length < total || data.length - total >= 8) return null;
  return data.subarray(0, total);
}
module.exports = { u64, rotl, rotr, bswap, qs_fwd, qs_inv, RC, RC7, perm512, perm512_inv, initS, seal, open_, p8_perm, initS8, seal8, open8, fileSeal, fileOpen, hex, words, xof };

if (require.main === module) {
  const fs = require("fs");
  const cmd = process.argv[2];
  if (cmd === "file-seal") {
    const suite = parseInt(process.argv[3] || "0", 10);
    if (suite !== 1 && suite !== 2) { console.error("ENOTSUP"); process.exit(2); }
    const inp = process.argv[4], outp = process.argv[5];
    const key = words(process.argv[6] || ""), non = words(process.argv[7] || "");
    if (key.length !== 4 || non.length !== 2) { console.error("bad key/nonce"); process.exit(2); }
    const data = fs.readFileSync(inp);
    const blob = fileSeal(suite, key, non, data);
    if (!blob) { console.error("SEAL FAIL"); process.exit(1); }
    fs.writeFileSync(outp, blob);
    console.log("SEALED " + data.length + " " + blob.length + " suite " + suite);
  } else if (cmd === "file-open") {
    const inp = process.argv[3], outp = process.argv[4];
    const key = words(process.argv[5] || "");
    if (key.length !== 4) { console.error("bad key"); process.exit(2); }
    const blob = fs.readFileSync(inp);
    const data = fileOpen(key, blob);
    if (data === null) { console.error("REFUSE"); process.exit(1); }
    fs.writeFileSync(outp, data);
    console.log("OPENED " + data.length);
  } else if (cmd === "selftest") {
    const gen5 = () => { let st = 0x243F6A8885A308D3n; return () => { st = u64(st * 0x5851F42D4C957F2Dn + 0x14057B7EF767814Fn); return st; }; };
    const fill5 = n => { const g = gen5(); const w = []; for (let i = 0; i < n; i++) w.push(g()); return w; };
    const H5 = w => u64(w).toString(16).toUpperCase().padStart(16, "0");
    const key = fill5(4), non = fill5(2), pt = fill5(3), ad = fill5(2);
    const [c1, t1] = seal(key, non, [], pt);
    const [c2, t2] = seal(key, non, ad, pt);
    const [c81, t81] = seal8(key, non, [], pt);
    const [c82, t82] = seal8(key, non, ad, pt);
    console.log("CAP7-1 " + c1.map(H5).concat(t1.map(H5)).join(" "));
    console.log("CAP7-2 " + c2.map(H5).concat(t2.map(H5)).join(" "));
    console.log("CAP8-1 " + c81.map(H5).concat(t81.map(H5)).join(" "));
    console.log("CAP8-2 " + c82.map(H5).concat(t82.map(H5)).join(" "));
    const tt = t82.slice(); tt[0] = u64(tt[0] ^ 1n);
    console.log(open8(key, non, ad, c82, tt) === null ? "TAM8 1 OK" : "TAM8 1 NO");
    const cc = c82.slice(); cc[0] = u64(cc[0] ^ 1n);
    console.log(open8(key, non, ad, cc, t82) === null ? "TAM8 2 OK" : "TAM8 2 NO");
    console.log("PASS");
  } else {
    console.error("usage: nsp.cjs file-seal <1|2> <in> <out> <keyhex> <noncehex>");
    console.error("       nsp.cjs file-open <in> <out> <keyhex>");
    console.error("       nsp.cjs selftest");
    process.exit(2);
  }
}
