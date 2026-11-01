# tools/nflat.awk - one-time host seed: flatten .include and strip comments/blank lines (what nasm0 reads).
# usage: awk -f tools/nflat.awk -v F=src/tests/nfix_test.nas
function dirof(p,  i){ i=match(p,/\/[^\/]*$/); return i? substr(p,1,i) : "" }
function flat(path,  line,s,q,c,i,cut,inc,d){
  d=dirof(path)
  while ((getline line < path) > 0) {
    sub(/\r$/,"",line); q=0; cut=length(line)+1
    for (i=1;i<=length(line);i++){ c=substr(line,i,1); if(c=="\"")q=!q; else if(c=="\\"&&q)i++; else if(c==";"&&!q){cut=i;break} }
    s=substr(line,1,cut-1); sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s)
    if (s=="") continue
    if (s ~ /^\.include[ \t]+"/) { inc=s; sub(/^\.include[ \t]+"/,"",inc); sub(/".*$/,"",inc); flat(d inc); continue }
    print s
  }
  close(path)
}
BEGIN{ flat(F) }
