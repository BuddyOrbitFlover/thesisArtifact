import sys
src, dst = sys.argv[1], sys.argv[2]
rows = []
for ln in open(src):
    ln = ln.strip()
    if not ln or ln.startswith("Component,"):
        continue
    comp, score = ln.rsplit(",", 1)
    try:
        sc = float(score)
    except ValueError:
        continue
    pkg = comp.split("[", 1)[0]
    canon = comp.split("<", 1)[1].split("{", 1)[0]
    meth = comp.split("{", 1)[1].rsplit("#", 1)[0]
    line = comp.rsplit("#", 1)[1]
    cls = canon[len(pkg) + 1:] if canon.startswith(pkg + ".") else canon
    rows.append((sc, "%s$%s#%s():%s;%s" % (pkg, cls, meth, line, score)))
rows.sort(key=lambda x: -x[0])
with open(dst, "w") as f:
    for r in rows:
        f.write(r[1] + "\n")
print("wrote %d components" % len(rows))
