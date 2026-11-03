#!/usr/bin/env node
// NSPV1 sector volume reference: format/verify/read/write a raw disk image.
// Header + per-sector AEAD tags; suites 1 (NSP-7) and 2 (NSP-8 reference).
// Experimental; host reference only. The guest port/boot integration is pending.
"use strict";
const fs = require("fs");
const nsp = require("./reference/nsp.cjs");

const SECTOR = 512;
const MAGIC = 0x4E53505631n; // "NSPV1" LE
const HEADER_WORDS = 16;
const TAG_WORDS = 6;
const TAGS_PER_SECTOR = 10;

function u64(x) { return BigInt.asUintN(64, BigInt(x)); }
function leWord(buf, off) {
  let w = 0n;
  for (let i = 0; i < 8; i++) w |= BigInt(buf[off + i]) << BigInt(8 * i);
  return u64(w);
}
function putWord(buf, off, w) {
  w = u64(w);
  for (let i = 0; i < 8; i++) buf[off + i] = Number((w >> BigInt(8 * i)) & 255n);
}
function wordsToBytes(ws) {
  const out = Buffer.alloc(ws.length * 8);
  for (let i = 0; i < ws.length; i++) putWord(out, i * 8, ws[i]);
  return out;
}
function bytesToWords(buf) {
  const out = [];
  for (let off = 0; off < buf.length; off += 8) out.push(leWord(buf, off));
  return out;
}
function parseHeader(buf, fileSectors) {
  if (buf.length < SECTOR) return null;
  const h = [];
  for (let i = 0; i < HEADER_WORDS; i++) h.push(leWord(buf, i * 8));
  if (h[0] !== MAGIC) return null;
  const ver = Number(h[1] >> 16n), suite = Number(h[1] & 0xffffn);
  const sector = Number(h[2]), dataLba = Number(h[3]), dataSectors = Number(h[4]);
  const tagLba = Number(h[5]), tagSectors = Number(h[6]);
  const flags = Number(h[12]);
  const used = (flags & 1) ? Number(h[11]) : dataSectors;
  if (ver !== 1 || (suite !== 1 && suite !== 2) || sector !== SECTOR) return null;
  if (dataSectors < 1 || dataSectors > 0xFFFFFFFF) return null;
  if (tagLba < 1 || tagLba + tagSectors > dataLba) return null;
  if (used < 0 || used > dataSectors) return null;
  const total = fileSectors == null ? buf.length / SECTOR : fileSectors;
  if (dataLba + dataSectors > total) return null;
  return { h, suite, dataLba, dataSectors, tagLba, tagSectors, flags, used,
    lazy: !!(flags & 1), nonce: [h[7], h[8]], keyId: Number(h[9]), rollback: Number(h[10]) };
}
function ad(h, lba) { return h.slice(0, 11).concat([BigInt(lba)]); }
function nonceAt(n, i) {
  const lo = u64(n[0] + BigInt(i));
  const hi = u64(n[1] + (lo < n[0] ? 1n : 0n));
  return [lo, hi];
}
function tagOffset(info, lba) {
  return info.tagLba * SECTOR + Math.floor(lba / TAGS_PER_SECTOR) * SECTOR +
    (lba % TAGS_PER_SECTOR) * TAG_WORDS * 8;
}
function sealSectorWith(info, key, lba, pt) {
  const p = Buffer.alloc(SECTOR); pt.copy(p, 0, 0, Math.min(pt.length, SECTOR));
  const adw = ad(info.h, lba);
  const w = bytesToWords(p);
  const [ct, tag] = info.suite === 1 ? nsp.seal(key, nonceAt(info.nonce, lba), adw, w) : nsp.seal8(key, nonceAt(info.nonce, lba), adw, w);
  return { ct: wordsToBytes(ct), tag };
}
function openSectorWith(info, key, lba, ct, tag) {
  const adw = ad(info.h, lba);
  const cw = bytesToWords(ct), tw = tag;
  const pt = info.suite === 1 ? nsp.open_(key, nonceAt(info.nonce, lba), adw, cw, tw) : nsp.open8(key, nonceAt(info.nonce, lba), adw, cw, tw);
  return pt === null ? null : wordsToBytes(pt);
}
function format(suite, key, nonce, dataSectors) {
  if (suite !== 1 && suite !== 2) return null;
  const tagSectors = Math.ceil(dataSectors / TAGS_PER_SECTOR);
  const dataLba = 1 + tagSectors;
  const buf = Buffer.alloc((dataLba + dataSectors) * SECTOR);
  const h = [MAGIC, (1n << 16n) | BigInt(suite), BigInt(SECTOR), BigInt(dataLba),
    BigInt(dataSectors), 1n, BigInt(tagSectors), nonce[0], nonce[1], 0n, 0n,
    0n, 0n, 0n, 0n, 0n];
  for (let i = 0; i < HEADER_WORDS; i++) putWord(buf, i * 8, h[i]);
  const info = { h, suite, dataLba, dataSectors, tagLba: 1, tagSectors, nonce };
  const zero = Buffer.alloc(SECTOR);
  for (let i = 0; i < dataSectors; i++) {
    const { ct, tag } = sealSectorWith(info, key, i, zero);
    ct.copy(buf, (dataLba + i) * SECTOR);
    const to = tagOffset(info, i);
    wordsToBytes(tag).copy(buf, to);
  }
  return buf;
}
// Sparse/lazy layout: reserve the tag table for the full capacity once, then
// grow `used` in place as sectors are written. data_lba never moves.
function lazyGeometry(totalSectors) {
  if (!Number.isSafeInteger(totalSectors) || totalSectors < 4) return null;
  let cap = Math.max(1, Math.floor((totalSectors - 1) * TAGS_PER_SECTOR /
    (TAGS_PER_SECTOR + 1)));
  for (;;) {
    const tagSectors = Math.ceil(cap / TAGS_PER_SECTOR);
    const dataLba = 1 + tagSectors;
    if (dataLba + cap <= totalSectors) {
      return { dataSectors: cap, tagSectors, dataLba, totalSectors };
    }
    if (--cap < 1) return null;
  }
}
function createLazy(suite, nonce, totalBytes) {
  if (suite !== 1 && suite !== 2) return null;
  const totalSectors = Math.floor(Number(totalBytes) / SECTOR);
  const g = lazyGeometry(totalSectors);
  if (!g || g.dataSectors > 0xFFFFFFFF) return null;
  const h = [MAGIC, (1n << 16n) | BigInt(suite), BigInt(SECTOR), BigInt(g.dataLba),
    BigInt(g.dataSectors), 1n, BigInt(g.tagSectors), nonce[0], nonce[1], 0n, 0n,
    0n, 1n, 0n, 0n, 0n];
  const header = Buffer.alloc(SECTOR);
  for (let i = 0; i < HEADER_WORDS; i++) putWord(header, i * 8, h[i]);
  return { header, suite, nonce, used: 0, flags: 1, lazy: true,
    dataLba: g.dataLba, dataSectors: g.dataSectors, tagLba: 1,
    tagSectors: g.tagSectors, totalSectors: g.totalSectors,
    fileBytes: g.totalSectors * SECTOR };
}
function verify(buf, key) {
  const info = parseHeader(buf);
  if (!info) return false;
  for (let i = 0; i < info.used; i++) {
    const ct = buf.subarray((info.dataLba + i) * SECTOR, (info.dataLba + i + 1) * SECTOR);
    const to = tagOffset(info, i);
    const tag = bytesToWords(buf.subarray(to, to + TAG_WORDS * 8));
    if (openSectorWith(info, key, i, ct, tag) === null) return false;
  }
  return true;
}
function readSector(buf, key, lba) {
  const info = parseHeader(buf);
  if (!info || lba < 0 || lba >= info.dataSectors) return null;
  if (info.lazy && lba >= info.used) return null;
  const ct = buf.subarray((info.dataLba + lba) * SECTOR, (info.dataLba + lba + 1) * SECTOR);
  const to = tagOffset(info, lba);
  const tag = bytesToWords(buf.subarray(to, to + TAG_WORDS * 8));
  return openSectorWith(info, key, lba, ct, tag);
}
function writeSector(buf, key, lba, pt) {
  const info = parseHeader(buf);
  if (!info || lba < 0 || lba >= info.dataSectors) return null;
  const { ct, tag } = sealSectorWith(info, key, lba, pt);
  ct.copy(buf, (info.dataLba + lba) * SECTOR);
  wordsToBytes(tag).copy(buf, tagOffset(info, lba));
  if (info.lazy && lba + 1 > info.used) {
    info.h[11] = BigInt(lba + 1);
    putWord(buf, 11 * 8, info.h[11]);
    info.used = lba + 1;
  }
  return buf;
}
function readHeaderFile(path, totalSectors) {
  const fd = fs.openSync(path, "r");
  try {
    const hb = Buffer.alloc(SECTOR);
    const n = fs.readSync(fd, hb, 0, SECTOR, 0);
    if (n < SECTOR) return null;
    const st = fs.fstatSync(fd);
    const sectors = totalSectors == null ? Math.floor(st.size / SECTOR) : totalSectors;
    return parseHeader(hb, sectors);
  } finally { fs.closeSync(fd); }
}
function readSectorFile(path, key, lba, totalSectors) {
  const info = readHeaderFile(path, totalSectors);
  if (!info || lba < 0 || lba >= info.dataSectors) return null;
  if (info.lazy && lba >= info.used) return null;
  const fd = fs.openSync(path, "r");
  try {
    const ct = Buffer.alloc(SECTOR);
    const tagb = Buffer.alloc(TAG_WORDS * 8);
    const off = (info.dataLba + lba) * SECTOR;
    fs.readSync(fd, ct, 0, SECTOR, off);
    fs.readSync(fd, tagb, 0, tagb.length, tagOffset(info, lba));
    return openSectorWith(info, key, lba, ct, bytesToWords(tagb));
  } finally { fs.closeSync(fd); }
}
function writeSectorFile(path, key, lba, pt, totalSectors) {
  const fd = fs.openSync(path, "r+");
  try {
    const hb = Buffer.alloc(SECTOR);
    if (fs.readSync(fd, hb, 0, SECTOR, 0) < SECTOR) return null;
    const st = fs.fstatSync(fd);
    const sectors = totalSectors == null ? Math.floor(st.size / SECTOR) : totalSectors;
    const info = parseHeader(hb, sectors);
    if (!info || lba < 0 || lba >= info.dataSectors) return null;
    const { ct, tag } = sealSectorWith(info, key, lba, pt);
    fs.writeSync(fd, ct, 0, SECTOR, (info.dataLba + lba) * SECTOR);
    const tw = wordsToBytes(tag);
    fs.writeSync(fd, tw, 0, tw.length, tagOffset(info, lba));
    if (info.lazy && lba + 1 > info.used) {
      info.h[11] = BigInt(lba + 1);
      putWord(hb, 11 * 8, info.h[11]);
      fs.writeSync(fd, hb, 0, SECTOR, 0);
    }
    return true;
  } finally { fs.closeSync(fd); }
}
// Grow capacity by re-sealing the populated prefix into a larger lazy image.
// The nonce/key stay the same; the header geometry and every copied sector's AD
// are therefore rebuilt. Capacity can shrink only down to `used`.
function growFile(path, key, totalBytes) {
  const old = readHeaderFile(path);
  if (!old) return null;
  const c = createLazy(old.suite, old.nonce, totalBytes);
  if (!c || old.used > c.dataSectors) return null;
  const tmp = path + ".grow." + process.pid;
  const fd = fs.openSync(tmp, "w+");
  try {
    fs.writeSync(fd, c.header, 0, SECTOR, 0);
    fs.ftruncateSync(fd, c.fileBytes);
  } finally { fs.closeSync(fd); }
  let copied = 0;
  for (let i = 0; i < old.used; i++) {
    const pt = readSectorFile(path, key, i);
    if (pt) {
      if (!writeSectorFile(tmp, key, i, pt)) { try { fs.unlinkSync(tmp); } catch (e) {} return null; }
      copied++;
    }
  }
  if (old.used > 0 && copied === 0) { try { fs.unlinkSync(tmp); } catch (e) {} return null; }
  const cur = readHeaderFile(tmp);
  if (!cur) { try { fs.unlinkSync(tmp); } catch (e) {} return null; }
  if (cur.used < old.used) {
    const hf = fs.openSync(tmp, "r+");
    try {
      const hb = Buffer.alloc(SECTOR);
      fs.readSync(hf, hb, 0, SECTOR, 0);
      putWord(hb, 11 * 8, BigInt(old.used));
      fs.writeSync(hf, hb, 0, SECTOR, 0);
    } finally { fs.closeSync(hf); }
  }
  fs.renameSync(tmp, path);
  return readHeaderFile(path);
}
function verifyFile(path, key, totalSectors) {
  const info = readHeaderFile(path, totalSectors);
  if (!info) return false;
  const fd = fs.openSync(path, "r");
  try {
    const ct = Buffer.alloc(SECTOR);
    const tagb = Buffer.alloc(TAG_WORDS * 8);
    for (let i = 0; i < info.used; i++) {
      fs.readSync(fd, ct, 0, SECTOR, (info.dataLba + i) * SECTOR);
      fs.readSync(fd, tagb, 0, tagb.length, tagOffset(info, i));
      if (openSectorWith(info, key, i, ct, bytesToWords(tagb)) === null) return false;
    }
    return true;
  } finally { fs.closeSync(fd); }
}
function infoOf(buf) {
  const i = parseHeader(buf); if (!i) return null;
  return { suite: i.suite, dataLba: i.dataLba, dataSectors: i.dataSectors,
    tagLba: i.tagLba, tagSectors: i.tagSectors, keyId: i.keyId,
    rollback: i.rollback, used: i.used, flags: i.flags, lazy: i.lazy };
}
module.exports = { format, createLazy, lazyGeometry, growFile, verify, verifyFile,
  readSector, writeSector, readSectorFile, writeSectorFile, readHeaderFile,
  infoOf, SECTOR, MAGIC };

function parseSize(s) {
  const m = /^(\d+(?:\.\d+)?)([KMGTP]?)(?:i?B)?$/i.exec(String(s || ""));
  if (!m) return null;
  const mul = { "": 1, K: 1024, M: 1024 ** 2, G: 1024 ** 3, T: 1024 ** 4, P: 1024 ** 5 };
  return Math.floor(parseFloat(m[1]) * mul[m[2].toUpperCase()]);
}

if (require.main === module) {
  const cmd = process.argv[2];
  const keyOf = s => nsp.words(s || "");
  try {
    if (cmd === "format") {
      const suite = parseInt(process.argv[3], 10), out = process.argv[4];
      const key = keyOf(process.argv[5]), non = keyOf(process.argv[6]);
      const n = parseInt(process.argv[7] || "16", 10);
      if ((suite !== 1 && suite !== 2) || key.length !== 4 || non.length !== 2 || n < 1) { console.error("usage: format <1|2> <out> <keyhex> <noncehex> <sectors>"); process.exit(2); }
      fs.writeFileSync(out, format(suite, key, non, n));
      console.log("FORMAT " + suite + " " + n);
    } else if (cmd === "create") {
      const suite = parseInt(process.argv[3], 10), out = process.argv[4];
      const key = keyOf(process.argv[5]), non = keyOf(process.argv[6]);
      const bytes = parseSize(process.argv[7]);
      const device = process.argv.includes("--device");
      if ((suite !== 1 && suite !== 2) || key.length !== 4 || non.length !== 2 || !bytes) {
        console.error("usage: create <1|2> <out> <keyhex> <noncehex> <size> [--device]");
        process.exit(2);
      }
      const c = createLazy(suite, non, bytes);
      if (!c) { console.error("CREATE FAIL geometry"); process.exit(1); }
      const fd = fs.openSync(out, device ? "r+" : "w+");
      try { fs.writeSync(fd, c.header, 0, SECTOR, 0); if (!device) fs.ftruncateSync(fd, c.fileBytes); }
      finally { fs.closeSync(fd); }
      console.log("CREATE " + suite + " capacity=" + c.dataSectors +
        " used=0 lazy=1 bytes=" + c.fileBytes);
    } else if (cmd === "grow") {
      const file = process.argv[3], key = keyOf(process.argv[4]);
      const bytes = parseSize(process.argv[5]);
      if (key.length !== 4 || !bytes) {
        console.error("usage: grow <image> <keyhex> <newsize>");
        process.exit(2);
      }
      const i = growFile(file, key, bytes);
      if (!i) { console.error("GROW FAIL"); process.exit(1); }
      console.log("GROW OK capacity=" + i.dataSectors + " used=" + i.used +
        " lazy=" + (i.lazy ? 1 : 0));
    } else if (cmd === "check") {
      const args = process.argv.slice(3), file = args[0];
      const si = args.indexOf("--sectors");
      const sectors = si >= 0 ? Number(args[si + 1]) : undefined;
      const keyArg = args[1] && !args[1].startsWith("--") ? args[1] : "";
      const i = readHeaderFile(file, sectors);
      const bytes = sectors == null ? fs.statSync(file).size : sectors * SECTOR;
      if (!i) { console.log("CHECK FAIL"); process.exit(1); }
      console.log("CHECK OK suite=" + i.suite + " capacity=" + i.dataSectors +
        " used=" + i.used + " lazy=" + (i.lazy ? 1 : 0) + " bytes=" + bytes);
      if (args.includes("--verify")) {
        const key = keyOf(keyArg);
        if (key.length !== 4 || !verifyFile(file, key)) { console.log("VERIFY FAIL"); process.exit(1); }
        console.log("VERIFY OK");
      }
    } else if (cmd === "verify") {
      const args = process.argv.slice(3), si = args.indexOf("--sectors");
      const file = args[0], key = keyOf(args[1]);
      const sec = si >= 0 ? Number(args[si + 1]) : undefined;
      const ok = key.length === 4 && verifyFile(file, key, sec);
      console.log(ok ? "VERIFY OK" : "VERIFY FAIL");
      process.exit(ok ? 0 : 1);
    } else if (cmd === "info") {
      const args = process.argv.slice(3), si = args.indexOf("--sectors");
      const i = readHeaderFile(args[0], si >= 0 ? Number(args[si + 1]) : undefined);
      if (!i) { console.log("NOT NSPV"); process.exit(1); }
      console.log("SUITE " + i.suite + " DATA " + i.dataLba + " SECTORS " + i.dataSectors +
        " USED " + i.used + " TAGS " + i.tagSectors + " LAZY " + (i.lazy ? 1 : 0));
    } else if (cmd === "read") {
      const args = process.argv.slice(3), si = args.indexOf("--sectors");
      const file = args[0], key = keyOf(args[1]);
      const pt = readSectorFile(file, key, parseInt(args[2], 10),
        si >= 0 ? Number(args[si + 1]) : undefined);
      if (!pt) { console.error("READ FAIL"); process.exit(1); }
      fs.writeFileSync(args[3], pt);
      console.log("READ OK");
    } else if (cmd === "write") {
      const args = process.argv.slice(3), si = args.indexOf("--sectors");
      const file = args[0], key = keyOf(args[1]);
      const lba = parseInt(args[2], 10);
      const pt = fs.readFileSync(args[3]);
      if (!writeSectorFile(file, key, lba, pt,
        si >= 0 ? Number(args[si + 1]) : undefined)) { console.error("WRITE FAIL"); process.exit(1); }
      console.log("WRITE OK");
    } else {
      console.error("usage: nspvol create|format|check|verify|info|read|write ...");
      process.exit(2);
    }
  } catch (e) { console.error("ERR " + e.message); process.exit(1); }
}
