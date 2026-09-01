#!/usr/bin/env python3
# coordfix.py: rewrite the 10 mis-exported patch JSONs from git ground truth.
# Per bug: map JSON hunks 1:1 (order + type) onto difflib opcodes between the
# BUGGY and FIXED commits; rewrite coordinates and content from git; verify by
# replay (must equal FIXED byte-wise) BEFORE writing; backup-first; abort the
# bug untouched on any mismatch.
import json, subprocess, difflib, shutil, sys

BUGS = ["RTree_1","RTree_6","RTree_7","Wicket_core_1","Javapoet_2","Zip4j_1",
        "Tika_core_9","Tika_core_23","Dropwizard_spring_1","JacksonModuleJsonSchema_1"]
BAK = ".bak20260806"

def git_show(wd, ref, path):
    r = subprocess.run(["git","-C",wd,"show",f"{ref}:{path}"],
                       capture_output=True, text=True)
    return r.stdout.splitlines(keepends=True) if r.returncode==0 else None

def find_commit(wd, marker):
    r = subprocess.run(["git","-C",wd,"log","--format=%H %s"],
                       capture_output=True, text=True)
    for line in r.stdout.splitlines():
        h,_,s = line.partition(" ")
        if marker in s: return h
    return None

def replay(b, hunks):
    edits=[]
    for i,h in enumerate(hunks):
        t=h["patch_type"]
        if t=="insert": edits.append((h["next_line_no"],i,t,0,h.get("replaced_with") or ""))
        elif t=="delete": edits.append((h["from_line_no"],i,t,h["to_line_no"]-h["from_line_no"]+1,""))
        else: edits.append((h["from_line_no"],i,t,h["to_line_no"]-h["from_line_no"]+1,h.get("replaced_with") or ""))
    out=list(b)
    for pos,i,t,cnt,txt in sorted(edits,reverse=True):
        new=txt.splitlines(keepends=True)
        if t=="insert": out[pos-1:pos-1]=new
        elif t=="delete": del out[pos-1:pos-1+cnt]
        else: out[pos-1:pos-1+cnt]=new
    return out

fixed_n=0
for bug in BUGS:
    proj,bid = bug.rsplit("_",1)
    wd = f"/catena/scripts/gb_diag/working/data/{bug}"
    jp = f"/catena/scripts/parse_patches/patches/{proj}/{bid}.json"
    print(f"===== {bug}")
    pj = json.load(open(jp))
    keys = sorted((k for k in pj if k.isdigit()), key=int)
    hunks = [pj[k] for k in keys]
    bc = find_commit(wd,"BUGGY_VERSION"); fc = find_commit(wd,"FIXED_VERSION")
    if not (bc and fc): print("  ABORT: git refs missing"); continue
    ok=True
    for fn in sorted(set(h["file_name"] for h in hunks)):
        b = git_show(wd,bc,fn); f = git_show(wd,fc,fn)
        if b is None or f is None: print(f"  ABORT: {fn} missing in git"); ok=False; break
        fh = [h for h in hunks if h["file_name"]==fn]
        sm = difflib.SequenceMatcher(None,b,f,autojunk=False)
        ops = [o for o in sm.get_opcodes() if o[0]!="equal"]
        if len(ops)!=len(fh):
            print(f"  ABORT: {fn} opcode count {len(ops)} != hunks {len(fh)}"); ok=False; break
        typemap={"insert":"insert","delete":"delete","replace":"replace"}
        for (tag,i1,i2,j1,j2),h in zip(ops,fh):
            if typemap[tag]!=h["patch_type"]:
                print(f"  ABORT: {fn} type {tag} vs {h['patch_type']}"); ok=False; break
            if tag=="insert":
                h["next_line_no"]=i1+1
                h["replaced_with"]="".join(f[j1:j2])
            elif tag=="delete":
                h["from_line_no"]=i1+1; h["to_line_no"]=i2
                h["replaced"]="".join(b[i1:i2])
                h["next_line_no"]=i2+1
            else:
                h["from_line_no"]=i1+1; h["to_line_no"]=i2
                h["replaced"]="".join(b[i1:i2])
                h["replaced_with"]="".join(f[j1:j2])
                h["next_line_no"]=i2+1
        if not ok: break
        if replay(b,fh)!=f:
            print(f"  ABORT: {fn} replay after rewrite still != FIXED"); ok=False; break
        print(f"  {fn}: rewrite verified (replay == FIXED)")
    if not ok: continue
    shutil.copy(jp, jp+BAK)
    json.dump(pj, open(jp,"w"), indent=4)
    print(f"  WRITTEN {jp} (backup {jp+BAK})")
    fixed_n+=1
print(f"== fixed {fixed_n}/{len(BUGS)} bugs")
