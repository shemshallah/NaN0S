// capx.mjs IMG SECS OUT.ppm [keyplan] -- boot, send keys, dump the visible framebuffer (VGA13 or Bochs-VBE 8bpp) as PPM
import {V86} from "v86"; import fs from "fs";
const [img,secs,out,plan=""]=[process.argv[2],+process.argv[3],process.argv[4],process.argv[5]||""];
const e=new V86({wasm_path:"node_modules/v86/build/v86.wasm",bios:{buffer:new Uint8Array(fs.readFileSync("bios/seabios.bin")).buffer},vga_bios:{buffer:new Uint8Array(fs.readFileSync("bios/vgabios.bin")).buffer},fda:{buffer:new Uint8Array(fs.readFileSync(img)).buffer},memory_size:64*1024*1024,disable_keyboard:false,vga_memory_size:8*1024*1024,screen_dummy:true,autostart:true});
for(const k of plan.split(",").filter(Boolean)){const [t,sc]=k.split(":");const parts=sc.trim().split(/\s+/).map(x=>parseInt(x,16));setTimeout(()=>e.keyboard_send_scancodes(parts),+t*1000)}
setTimeout(()=>{
  const v=e.v86.cpu.devices.vga;
  const info={svga:v.svga_enabled,w:v.svga_width,h:v.svga_height,bpp:v.svga_bpp,gm:v.graphical_mode,sw:v.screen_width,sh:v.screen_height};
  console.log(JSON.stringify(info),'eip',e.v86.cpu.instruction_pointer[0].toString(16));
  let w,h,idx;
  if(v.svga_enabled){w=v.svga_width;h=v.svga_height;idx=v.svga_memory.subarray(0,w*h);}
  else {w=320;h=200;v.vga_replot();v.vga_redraw();idx=v.pixel_buffer.subarray(0,64000);}
  const pal=v.dac_map?null:null;
  // palette: v.vga256_palette (RGBA ints) if present
  const P=v.vga256_palette||new Int32Array(256);
  const buf=Buffer.alloc(w*h*3);
  for(let i=0;i<w*h;i++){const c=P[idx[i]];buf[i*3]=(c>>16)&255;buf[i*3+1]=(c>>8)&255;buf[i*3+2]=c&255;}
  fs.writeFileSync(out,Buffer.concat([Buffer.from(`P6\n${w} ${h}\n255\n`),buf]));
  fs.writeFileSync(out+'.idx',Buffer.from(idx));
  process.exit(0);
},secs*1000);
