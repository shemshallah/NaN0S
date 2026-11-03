#!/usr/bin/env node
// nan0s_fs: flat file layer over an NSPV volume, v2 chained directory.
// Block 0 = superblock; each file has one directory block (linked list) plus
// contiguous payload blocks. File count is limited by volume capacity, not a
// fixed 8-entry table.
"use strict";
const fs = require("fs");
const vol = require("./volume.cjs");
const nsp = require("./reference/nsp.cjs");

const SECTOR = 512;
const VERSION = 2;
const NAME_MAX = 39;
const FS_MAGIC = 0x4E414E30465331n; // "NAN0FS1" in the unauthenticated header
const SB_MAGIC = "NAN0FS1";
const DIR_MAGIC = "NDIR1";

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
function readSuper(image, key) {
  const sb = block(image, key, 0);
  if (sb.toString("ascii", 0, 7) !== SB_MAGIC) throw new Error("no nan0s_fs superblock");
  const version = sb.readUInt32LE(8), blockSize = sb.readUInt32LE(12);
  const capacity = sb.readUInt32LE(16), next = sb.readUInt32LE(20);
  const files = sb.readUInt32LE(24), flags = sb.readUInt32LE(28);
  const first = sb.readUInt32LE(32), last = sb.readUInt32LE(36);
  if (version !== VERSION || blockSize !== SECTOR) throw new Error("bad nan0s_fs superblock");
  return { sb, version, capacity, next, files, flags, first, last };
}
function readDirBlock(image, key, lba) {
  const b = block(image, key, lba);
  if (b.toString("ascii", 0, 5) !== DIR_MAGIC) throw new Error("bad directory block " + lba);
  return {
    lba, b, next: b.readUInt32LE(8),
    name: b.toString("utf8", 12, 52).replace(/\0.*$/, ""),
    start: b.readUInt32LE(52), sectors: b.readUInt32LE(56),
    size: b.readUInt32LE(60), flags: b.readUInt32LE(64),
  };
}
function readFs(image, key) {
  const f = readSuper(image, key);
  const dirs = [];
  const seen = new Set();
  let lba = f.first;
  while (lba !== 0) {
    if (lba < 1 || lba >= f.capacity || seen.has(lba)) throw new Error("bad directory chain");
    const d = readDirBlock(image, key, lba);
    dirs.push(d);
    seen.add(lba);
    lba = d.next;
    if (dirs.length > f.capacity) throw new Error("directory loop");
  }
  if (f.last !== (dirs.length ? dirs[dirs.length - 1].lba : 0)) throw new Error("directory tail mismatch");
  if (f.files !== dirs.length) throw new Error("file count mismatch");
  f.dirs = dirs;
  return f;
}
function writeSuper(image, key, f) {
  f.sb.writeUInt32LE(f.next, 20);
  f.sb.writeUInt32LE(f.files, 24);
  f.sb.writeUInt32LE(f.first, 32);
  f.sb.writeUInt32LE(f.last, 36);
  putBlock(image, key, 0, f.sb);
  vol.setHeaderWords(image, { 13: FS_MAGIC, 14: VERSION, 15: BigInt(f.files) });
}
function mkfs(image, key) {
  const h = needHeader(image);
  if (h.dataSectors < 1) throw new Error("volume too small");
  const sb = Buffer.alloc(SECTOR);
  sb.write(SB_MAGIC, 0, "ascii");
  sb.writeUInt32LE(VERSION, 8);
  sb.writeUInt32LE(SECTOR, 12);
  sb.writeUInt32LE(h.dataSectors, 16);
  sb.writeUInt32LE(1, 20); // next free; block 0 is the superblock
  sb.writeUInt32LE(0, 24); // files
  sb.writeUInt32LE(0, 28); // flags
  sb.writeUInt32LE(0, 32); // first directory block
  sb.writeUInt32LE(0, 36); // last directory block
  putBlock(image, key, 0, sb);
  vol.setHeaderWords(image, { 13: FS_MAGIC, 14: VERSION, 15: 0n });
  console.log("MKFS capacity=" + h.dataSectors + " next=1");
}
function findFile(f, name) {
  return f.dirs.find(d => d.name === name) || null;
}
function put(image, key, local, name) {
  if (!name || Buffer.byteLength(name) > NAME_MAX) throw new Error("name too long");
  const f = readFs(image, key);
  if (findFile(f, name)) throw new Error("exists: " + name);
  const data = fs.readFileSync(local);
  const sectors = Math.max(1, Math.ceil(data.length / SECTOR));
  const dirLba = f.next;
  const start = dirLba + 1;
  if (start + sectors > f.capacity) throw new Error("no space");
  for (let i = 0; i < sectors; i++) {
    const b = Buffer.alloc(SECTOR);
    data.copy(b, 0, i * SECTOR, Math.min(data.length, (i + 1) * SECTOR));
    putBlock(image, key, start + i, b);
  }
  const d = Buffer.alloc(SECTOR);
  d.write(DIR_MAGIC, 0, "ascii");
  d.writeUInt32LE(0, 8);
  d.write(name, 12, "utf8");
  d.writeUInt32LE(start, 52);
  d.writeUInt32LE(sectors, 56);
  d.writeUInt32LE(data.length, 60);
  d.writeUInt32LE(0, 64);
  putBlock(image, key, dirLba, d);
  if (f.last !== 0) {
    const tail = f.dirs[f.dirs.length - 1];
    tail.b.writeUInt32LE(dirLba, 8);
    putBlock(image, key, f.last, tail.b);
  } else {
    f.first = dirLba;
  }
  f.last = dirLba;
  f.next = start + sectors;
  f.files++;
  writeSuper(image, key, f);
  console.log("PUT " + name + " dir=" + dirLba + " start=" + start + " sectors=" + sectors + " bytes=" + data.length);
}
function get(image, key, name, out) {
  const f = readFs(image, key);
  const e = findFile(f, name);
  if (!e) throw new Error("not found: " + name);
  const parts = [];
  for (let i = 0; i < e.sectors; i++) parts.push(block(image, key, e.start + i));
  const data = Buffer.concat(parts).subarray(0, e.size);
  fs.writeFileSync(out, data);
  console.log("GET " + name + " bytes=" + data.length);
}
function ls(image, key) {
  const f = readFs(image, key);
  if (!f.dirs.length) { console.log("EMPTY"); return; }
  for (const e of f.dirs) console.log(e.name + " " + e.start + " " + e.sectors + " " + e.size);
}
function rm(image, key, name) {
  const f = readFs(image, key);
  const i = f.dirs.findIndex(d => d.name === name);
  if (i < 0) throw new Error("not found: " + name);
  const d = f.dirs[i];
  if (i > 0) {
    const prev = f.dirs[i - 1];
    prev.b.writeUInt32LE(d.next, 8);
    putBlock(image, key, prev.lba, prev.b);
  } else {
    f.first = d.next;
  }
  if (f.last === d.lba) f.last = i > 0 ? f.dirs[i - 1].lba : 0;
  f.files--;
  writeSuper(image, key, f);
  console.log("RM " + name);
}
function resize(image, key) {
  const h = needHeader(image);
  const f = readFs(image, key);
  if (h.dataSectors < f.next) throw new Error("capacity below next free block");
  for (const e of f.dirs) {
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
  for (const e of f.dirs) {
    if (e.start < 2 || e.start + e.sectors > f.capacity) throw new Error("bad extent: " + e.name);
    if (e.size > e.sectors * SECTOR) throw new Error("bad size: " + e.name);
  }
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
