// shot.mjs - THE outer box (r26h). Boots a floppy image in v86, plays a key plan, then captures.
// It contains no build or test logic: it only moves bytes between the emulator and files.
// usage: node shot.mjs IMG SECS OUT [plan] [--mem 0xADDR:LEN:FILE]
//   plan  "t:HH HH;t:HH"  (seconds : PS/2 scancodes; one byte = make+break, several = as given). A leading "@t" snapshots at t.
//   OUT   graphics modes -> OUT.png (+OUT.idx palette indices); text modes -> OUT.txt (the 80x25 text screen)
//   --mem dumps LEN bytes of guest physical memory at ADDR to FILE (e.g. the output buffer of an in-guest assembler)
import {V86} from "v86"; import fs from "fs"; import zlib from "zlib";
const A=process.argv.slice(2); const mi=A.indexOf("--mem"); const memreq=mi>=0?A.splice(mi,2)[1]:null;
const [img,secs,out,plan=""]=[A[0],+A[1],A[2],A[3]||""];
const crcT=new Int32Array(256).map((_,n)=>{let c=n;for(let k=0;k<8;k++)c=c&1?0xEDB88320^(c>>>1):c>>>1;return c});
const crc=b=>{let c=-1;for(const x of b)c=crcT[(c^x)&255]^(c>>>8);return (c^-1)>>>0};
const chunk=(t,d)=>{const b=Buffer.alloc(12+d.length);b.writeUInt32BE(d.length,0);b.write(t,4);d.copy(b,8);b.writeUInt32BE(crc(b.subarray(4,8+d.length)),8+d.length);return b};
function png(w,h,rgb){const raw=Buffer.alloc((w*3+1)*h);for(let y=0;y<h;y++){raw[y*(w*3+1)]=0;rgb.copy(raw,y*(w*3+1)+1,y*w*3,(y+1)*w*3)}
 const ih=Buffer.alloc(13);ih.writeUInt32BE(w,0);ih.writeUInt32BE(h,4);ih[8]=8;ih[9]=2;
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk("IHDR",ih),chunk("IDAT",zlib.deflateSync(raw,{level:9})),chunk("IEND",Buffer.alloc(0))])}
const e=new V86({wasm_path:"node_modules/v86/build/v86.wasm",bios:{buffer:new Uint8Array(fs.readFileSync("bios/seabios.bin")).buffer},vga_bios:{buffer:new Uint8Array(fs.readFileSync("bios/vgabios.bin")).buffer},fda:{buffer:new Uint8Array(fs.readFileSync(img)).buffer},memory_size:64*1024*1024,disable_keyboard:false,vga_memory_size:8*1024*1024,screen_dummy:true,autostart:true});
function capture(name){
  const v=e.v86.cpu.devices.vga;
  if(v.svga_enabled||v.graphical_mode){
    let w,h,idx;
    if(v.svga_enabled){w=v.svga_width;h=v.svga_height;idx=v.svga_memory.subarray(0,w*h)}
    else{w=320;h=200;v.vga_replot();v.vga_redraw();idx=v.pixel_buffer.subarray(0,64000)}
    const P=v.vga256_palette||new Int32Array(256),rgb=Buffer.alloc(w*h*3);
    for(let i=0;i<w*h;i++){const c=P[idx[i]];rgb[i*3]=(c>>16)&255;rgb[i*3+1]=(c>>8)&255;rgb[i*3+2]=c&255}
    fs.writeFileSync(name+".png",png(w,h,rgb));fs.writeFileSync(name+".idx",Buffer.from(idx));console.log(`${name}.png ${w}x${h}`)
  } else {
    const t=e.screen_adapter.get_text_screen().map(l=>l.replace(/\s+$/,"")).join("\n").replace(/\n+$/,"");
    fs.writeFileSync(name+".txt",t+"\n");console.log(`${name}.txt text`)}
}
for(const it of plan.split(";").filter(Boolean)){
  if(it[0]==="@"){const t=+it.slice(1);setTimeout(()=>capture(`${out}_${t}`),t*1000);continue}
  const [t,s]=it.split(":");const b=s.trim().split(/\s+/).map(x=>parseInt(x,16));
  setTimeout(()=>e.keyboard_send_scancodes(b),+t*1000);
  if(b.length===1)setTimeout(()=>e.keyboard_send_scancodes([b[0]|0x80]),+t*1000+60)}
setTimeout(()=>{capture(out);
  if(memreq){const [a,n,f]=memreq.split(":");fs.writeFileSync(f,Buffer.from(e.read_memory(parseInt(a),parseInt(n))));console.log(`mem ${a}+${n} -> ${f}`)}
  e.destroy();process.exit(0)},secs*1000);
