#!/bin/bash
exec 9>/tmp/rq2tbar.lock
flock -n 9 || { echo "rq2_tbar already running - abort"; exit 1; }
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -XX:ActiveProcessorCount=5"
cd /catena/tbar
mkdir -p OUTPUT/NormalFL/TBar RESULTS_GB/done RESULTS_GB/fixed /tbar_log
{
echo "=== RQ2 TBAR START $(date) ==="
for BUG in Text_2_2 Jfreesvg_1_1 Graph_3_2 Bcel_2_1 Bcel_2_2; do
  if [ -e RESULTS_GB/done/$BUG ]; then echo "$BUG: done, skip"; continue; fi
  [ -f /catena/FL/$BUG/cp.txt ] || cp /tmp/rq2fl/$BUG/cp.txt /catena/FL/$BUG/cp.txt
  export TBAR_EXTRA_CP=$(cat /catena/FL/$BUG/cp.txt)
  echo "--- $BUG start $(date) ---"
  echo $BUG > /tmp/one_bug.txt
  timeout -k 60 19000 python3 runTBarForCatenaD4J.py 0 0 /catena/tbar /tmp/one_bug.txt /gb
  for kind in FixedBugs PartiallyFixedBugs; do
    for d in OUTPUT/NormalFL/TBar/*/$kind/$BUG; do
      [ -d "$d" ] && mkdir -p RESULTS_GB/fixed/$BUG && cp -r "$d" RESULTS_GB/fixed/$BUG/$(basename $(dirname $(dirname $d)))_$kind
    done
  done
  touch RESULTS_GB/done/$BUG
  echo "--- $BUG end $(date) fixed_dirs=$(ls RESULTS_GB/fixed/$BUG 2>/dev/null | wc -l) ---"
  pkill -9 -f "[j]ava" 2>/dev/null
  sleep 3
done
echo "=== RQ2 TBAR DONE $(date) ==="
curl -s -d "RQ2 TBar run on 5 growingBugs sub-bugs FINISHED" https://ntfy.sh/klee-tbar-9x42qz > /dev/null
} > /catena/tbar/rq2_tbar.log 2>&1
