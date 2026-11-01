// TEST HARNESS: boot fda, attach an ATA primary master image, print serial.
import {V86} from "v86"; import fs from "fs";
const [img,hda,secs]=[process.argv[2],process.argv[3],+process.argv[4]||8];
const e=new V86({wasm_path:"node_modules/v86/build/v86.wasm",bios:{buffer:new Uint8Array(fs.readFileSync("bios/seabios.bin")).buffer},vga_bios:{buffer:new Uint8Array(fs.readFileSync("bios/vgabios.bin")).buffer},fda:{buffer:new Uint8Array(fs.readFileSync(img)).buffer},hda:{buffer:new Uint8Array(fs.readFileSync(hda)).buffer},memory_size:64*1024*1024,vga_memory_size:2*1024*1024,autostart:true});
let ser="";e.add_listener("serial0-output-byte",b=>ser+=String.fromCharCode(b));
setTimeout(()=>{console.log("SERIAL:",JSON.stringify(ser));process.exit(0)},secs*1000);
