// TEST HARNESS (scaffold, not part of NaN/0S): boot a floppy image in v86, dump text screen.
import { V86 } from "v86";
import fs from "fs";
const img = process.argv[2], secs = +(process.argv[3]||5);
const buf = fs.readFileSync(img);
const em = new V86({
  wasm_path: "node_modules/v86/build/v86.wasm",
  bios: { buffer: fs.readFileSync("bios/seabios.bin").buffer },
  vga_bios: { buffer: fs.readFileSync("bios/vgabios.bin").buffer },
  fda: { buffer: buf.buffer.slice(buf.byteOffset, buf.byteOffset+buf.length) },
  autostart: true, memory_size: 16*1024*1024, vga_memory_size: 2*1024*1024, disable_keyboard: false, screen_dummy: true,
});
setTimeout(()=>{
  const t = em.screen_adapter.get_text_screen();
  console.log(t.map(l=>l.replace(/\s+$/,'')).join("\n").replace(/\n+$/,''));
  em.destroy(); process.exit(0);
}, secs*1000);
