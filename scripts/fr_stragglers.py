#!/usr/bin/env python3
"""fr_stragglers.py — translate French comments the main extractor missed.

`extract` selects lines with `is_french`, and that detector under-called unaccented
French (`son formulaire y ajoutait un profil`) — 26 such lines survived a full run on
2026-10-16. This pass re-reads every already-modified file, translates whatever still
reads as French, and re-checks the code skeleton before writing. It loops to a fixed
point: round N+1 only sees what round N failed to convert, so it terminates.

Run after `apply`:
    python3 scripts/fr_comments.py apply
    python3 scripts/fr_stragglers.py
    python3 scripts/fr_comments.py verify
"""
import subprocess,re,json,os,importlib.util,collections
spec=importlib.util.spec_from_file_location("fc","scripts/fr_comments.py")
fc=importlib.util.module_from_spec(spec); spec.loader.exec_module(fc)
def deg(o):
    o=o.strip()
    if not o: return True
    tk=re.findall(r"\S+",o)
    if len(tk)>=6 and max(collections.Counter(tk).values())>max(4,int(len(tk)*0.4)): return True
    return fc.is_french(o)
def tr(t):
    r=subprocess.run(["tg-translate","fr","en","/dev/stdin","--model","box","--max-tokens","160"],
                     input=t,capture_output=True,text=True)
    return r.stdout.strip()
total=0
for rnd in range(1,5):
    files=[f for f in subprocess.run(["git","diff","--name-only"],capture_output=True,text=True).stdout.split() if f.endswith(".dart")]
    jobs=[]
    for f in files:
        src=open(f,encoding="utf-8").read(); sk=fc.code_skeleton(src).split("\n")
        for i,l in enumerate(src.split("\n"),1):
            s=l.strip()
            if not s.startswith("//"): continue
            body=s.lstrip("/").strip()
            if fc.is_french(body): jobs.append((f,i,l,body))
    print(f"\n### round {rnd}: {len(jobs)} French line(s)")
    if not jobs: break
    edits={}
    for f,i,l,body in jobs:
        out=tr(body)
        if deg(out):
            print(f"  KEEP-FRENCH {f}:{i}\n     FR: {body[:70]}\n     EN: {out[:70]!r}"); continue
        edits.setdefault(f,[]).append((i,(len(l)-len(l.lstrip())),out))
    for f,e in edits.items():
        src=open(f,encoding="utf-8").read(); before=fc.code_skeleton(src); L=src.split("\n")
        for ln,indent,new in e:
            marker="///" if L[ln-1].strip().startswith("///") else "//"
            L[ln-1]=" "*indent+marker+" "+new
        ns="\n".join(L)
        if fc.code_skeleton(ns)!=before:
            print(f"  ABORT skeleton {f}"); continue
        open(f,"w",encoding="utf-8").write(ns); total+=len(e)
    print(f"  applied {len(edits)} file(s)")
print(f"\ntotal comment lines fixed by straggler rounds: {total}")
