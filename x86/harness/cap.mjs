// TEST HARNESS: boot image, optionally send raw PS/2 sequences, dump VGA text memory.
// usage: node cap.mjs IMG SECS OUT.bin "t:HH HH HH;t:HH" [@sec snapshots]
// A plan entry with one byte sends make+break. Multiple bytes are sent as-is.
import { V86 } from "v86";
import fs from "fs";
const [img, secs, out, plan=""] = [process.argv[2], +process.argv[3], process.argv[4], process.argv[5]||""];
const buf = fs.readFileSync(img);
const em = new V86({
  wasm_path: "node_modules/v86/build/v86.wasm",
  bios: { buffer: fs.readFileSync("bios/seabios.bin").buffer },
  vga_bios: { buffer: fs.readFileSync("bios/vgabios.bin").buffer },
  fda: { buffer: buf.buffer.slice(buf.byteOffset, buf.byteOffset+buf.length) },
  autostart: true, memory_size: 16*1024*1024, vga_memory_size: 2*1024*1024,
  disable_keyboard: false, screen_dummy: true,
});
function snap(name){
  const cols = em.read_memory(0x44A,1)[0], rows = em.read_memory(0x484,1)[0]+1;
  const mode = em.read_memory(0x449,1)[0];
  const vm=em.v86.cpu.devices.vga.vga_memory;
  const mem=vm.slice(0,cols*rows*2);
  fs.writeFileSync(name, Buffer.concat([Buffer.from([mode,cols,rows]), Buffer.from(mem)]));
}
for (const it of plan.split(";").filter(Boolean)) {
  if (it[0]==="@") { const t=+it.slice(1); setTimeout(()=>snap(`${out}_${t}.bin`), t*1000); continue; }
  const [t,s]=it.split(":");
  const bytes=s.trim().split(/\s+/).map(x=>parseInt(x,16));
  setTimeout(()=>em.keyboard_send_scancodes(bytes), +t*1000);
  if (bytes.length===1) setTimeout(()=>em.keyboard_send_scancodes([bytes[0]|0x80]), +t*1000+60);
}
setTimeout(()=>{ snap(out); em.destroy(); process.exit(0); }, secs*1000);
