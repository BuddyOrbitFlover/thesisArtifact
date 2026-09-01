#!/bin/bash
# fl_s5.sh — FL for the final-campaign sub-bugs (S5/S2 survivors).
# Pilot rq2_fl.sh protocol + the two 2026-08 lessons baked in:
#   - sanitized classpath via /catena/flprobe/cp_sanitize.py (javassist scan)
#   - -Dtimelimit=10000 (GZoltar global cap, default 600 s, too small)
#   - NO global java pkill (TBar workers are running) — scoped setsid reap
# Reads bug list from /catena/fl_s5_bugs.txt; resumable (skips adopted FL).
# Writes /catena/FL/<bug>/{ochiai.ranking.txt,cp.txt,info.txt}; work in /tmp/fl_s5.
exec 9>/tmp/fl_s5.lock
flock -n 9 || { echo "fl_s5 already running - abort"; exit 1; }
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
mkdir -p /catena/FL /tmp/fl_s5
LOG=/catena/fl_s5.log
{
echo "=== fl_s5 start $(date) bugs: $(paste -sd" " /catena/fl_s5_bugs.txt)"
while read BUG; do
  [ -z "$BUG" ] && continue
  C=${BUG##*_}; REST=${BUG%_*}; B=${REST##*_}; P=${REST%_*}
  if [ -s /catena/FL/$BUG/ochiai.ranking.txt ]; then echo "$BUG: already adopted, skip"; continue; fi
  echo "=== $BUG (proj=$P bid=$B cid=$C) $(date)"
  LC=/gb/framework/projects/$P/loaded_classes/$B.src
  RT=/gb/framework/projects/$P/relevant_tests/$B
  [ -f "$LC" ] || { echo "$BUG FAIL no loaded_classes"; continue; }
  [ -f "$RT" ] || { echo "$BUG FAIL no relevant_tests"; continue; }
  TC=$(while read c; do printf "%s:%s\$*:" "$c" "$c"; done < $LC); TC=${TC%:}
  TESTC=$(paste -sd: $RT)
  W=/tmp/fl_s5/$BUG
  rm -rf $W
  catena4j checkout -p $P -v ${B}b${C} -w $W > /tmp/fl_s5/$BUG.checkout.log 2>&1 || { echo "$BUG FAIL checkout"; continue; }
  cd $W
  defects4j compile > compile.log 2>&1 || { echo "$BUG FAIL compile"; continue; }
  defects4j export -p cp.test -o cp.txt 2>/dev/null
  [ -s cp.txt ] || { echo "$BUG FAIL cp-export"; continue; }
  python3 /catena/flprobe/cp_sanitize.py "$W/cp.txt" "$W/sancp" > "$W/cp_san.txt" 2>> /tmp/fl_s5/$BUG.san.log \
    || { echo "$BUG FAIL sanitize"; continue; }
  setsid timeout -k 30 10800 java -jar /catena/gzoltar-1.6.0.jar -diagnose \
    -Dproject_cp="$(cat cp_san.txt)" \
    -Dtargetclasses="$TC" \
    -Dtestclasses="$TESTC" \
    -Dgzoltar_data_dir=$W/gzoltar-data \
    -Dtest_case_timeout=1200 \
    -Dtimelimit=10000 \
    -Dshow_progress_bar=false > gzoltar.log 2>&1 &
  GP=$!
  wait $GP
  kill -9 -- -$GP 2>/dev/null
  [ -f $W/gzoltar-data/spectra ] || { echo "$BUG FAIL gzoltar started=$(grep -c "Started " gzoltar.log) finished=$(grep -c "Finished " gzoltar.log) tail: $(grep -m1 -E "Process terminated|Exception|Error" gzoltar.log | cut -c1-140)"; continue; }
  FR=$(awk "{print \$NF}" $W/gzoltar-data/matrix | grep -c "^-$")
  mkdir -p /catena/FL/$BUG
  python3 /catena/gz2ranking.py $W/gzoltar-data/spectra /catena/FL/$BUG/ochiai.ranking.txt
  cp $W/cp.txt /catena/FL/$BUG/cp.txt   # ORIGINAL cp for TBar, not the sanitized one
  echo "failing_tests=$FR protocol=relevant_tests sanitizer+timelimit10000" > /catena/FL/$BUG/info.txt
  echo "$BUG OK failing_tests=$FR ranking_lines=$(wc -l < /catena/FL/$BUG/ochiai.ranking.txt) triggers_registered=$(wc -l < /catena/projects/$P/$B/$C.tests.trigger 2>/dev/null)"
done < /catena/fl_s5_bugs.txt
echo "=== fl_s5 DONE $(date)"
curl -s -d "fl_s5: FL batch finished" https://ntfy.sh/klee-tbar-9x42qz > /dev/null
} >> $LOG 2>&1
