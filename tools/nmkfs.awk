# tools/nmkfs.awk - one-time host seed: text on stdin -> NaNFS disk image as shell-printf octal escapes on stdout.
# Volume (32-bit words, each stored as two LE u16 = how ata_read28 sees them), sectors = 128 words = 2 blocks:
#   block0 superblock: [0]=NF_MAGIC [1]=nblocks [2]=free [3]=2 [4]=text words (4 chars/word LE, NUL padded, +1 NUL word)
#   bitmap from block 1 (1 word per block, 1=used, ceil(nblocks/64) blocks); [3]=first data block, which holds the text words.
BEGIN{ for(i=1;i<256;i++) O[sprintf("%c",i)]=i; O[""]=0 }
{ T=T $0 "\n" }
END{
  n=length(T); nw=int((n+3)/4)+1; nd=int((nw+63)/64); nbm=1
  do { nb=1+nbm+nd; if(nb%2) nb++; q=int((nb+63)/64); ch=(q!=nbm); nbm=q } while(ch)
  fb=1+nbm; for(i=0;i<nb*64;i++) W[i]=0
  W[0]=1313231665; W[1]=nb; W[2]=nb-fb-nd; W[3]=fb; W[4]=nw
  for(b=0;b<fb+nd;b++) W[64+b]=1
  for(i=0;i<n;i++){ c=substr(T,i+1,1); k=(i-i%4)/4; m=1; for(j=0;j<i%4;j++) m*=256; W[64*fb+k]+=O[c]*m }
  for(i=0;i<nb*64;i++){ v=W[i]; for(j=0;j<4;j++){ printf "\\0%03o", v%256; v=int(v/256) } }
}
