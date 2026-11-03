// TEST HARNESS: boot image, dump the 320x200 palette-index framebuffer.
// usage: node capfb.mjs IMG SECS OUT.raw [keyplan]
import {V86} from "v86"; import fs from "fs";
const [img,secs,out,plan=""]=[process.argv[2],+process.argv[3],process.argv[4],process.argv[5]||""];
const e=new V86({wasm_path:"node_modules/v86/build/v86.wasm",bios:{buffer:new Uint8Array(fs.readFileSync("bios/seabios.bin")).buffer},vga_bios:{buffer:new Uint8Array(fs.readFileSync("bios/vgabios.bin")).buffer},fda:{buffer:new Uint8Array(fs.readFileSync(img)).buffer},memory_size:64*1024*1024,disable_keyboard:false,vga_memory_size:2*1024*1024,autostart:true});
for(const k of plan.split(",").filter(Boolean)){const [t,sc]=k.split(":");const parts=sc.trim().split(/\s+/).map(x=>parseInt(x,16));setTimeout(()=>e.keyboard_send_scancodes(parts),+t*1000)}
setTimeout(()=>{
  const v=e.v86.cpu.devices.vga;
  if(v.graphical_mode){ v.vga_replot(); v.vga_redraw(); }
  const buf=v.graphical_mode ? Buffer.from(v.pixel_buffer.slice(0,64000)) : Buffer.alloc(64000);
  fs.writeFileSync(out, buf);
  console.log('graphical',v.graphical_mode,'size',v.screen_width+'x'+v.screen_height,'eip',e.v86.cpu.instruction_pointer[0].toString(16));
  process.exit(0);
},secs*1000);
