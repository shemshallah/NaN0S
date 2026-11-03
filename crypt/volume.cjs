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
function parseHeader(buf) {
  if (buf.length < SECTOR) return null;
  const h = [];
  for (let i = 0; i < HEADER_WORDS; i++) h.push(leWord(buf, i * 8));
  if (h[0] !== MAGIC) return null;
  const ver = Number(h[1] >> 16n), suite = Number(h[1] & 0xffffn);
  const sector = Number(h[2]), dataLba = Number(h[3]), dataSectors = Number(h[4]);
  const tagLba = Number(h[5]), tagSectors = Number(h[6]);
  if (ver !== 1 || (suite !== 1 && suite !== 2) || sector !== SECTOR) return null;
  if (dataSectors < 1 || dataSectors > 0x1000000) return null;
  if (tagLba < 1 || tagLba + tagSectors > dataLba) return null;
  if (dataLba + dataSectors > buf.length / SECTOR) return null;
  return { h, suite, dataLba, dataSectors, tagLba, tagSectors,
    nonce: [h[7], h[8]], keyId: Number(h[9]), rollback: Number(h[10]) };
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
function verify(buf, key) {
  const info = parseHeader(buf);
  if (!info) return false;
  for (let i = 0; i < info.dataSectors; i++) {
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
  return buf;
}
function infoOf(buf) {
  const i = parseHeader(buf); if (!i) return null;
  return { suite: i.suite, dataLba: i.dataLba, dataSectors: i.dataSectors,
    tagLba: i.tagLba, tagSectors: i.tagSectors, keyId: i.keyId,
    rollback: i.rollback };
}
module.exports = { format, verify, readSector, writeSector, infoOf, SECTOR, MAGIC };

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
    } else if (cmd === "verify") {
      const buf = fs.readFileSync(process.argv[3]), key = keyOf(process.argv[4]);
      console.log(verify(buf, key) ? "VERIFY OK" : "VERIFY FAIL");
      process.exit(verify(buf, key) ? 0 : 1);
    } else if (cmd === "info") {
      const i = infoOf(fs.readFileSync(process.argv[3]));
      if (!i) { console.log("NOT NSPV"); process.exit(1); }
      console.log("SUITE " + i.suite + " DATA " + i.dataLba + " SECTORS " + i.dataSectors + " TAGS " + i.tagSectors);
    } else if (cmd === "read") {
      const buf = fs.readFileSync(process.argv[3]), key = keyOf(process.argv[4]);
      const pt = readSector(buf, key, parseInt(process.argv[5], 10));
      if (!pt) { console.error("READ FAIL"); process.exit(1); }
      fs.writeFileSync(process.argv[6], pt);
      console.log("READ OK");
    } else if (cmd === "write") {
      const file = process.argv[3], key = keyOf(process.argv[4]);
      const lba = parseInt(process.argv[5], 10);
      const buf = fs.readFileSync(file);
      const pt = fs.readFileSync(process.argv[6]);
      if (!writeSector(buf, key, lba, pt)) { console.error("WRITE FAIL"); process.exit(1); }
      fs.writeFileSync(file, buf);
      console.log("WRITE OK");
    } else {
      console.error("usage: nspvol format|verify|info|read|write ...");
      process.exit(2);
    }
  } catch (e) { console.error("ERR " + e.message); process.exit(1); }
}
