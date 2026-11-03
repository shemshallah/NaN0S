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
const FREE_MAX = Math.floor((SECTOR - 44) / 8); // free extents in the superblock

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
  return { sb, version, capacity, next, files, flags, first, last, free: readFree(sb) };
}
function readFree(sb) {
  const n = sb.readUInt32LE(40);
  if (n > FREE_MAX) throw new Error("bad free count");
  const free = [];
  for (let i = 0; i < n; i++) {
    const start = sb.readUInt32LE(44 + i * 8);
    const sectors = sb.readUInt32LE(48 + i * 8);
    if (start < 1 || sectors < 1) throw new Error("bad free extent");
    free.push({ start, sectors });
  }
  return free;
}
function writeFree(sb, free) {
  if (free.length > FREE_MAX) throw new Error("free list full");
  sb.fill(0, 40, SECTOR);
  sb.writeUInt32LE(free.length, 40);
  for (let i = 0; i < free.length; i++) {
    sb.writeUInt32LE(free[i].start, 44 + i * 8);
    sb.writeUInt32LE(free[i].sectors, 48 + i * 8);
  }
}
function addFree(free, start, sectors) {
  if (sectors < 1) return;
  const all = free.concat([{ start, sectors }]).sort((a, b) => a.start - b.start);
  const out = [];
  for (const e of all) {
    if (e.sectors < 1) continue;
    const last = out[out.length - 1];
    if (last && e.start < last.start + last.sectors) throw new Error("overlapping free extents");
    if (last && e.start === last.start + last.sectors) last.sectors += e.sectors;
    else out.push({ start: e.start, sectors: e.sectors });
  }
  if (out.length > FREE_MAX) throw new Error("free list full; compact instead");
  free.length = 0;
  for (const e of out) free.push(e);
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
  writeFree(f.sb, f.free);
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
function putData(image, key, data, name) {
  if (!name || Buffer.byteLength(name) > NAME_MAX) throw new Error("name too long");
  const f = readFs(image, key);
  if (findFile(f, name)) throw new Error("exists: " + name);
  const sectors = Math.max(1, Math.ceil(data.length / SECTOR));
  const need = 1 + sectors;
  let dirLba = 0;
  for (let i = 0; i < f.free.length; i++) {
    const e = f.free[i];
    if (e.sectors < need) continue;
    dirLba = e.start;
    if (e.sectors === need) f.free.splice(i, 1);
    else { e.start += need; e.sectors -= need; }
    break;
  }
  if (dirLba === 0) {
    dirLba = f.next;
    if (dirLba + need > f.capacity) throw new Error("no space");
    f.next += need;
  }
  const start = dirLba + 1;
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
  f.files++;
  writeSuper(image, key, f);
  console.log("PUT " + name + " dir=" + dirLba + " start=" + start + " sectors=" + sectors + " bytes=" + data.length);
}
function put(image, key, local, name) {
  putData(image, key, fs.readFileSync(local), name);
}
function rename(image, key, oldName, newName) {
  if (!newName || Buffer.byteLength(newName) > NAME_MAX) throw new Error("name too long");
  const f = readFs(image, key);
  if (findFile(f, newName)) throw new Error("exists: " + newName);
  const e = findFile(f, oldName);
  if (!e) throw new Error("not found: " + oldName);
  e.b.fill(0, 12, 52);
  e.b.write(newName, 12, "utf8");
  putBlock(image, key, e.lba, e.b);
  console.log("MV " + oldName + " " + newName);
}
function df(image, key) {
  const f = readFs(image, key);
  const freeBlocks = f.free.reduce((n, e) => n + e.sectors, 0);
  const used = f.next - freeBlocks;
  console.log("DF capacity=" + f.capacity + " next=" + f.next +
    " free=" + (f.capacity - used) + " extents=" + f.free.length +
    " files=" + f.files);
}
function readFileData(image, key, e) {
  const parts = [];
  for (let i = 0; i < e.sectors; i++) parts.push(block(image, key, e.start + i));
  return Buffer.concat(parts).subarray(0, e.size);
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
  const nf = f.free.map(e => ({ ...e }));
  addFree(nf, d.lba, 1);
  addFree(nf, d.start, d.sectors);
  if (i > 0) {
    const prev = f.dirs[i - 1];
    prev.b.writeUInt32LE(d.next, 8);
    putBlock(image, key, prev.lba, prev.b);
  } else {
    f.first = d.next;
  }
  if (f.last === d.lba) f.last = i > 0 ? f.dirs[i - 1].lba : 0;
  f.free = nf;
  f.files--;
  writeSuper(image, key, f);
  console.log("RM " + name);
}
function compact(image, key) {
  const st = fs.statSync(image);
  if (!st.isFile()) throw new Error("compact requires an image file");
  const h = needHeader(image);
  const f = readFs(image, key);
  const files = f.dirs.map(e => ({ name: e.name, data: readFileData(image, key, e) }));
  const c = vol.createLazy(h.suite, h.nonce, st.size);
  if (!c) throw new Error("cannot recreate geometry");
  const tmp = image + ".compact." + process.pid;
  try {
    const fd = fs.openSync(tmp, "w+");
    try {
      fs.writeSync(fd, c.header, 0, SECTOR, 0);
      fs.ftruncateSync(fd, c.fileBytes);
    } finally { fs.closeSync(fd); }
    mkfs(tmp, key);
    for (const x of files) putData(tmp, key, x.data, x.name);
    fs.renameSync(tmp, image);
  } catch (e) {
    try { fs.unlinkSync(tmp); } catch (_) {}
    throw e;
  }
  console.log("COMPACT files=" + files.length);
}
function resize(image, key) {
  const h = needHeader(image);
  const f = readFs(image, key);
  if (h.dataSectors < f.next) throw new Error("capacity below next free block");
  for (const e of f.dirs) {
    if (e.start < 2 || e.start + e.sectors > h.dataSectors) throw new Error("extent outside capacity");
  }
  for (const e of f.free) {
    if (e.start + e.sectors > h.dataSectors) throw new Error("free extent outside capacity");
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
  const used = [];
  for (const e of f.dirs) {
    if (e.start < 2 || e.start + e.sectors > f.capacity) throw new Error("bad extent: " + e.name);
    if (e.size > e.sectors * SECTOR) throw new Error("bad size: " + e.name);
    used.push({ start: e.lba, sectors: 1 });
    used.push({ start: e.start, sectors: e.sectors });
  }
  const all = used.concat(f.free).sort((a, b) => a.start - b.start);
  for (let i = 0; i < all.length; i++) {
    if (all[i].start < 1 || all[i].sectors < 1 || all[i].start + all[i].sectors > f.capacity) {
      throw new Error("extent outside capacity");
    }
    if (i > 0 && all[i].start < all[i - 1].start + all[i - 1].sectors) throw new Error("overlapping extents");
  }
  console.log("FS OK files=" + f.files + " next=" + f.next + " free=" +
    f.free.reduce((n, e) => n + e.sectors, 0) + " capacity=" + f.capacity);
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
    else if (cmd === "mv") rename(image, key, a, b);
    else if (cmd === "df") df(image, key);
    else if (cmd === "compact") compact(image, key);
    else if (cmd === "resize") resize(image, key);
    else if (cmd === "check") check(image, key);
    else {
      console.error("usage: nan0s_fs mkfs <image> <keyhex>");
      console.error("       nan0s_fs put  <image> <keyhex> <local> <name>");
      console.error("       nan0s_fs get  <image> <keyhex> <name> <out>");
      console.error("       nan0s_fs ls   <image> <keyhex>");
      console.error("       nan0s_fs rm   <image> <keyhex> <name>");
      console.error("       nan0s_fs mv   <image> <keyhex> <old> <new>");
      console.error("       nan0s_fs df   <image> <keyhex>");
      console.error("       nan0s_fs compact <image> <keyhex>");
      console.error("       nan0s_fs resize <image> <keyhex>");
      console.error("       nan0s_fs check <image> <keyhex>");
      process.exit(2);
    }
  } catch (e) { console.error("ERR " + e.message); process.exit(1); }
}
