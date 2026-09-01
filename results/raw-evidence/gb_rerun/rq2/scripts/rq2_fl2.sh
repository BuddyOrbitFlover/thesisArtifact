#!/bin/bash
# RQ2 re-run FL: GZoltar 1.6.0 Ochiai per sub-bug (pilot rq2_fl.sh, parameterized for the 14)
exec 9>/tmp/rq2fl2.lock
flock -n 9 || { echo "rq2_fl2 already running - abort"; exit 1; }
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
mkdir -p /catena/FL /tmp/rq2fl2
while read BUG; do
  [ -z "$BUG" ] && continue
  C=${BUG##*_}; REST=${BUG%_*}; B=${REST##*_}; P=${REST%_*}
  if [ -s /catena/FL/$BUG/ochiai.ranking.txt ]; then echo "$BUG: already done, skip"; continue; fi
  echo "=== $BUG (proj=$P bid=$B cid=$C) $(date) ==="
  LC=/gb/framework/projects/$P/loaded_classes/$B.src
  RT=/gb/framework/projects/$P/relevant_tests/$B
  [ -f $LC ] || { echo "FAIL no loaded_classes for $BUG"; continue; }
  [ -f $RT ] || { echo "FAIL no relevant_tests for $BUG"; continue; }
  TC=$(while read c; do printf "%s:%s\$*:" "$c" "$c"; done < $LC); TC=${TC%:}
  TESTC=$(paste -sd: $RT)
  W=/tmp/rq2fl2/$BUG
  rm -rf $W
  catena4j checkout -p $P -v ${B}b${C} -w $W > /tmp/rq2fl2/$BUG.checkout.log 2>&1 || { echo "FAIL checkout $BUG"; continue; }
  cd $W
  defects4j compile > compile.log 2>&1 || { echo "FAIL compile $BUG"; continue; }
  defects4j export -p cp.test -o cp.txt 2>/dev/null
  timeout -k 30 5400 java -jar /catena/gzoltar-1.6.0.jar -diagnose \
    -Dproject_cp="$(cat cp.txt)" \
    -Dtargetclasses="$TC" \
    -Dtestclasses="$TESTC" \
    -Dgzoltar_data_dir=$W/gzoltar-data \
    -Dtest_case_timeout=120 \
    -Dshow_progress_bar=false > gzoltar.log 2>&1
  [ -f $W/gzoltar-data/spectra ] || { echo "FAIL gzoltar $BUG (see $W/gzoltar.log)"; continue; }
  FR=$(awk "{print \$NF}" $W/gzoltar-data/matrix | grep -c "^-$")
  NZ=$(awk -F, "\$2 > 0" $W/gzoltar-data/spectra | wc -l)
  mkdir -p /catena/FL/$BUG
  python3 /catena/gz2ranking.py $W/gzoltar-data/spectra /catena/FL/$BUG/ochiai.ranking.txt
  cp $W/cp.txt /catena/FL/$BUG/cp.txt
  echo "failing_tests=$FR nonzero_components=$NZ protocol=relevant_tests" > /catena/FL/$BUG/info.txt
  echo "$BUG: failing_tests=$FR nonzero=$NZ ranking_lines=$(wc -l < /catena/FL/$BUG/ochiai.ranking.txt)"
  pkill -9 -f "[j]ava" 2>/dev/null
  sleep 2
done < /catena/rq2_rerun_bugs.txt
echo "=== RQ2-RERUN FL DONE $(date) ==="
touch /catena/rq2fl2.done
