#!/usr/bin/env python3
# SCAFFOLD (not NaN/0S): render a VGA text dump (mode,cols,rows + char/attr pairs) from cap.mjs to a PNG screencap.
# usage: shot.py dump.bin out.png [scale]
import sys
from PIL import Image, ImageDraw, ImageFont
PAL=[(0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),(170,85,0),(170,170,170),
     (85,85,85),(85,85,255),(85,255,85),(85,255,255),(255,85,85),(255,85,255),(255,255,85),(255,255,255)]
d=open(sys.argv[1],'rb').read(); mode,cols,rows=d[0],d[1],d[2]; body=d[3:]
CW,CH=9,16; sc=int(sys.argv[3]) if len(sys.argv)>3 else 2
im=Image.new('RGB',(cols*CW,rows*CH),(0,0,0)); dr=ImageDraw.Draw(im)
F=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',14)
for i in range(cols*rows):
    ch,at=body[2*i],body[2*i+1]; x,y=(i%cols)*CW,(i//cols)*CH
    bg=PAL[(at>>4)&7]; fg=PAL[at&15]
    dr.rectangle([x,y,x+CW-1,y+CH-1],fill=bg)
    c=bytes([ch]).decode('cp437') if ch>=32 else ' '
    if c in '█': dr.rectangle([x,y,x+CW-1,y+CH-1],fill=fg)
    elif c=='▀': dr.rectangle([x,y,x+CW-1,y+CH//2-1],fill=fg)
    elif c=='▄': dr.rectangle([x,y+CH//2,x+CW-1,y+CH-1],fill=fg)
    elif c in '░▒▓':
        a={'░':.25,'▒':.5,'▓':.75}[c]; col=tuple(int(bg[k]+(fg[k]-bg[k])*a) for k in range(3)); dr.rectangle([x,y,x+CW-1,y+CH-1],fill=col)
    elif c!=' ': dr.text((x,y-1),c,font=F,fill=fg)
if cols<=40: im=im.resize((im.width*2,im.height),Image.NEAREST) if False else im
im=im.resize((im.width*sc//2 if sc>1 else im.width,im.height*sc//2 if sc>1 else im.height),Image.NEAREST) if sc!=2 else im
im.save(sys.argv[2]); print(sys.argv[2],im.size,'mode',mode,cols,'x',rows)
