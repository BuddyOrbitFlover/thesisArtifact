#!/bin/bash
# fl_san.sh: sanitized-classpath GZoltar retry for the 7 classpath-attrition
# FL bugs (6 JAVA9-CLASSFILE + 1 JUNIT-CONFLICT). Spoon_16_1 excluded
# (internal timeout, different failure class).
# Fixes are Java-8-semantics-neutral tooling adaptations:
#   - jar copies without module-info.class + META-INF/versions/* (the Java 8
#     runtime never reads either entry; only GZoltar's javassist scan did)
#   - exactly one junit on the cp, newest first (an older junit earlier on
#     the cp shadowed JUnit4 symbols GZoltar needs)
# Writes only: $W/sancp/, $W/cp_san.txt, FLDIAG/<bug>/, fl_san.log.
# Originals (cp.txt, project jars, /catena/FL) untouched. No global java pkill.
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
LOG=/catena/flprobe/fl_san.log
mkdir -p /catena/flprobe/FLDIAG

cat > /catena/flprobe/cp_sanitize.py <<'PYEOF'
#!/usr/bin/env python3
# Rewrite a GZoltar classpath so javassist can scan it under Java 8.
# argv: cp_file outdir. Prints sanitized cp on stdout, diagnostics on stderr.
import sys, os, re, zipfile

cp_file, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
entries = [e for e in open(cp_file).read().strip().split(":") if e]

def bad(n):
    return (n == "module-info.class" or n.endswith("/module-info.class")
            or n.startswith("META-INF/versions/"))

def sanitize_jar(path, idx):
    try:
        zin = zipfile.ZipFile(path)
    except Exception as e:
        print("  keep (unreadable zip: %s): %s" % (e, path), file=sys.stderr)
        return path
    hits = [n for n in zin.namelist() if bad(n)]
    if not hits:
        zin.close()
        return path
    out = os.path.join(outdir, "%02d_%s" % (idx, os.path.basename(path)))
    with zipfile.ZipFile(out, "w") as zout:
        for item in zin.infolist():
            if bad(item.filename):
                continue
            zout.writestr(item, zin.read(item.filename))
    zin.close()
    print("  sanitized (%d entries removed): %s" % (len(hits), os.path.basename(path)), file=sys.stderr)
    return out

def is_junit(e):
    b = os.path.basename(e)
    return b == "junit.jar" or re.match(r"junit[-._]?\d.*\.jar$", b) is not None

def junit_ver(e):
    m = re.search(r"junit[-._]?(\d+(?:\.\d+)*)", os.path.basename(e))
    return tuple(int(x) for x in m.group(1).split(".")) if m else (0,)

junits = [e for e in entries if is_junit(e)]
rest = [e for e in entries if not is_junit(e)]
ordered = []
if junits:
    best = max(junits, key=junit_ver)
    for j in junits:
        if j != best:
            print("  dropped junit: %s" % j, file=sys.stderr)
    print("  junit kept first: %s" % best, file=sys.stderr)
    ordered.append(best)
ordered += rest
final = []
for i, e in enumerate(ordered):
    if e.endswith(".jar") and os.path.isfile(e):
        final.append(sanitize_jar(e, i))
    else:
        final.append(e)
print(":".join(final))
PYEOF

for BUG in Cli_parser_1_1 Shiro_core_203_1 Zip4j_35_1 Zip4j_39_1 Zip4j_44_1 Zip4j_46_1 Zip4j_47_1; do
  C=${BUG##*_}; REST=${BUG%_*}; B=${REST##*_}; P=${REST%_*}
  W=/catena/flprobe/$BUG
  echo "=== $BUG $(date)" >> $LOG
  cd "$W" || { echo "$BUG NO WORKDIR" >> $LOG; continue; }
  [ -s cp.txt ] || defects4j export -p cp.test -o cp.txt 2>/dev/null
  [ -s cp.txt ] || { echo "$BUG NO CP" >> $LOG; continue; }
  python3 /catena/flprobe/cp_sanitize.py "$W/cp.txt" "$W/sancp" > "$W/cp_san.txt" 2>> $LOG \
    || { echo "$BUG SANITIZE-FAIL" >> $LOG; continue; }
  LC=/gb/framework/projects/$P/loaded_classes/$B.src
  RT=/gb/framework/projects/$P/relevant_tests/$B
  TC=$(while read c; do printf "%s:%s\$*:" "$c" "$c"; done < "$LC"); TC=${TC%:}
  TESTC=$(paste -sd: "$RT")
  rm -rf "$W/gzoltar-data"
  timeout -k 30 5400 java -jar /catena/gzoltar-1.6.0.jar -diagnose \
    -Dproject_cp="$(cat cp_san.txt)" \
    -Dtargetclasses="$TC" \
    -Dtestclasses="$TESTC" \
    -Dgzoltar_data_dir=$W/gzoltar-data \
    -Dtest_case_timeout=120 \
    -Dshow_progress_bar=false > gzoltar_san.log 2>&1
  rc=$?
  if [ -f $W/gzoltar-data/spectra ]; then
    mkdir -p /catena/flprobe/FLDIAG/$BUG
    python3 /catena/gz2ranking.py $W/gzoltar-data/spectra /catena/flprobe/FLDIAG/$BUG/ochiai.ranking.txt
    FR=$(awk "{print \$NF}" $W/gzoltar-data/matrix | grep -c "^-$")
    echo "$BUG OK rc=$rc failing_tests=$FR ranking_lines=$(wc -l < /catena/flprobe/FLDIAG/$BUG/ochiai.ranking.txt)" >> $LOG
  else
    echo "$BUG GZOLTAR-FAIL rc=$rc tail: $(tail -n 3 gzoltar_san.log | tr "\n" " " | cut -c1-200)" >> $LOG
  fi
  pkill -9 -f "[g]zoltar-1.6.0.jar" 2>/dev/null
done
curl -s -d "FL sanitized retry: 7 gzoltar runs finished" https://ntfy.sh/klee-tbar-9x42qz > /dev/null
echo "=== ALL DONE $(date)" >> $LOG
