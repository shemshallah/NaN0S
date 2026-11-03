#!/usr/bin/env node
// nan0s_fs: flat file layer over an NSPV volume.
// Logical data block 0 = superblock, block 1 = directory, then contiguous files.
// Every metadata/data block is an NSPV sealed sector; unused blocks stay holes.
"use strict";
const fs = require("fs");
const vol = require("./volume.cjs");
const nsp = require("./reference/nsp.cjs");

const SECTOR = 512;
const ENTRIES = 8;
const ENTRY = 64;
const FS_MAGIC = 0x4E414E30465331n; // "NAN0FS1" in the unauthenticated header
const SB_MAGIC = "NAN0FS1";
const NAME_MAX = 39;

function needHeader(image) {
  const h = vol.readHeaderFile(image);
  if (!h) throw new Error("not an NSPV image");
  return h;
}
function block(image, key, lba) {
  const b = vol.readSectorFile(image, key, lba);
  if (!b) throw new Error("missing block " + lba);
  return b;
}
function putBlock(image, key, lba, b) {
  if (!vol.writeSectorFile(image, key, lba, b)) throw new Error("write block " + lba);
}
function readFs(image, key) {
  const sb = block(image, key, 0);
  if (sb.toString("ascii", 0, 7) !== SB_MAGIC) throw new Error("no nan0s_fs superblock");
  const version = sb.readUInt32LE(8), blockSize = sb.readUInt32LE(12);
  const capacity = sb.readUInt32LE(16), next = sb.readUInt32LE(20);
  const files = sb.readUInt32LE(24), flags = sb.readUInt32LE(28);
  if (version !== 1 || blockSize !== SECTOR) throw new Error("bad nan0s_fs superblock");
  const dir = block(image, key, 1);
  return { sb, dir, version, capacity, next, files, flags };
}
function entries(dir) {
  const out = [];
  for (let e = 0; e < ENTRIES; e++) {
    const o = e * ENTRY;
    const name = dir.toString("utf8", o, o + 40).replace(/\0.*$/, "");
    if (!name) continue;
    out.push({ slot: e, offset: o, name,
      start: dir.readUInt32LE(o + 40), sectors: dir.readUInt32LE(o + 44),
      size: dir.readUInt32LE(o + 48), flags: dir.readUInt32LE(o + 52) });
  }
  return out;
}
function findEntry(dir, name) {
  return entries(dir).find(e => e.name === name) || null;
}
function writeMeta(image, key, f, fileCount) {
  f.sb.writeUInt32LE(f.next, 20);
  f.sb.writeUInt32LE(fileCount, 24);
  putBlock(image, key, 0, f.sb);
  putBlock(image, key, 1, f.dir);
  vol.setHeaderWords(image, { 13: FS_MAGIC, 14: 1n, 15: BigInt(fileCount) });
}
function mkfs(image, key) {
  const h = needHeader(image);
  if (h.dataSectors < 2) throw new Error("volume too small");
  const sb = Buffer.alloc(SECTOR);
  sb.write(SB_MAGIC, 0, "ascii");
  sb.writeUInt32LE(1, 8);
  sb.writeUInt32LE(SECTOR, 12);
  sb.writeUInt32LE(h.dataSectors, 16);
  sb.writeUInt32LE(2, 20);
  sb.writeUInt32LE(0, 24);
  sb.writeUInt32LE(0, 28);
  putBlock(image, key, 0, sb);
  putBlock(image, key, 1, Buffer.alloc(SECTOR));
  vol.setHeaderWords(image, { 13: FS_MAGIC, 14: 1n, 15: 0n });
  console.log("MKFS capacity=" + h.dataSectors + " next=2");
}
function put(image, key, local, name) {
  if (!name || Buffer.byteLength(name) > NAME_MAX) throw new Error("name too long");
  const f = readFs(image, key);
  if (findEntry(f.dir, name)) throw new Error("exists: " + name);
  let slot = -1;
  for (let e = 0; e < ENTRIES; e++) {
    if (!f.dir.toString("utf8", e * ENTRY, e * ENTRY + 40).replace(/\0.*$/, "")) { slot = e; break; }
  }
  if (slot < 0) throw new Error("directory full");
  const data = fs.readFileSync(local);
  const sectors = Math.max(1, Math.ceil(data.length / SECTOR));
  const start = f.next;
  if (start + sectors > f.capacity) throw new Error("no space");
  for (let i = 0; i < sectors; i++) {
    const b = Buffer.alloc(SECTOR);
    data.copy(b, 0, i * SECTOR, Math.min(data.length, (i + 1) * SECTOR));
    putBlock(image, key, start + i, b);
  }
  const o = slot * ENTRY;
  f.dir.fill(0, o, o + ENTRY);
  f.dir.write(name, o, "utf8");
  f.dir.writeUInt32LE(start, o + 40);
  f.dir.writeUInt32LE(sectors, o + 44);
  f.dir.writeUInt32LE(data.length, o + 48);
  f.dir.writeUInt32LE(0, o + 52);
  f.next = start + sectors;
  f.files++;
  writeMeta(image, key, f, f.files);
  console.log("PUT " + name + " start=" + start + " sectors=" + sectors + " bytes=" + data.length);
}
function get(image, key, name, out) {
  const f = readFs(image, key);
  const e = findEntry(f.dir, name);
  if (!e) throw new Error("not found: " + name);
  const parts = [];
  for (let i = 0; i < e.sectors; i++) parts.push(block(image, key, e.start + i));
  const data = Buffer.concat(parts).subarray(0, e.size);
  fs.writeFileSync(out, data);
  console.log("GET " + name + " bytes=" + data.length);
}
function ls(image, key) {
  const f = readFs(image, key);
  const es = entries(f.dir);
  if (!es.length) { console.log("EMPTY"); return; }
  for (const e of es) console.log(e.name + " " + e.start + " " + e.sectors + " " + e.size);
}
function rm(image, key, name) {
  const f = readFs(image, key);
  const e = findEntry(f.dir, name);
  if (!e) throw new Error("not found: " + name);
  f.dir.fill(0, e.offset, e.offset + ENTRY);
  f.files = Math.max(0, f.files - 1);
  writeMeta(image, key, f, f.files);
  console.log("RM " + name);
}
function resize(image, key) {
  const h = needHeader(image);
  const f = readFs(image, key);
  if (h.dataSectors < f.next) throw new Error("capacity below next free block");
  for (const e of entries(f.dir)) {
    if (e.start < 2 || e.start + e.sectors > h.dataSectors) throw new Error("extent outside capacity");
  }
  f.sb.writeUInt32LE(h.dataSectors, 16);
  putBlock(image, key, 0, f.sb);
  console.log("FS RESIZE capacity=" + h.dataSectors);
}
function check(image, key) {
  const h = needHeader(image);
  if (h.h[13] !== FS_MAGIC) { console.log("FS NO"); process.exit(1); }
  const f = readFs(image, key);
  if (f.capacity > h.dataSectors || f.next > f.capacity) throw new Error("bad geometry");
  let count = 0;
  for (const e of entries(f.dir)) {
    if (e.start < 2 || e.start + e.sectors > f.capacity) throw new Error("bad extent: " + e.name);
    if (e.size > e.sectors * SECTOR) throw new Error("bad size: " + e.name);
    count++;
  }
  if (count !== f.files) throw new Error("file count mismatch");
  console.log("FS OK files=" + f.files + " next=" + f.next + " capacity=" + f.capacity);
}

if (require.main === module) {
  const keyOf = s => nsp.words(s || "");
  const [cmd, image, keyhex, a, b] = process.argv.slice(2);
  try {
    const key = keyOf(keyhex);
    if (key.length !== 4) throw new Error("key must be 64 hex chars");
    if (cmd === "mkfs") mkfs(image, key);
    else if (cmd === "put") put(image, key, a, b);
    else if (cmd === "get") get(image, key, a, b);
    else if (cmd === "ls") ls(image, key);
    else if (cmd === "rm") rm(image, key, a);
    else if (cmd === "resize") resize(image, key);
    else if (cmd === "check") check(image, key);
    else {
      console.error("usage: nan0s_fs mkfs <image> <keyhex>");
      console.error("       nan0s_fs put  <image> <keyhex> <local> <name>");
      console.error("       nan0s_fs get  <image> <keyhex> <name> <out>");
      console.error("       nan0s_fs ls   <image> <keyhex>");
      console.error("       nan0s_fs rm   <image> <keyhex> <name>");
      console.error("       nan0s_fs resize <image> <keyhex>");
      console.error("       nan0s_fs check <image> <keyhex>");
      process.exit(2);
    }
  } catch (e) { console.error("ERR " + e.message); process.exit(1); }
}
