// usage: node bootseq.mjs IMG SECS "t:HH HH HH;t:HH ..." -> prints serial + VGA rows.
// Like boot.mjs, but the key plan is raw PS/2 bytes (so E0-prefixed arrows work).
import {V86} from "v86"; import fs from "fs";
const [img,secs,plan]=[process.argv[2],+process.argv[3]||8,process.argv[4]||""];
const e=new V86({wasm_path:"node_modules/v86/build/v86.wasm",bios:{buffer:new Uint8Array(fs.readFileSync("bios/seabios.bin")).buffer},vga_bios:{buffer:new Uint8Array(fs.readFileSync("bios/vgabios.bin")).buffer},fda:{buffer:new Uint8Array(fs.readFileSync(img)).buffer},memory_size:64*1024*1024,disable_keyboard:false,vga_memory_size:2*1024*1024,autostart:true});
let ser="";e.add_listener("serial0-output-byte",b=>ser+=String.fromCharCode(b));
let rows={};e.add_listener("screen-put-char",([r,c,ch])=>{(rows[r]??={})[c]=String.fromCharCode(ch)});
for(const k of plan.split(";").filter(Boolean)){const [t,s]=k.split(":");setTimeout(()=>e.keyboard_send_scancodes(s.trim().split(/\s+/).map(h=>parseInt(h,16))),+t*1000)}
setTimeout(()=>{console.log("SERIAL:",JSON.stringify(ser));for(const r in rows){const l=rows[r];const s=Object.keys(l).map(Number).sort((a,b)=>a-b).map(k=>l[k]).join("").replace(/\u0000/g," ").trimEnd();if(s.trim()&&r<30)console.log("row",r,s)}console.log("eip",e.v86.cpu.instruction_pointer[0].toString(16));process.exit(0)},secs*1000)
