#!/bin/bash
# fl_san2.sh: second-pass GZoltar retry for the Zip4j FL bugs. First pass
# (fl_san.sh) fixed the javassist classpath scan; the runs then died on a
# timeout. Probe 2026-08-10 proved the binding cap is GZoltar's GLOBAL
# `timelimit` (default 600 s, listParameters-confirmed) -- the 607 s wall --
# not test_case_timeout. This pass raises both.
#   TCT   per-test timeout seconds (default 1200)
#   TL    GZoltar global timelimit seconds (default 10000, < OUTER)
#   OUTER outer wall cap per bug seconds (default 10800)
# Usage: fl_san2.sh [bug ...]   (default: all 5 Zip4j; skips bugs that
# already have a FLDIAG ranking -> resumable)
# Writes only: $W/gzoltar_san2.log, $W/gzoltar-data (recreated),
# FLDIAG/<bug>/, fl_san2.log. Reuses cp_san.txt from pass 1 (regenerates via
# /catena/flprobe/cp_sanitize.py if missing). No global java pkill.
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
TCT=${TCT:-1200}
TL=${TL:-10000}
OUTER=${OUTER:-10800}
LOG=/catena/flprobe/fl_san2.log
mkdir -p /catena/flprobe/FLDIAG

BUGS="$@"
[ -z "$BUGS" ] && BUGS="Zip4j_35_1 Zip4j_39_1 Zip4j_44_1 Zip4j_46_1 Zip4j_47_1"

echo "=== fl_san2 start $(date) TCT=$TCT TL=$TL OUTER=$OUTER bugs: $BUGS" >> $LOG
for BUG in $BUGS; do
  if [ -s /catena/flprobe/FLDIAG/$BUG/ochiai.ranking.txt ]; then
    echo "$BUG SKIP (ranking exists)" >> $LOG; continue
  fi
  C=${BUG##*_}; REST=${BUG%_*}; B=${REST##*_}; P=${REST%_*}
  W=/catena/flprobe/$BUG
  echo "=== $BUG $(date)" >> $LOG
  cd "$W" || { echo "$BUG NO WORKDIR" >> $LOG; continue; }
  if [ ! -s cp_san.txt ]; then
    [ -s cp.txt ] || defects4j export -p cp.test -o cp.txt 2>/dev/null
    [ -s cp.txt ] || { echo "$BUG NO CP" >> $LOG; continue; }
    python3 /catena/flprobe/cp_sanitize.py "$W/cp.txt" "$W/sancp" > "$W/cp_san.txt" 2>> $LOG \
      || { echo "$BUG SANITIZE-FAIL" >> $LOG; continue; }
  fi
  LC=/gb/framework/projects/$P/loaded_classes/$B.src
  RT=/gb/framework/projects/$P/relevant_tests/$B
  TC=$(while read c; do printf "%s:%s\$*:" "$c" "$c"; done < "$LC"); TC=${TC%:}
  TESTC=$(paste -sd: "$RT")
  rm -rf "$W/gzoltar-data"
  timeout -k 30 $OUTER java -jar /catena/gzoltar-1.6.0.jar -diagnose \
    -Dproject_cp="$(cat cp_san.txt)" \
    -Dtargetclasses="$TC" \
    -Dtestclasses="$TESTC" \
    -Dgzoltar_data_dir=$W/gzoltar-data \
    -Dtest_case_timeout=$TCT \
    -Dtimelimit=$TL \
    -Dshow_progress_bar=false > gzoltar_san2.log 2>&1
  rc=$?
  if [ -f $W/gzoltar-data/spectra ]; then
    mkdir -p /catena/flprobe/FLDIAG/$BUG
    python3 /catena/gz2ranking.py $W/gzoltar-data/spectra /catena/flprobe/FLDIAG/$BUG/ochiai.ranking.txt
    FR=$(awk "{print \$NF}" $W/gzoltar-data/matrix | grep -c "^-$")
    echo "$BUG OK rc=$rc failing_tests=$FR ranking_lines=$(wc -l < /catena/flprobe/FLDIAG/$BUG/ochiai.ranking.txt) started=$(grep -c "Started " gzoltar_san2.log) finished=$(grep -c "Finished " gzoltar_san2.log)" >> $LOG
  else
    echo "$BUG GZOLTAR-FAIL rc=$rc started=$(grep -c "Started " gzoltar_san2.log) finished=$(grep -c "Finished " gzoltar_san2.log) tail: $(grep -m1 -E "Process terminated|Exception|Error" gzoltar_san2.log | cut -c1-160)" >> $LOG
  fi
  pkill -9 -f "[g]zoltar-1.6.0.jar" 2>/dev/null
done
curl -s -d "fl_san2: Zip4j FL retry pass finished" https://ntfy.sh/klee-tbar-9x42qz > /dev/null
echo "=== ALL DONE $(date)" >> $LOG
