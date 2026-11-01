// usage: node keyseq.mjs IMG SECS "t:HH HH HH;t:HH ..."  (t seconds, raw PS/2 scancode bytes) -> prints serial
import {V86} from "v86"; import fs from "fs";
const [img,secs,plan]=[process.argv[2],+process.argv[3]||8,process.argv[4]||""];
const e=new V86({wasm_path:"node_modules/v86/build/v86.wasm",bios:{buffer:new Uint8Array(fs.readFileSync("bios/seabios.bin")).buffer},vga_bios:{buffer:new Uint8Array(fs.readFileSync("bios/vgabios.bin")).buffer},fda:{buffer:new Uint8Array(fs.readFileSync(img)).buffer},memory_size:64*1024*1024,vga_memory_size:2*1024*1024,autostart:true});
let ser="";e.add_listener("serial0-output-byte",b=>ser+=String.fromCharCode(b));
for(const k of plan.split(";").filter(Boolean)){const [t,s]=k.split(":");setTimeout(()=>e.keyboard_send_scancodes(s.trim().split(/\s+/).map(h=>parseInt(h,16))),+t*1000)}
setTimeout(()=>{console.log(JSON.stringify(ser));process.exit(0)},secs*1000);
