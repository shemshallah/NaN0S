// F2: wall-clock vs guest TICK. usage: node tick.mjs IMG SECS
import {V86} from "v86"; import fs from "fs";
const [img,secs]=[process.argv[2],+process.argv[3]||8];
const e=new V86({wasm_path:"node_modules/v86/build/v86.wasm",bios:{buffer:new Uint8Array(fs.readFileSync("bios/seabios.bin")).buffer},vga_bios:{buffer:new Uint8Array(fs.readFileSync("bios/vgabios.bin")).buffer},fda:{buffer:new Uint8Array(fs.readFileSync(img)).buffer},memory_size:64*1024*1024,vga_memory_size:2*1024*1024,autostart:true});
let ser="";const t0=performance.now();const rows=[];
e.add_listener("serial0-output-byte",b=>{const c=String.fromCharCode(b);ser+=c;if(c==="\n"){const m=ser.trim().match(/T([0-9a-f]{8})$/);if(m)rows.push([performance.now()-t0,parseInt(m[1],16)]);ser="";}});
setTimeout(()=>{console.log("lines",rows.length);let p=null;for(const [w,t] of rows){console.log("wall_ms",w.toFixed(0),"tick",t,p?("d_tick "+(t-p[1])+" d_wall "+(w-p[0]).toFixed(0)):"");p=[w,t]}
if(rows.length>2){const a=rows[1],b=rows[rows.length-1];console.log("RATIO tick/wall =",((b[1]-a[1])/(b[0]-a[0])).toFixed(4))}process.exit(0)},secs*1000);
