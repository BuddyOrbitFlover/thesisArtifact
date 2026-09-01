#!/bin/bash
exec 9>/tmp/rq2tbar2.lock
flock -n 9 || { echo "rq2_tbar2 already running - abort"; exit 1; }
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -XX:ActiveProcessorCount=5"
cd /catena/tbar || exit 1
mkdir -p OUTPUT/NormalFL/TBar RESULTS_GB2/done RESULTS_GB2/fixed /tbar_log
{
echo "=== RQ2 RE-RUN TBAR START $(date) ==="
while read BUG; do
  [ -z "$BUG" ] && continue
  if [ -e RESULTS_GB2/done/$BUG ]; then echo "$BUG: done, skip"; continue; fi
  mkdir -p C4J_location/105SampleBugsResult/$BUG
  cp -f /catena/FL/$BUG/ochiai.ranking.txt C4J_location/105SampleBugsResult/$BUG/ochiai.ranking.txt
  export TBAR_EXTRA_CP=$(cat /catena/FL/$BUG/cp.txt)
  echo "--- $BUG start $(date) ---"
  echo $BUG > /tmp/one_bug2.txt
  timeout -k 60 19000 python3 runTBarForCatenaD4J.py 0 0 /catena/tbar /tmp/one_bug2.txt /gb
  for kind in FixedBugs PartiallyFixedBugs; do
    for d in OUTPUT/NormalFL/TBar/*/$kind/$BUG; do
      [ -d "$d" ] && mkdir -p RESULTS_GB2/fixed/$BUG && cp -r "$d" RESULTS_GB2/fixed/$BUG/$(basename $(dirname $(dirname $d)))_$kind
    done
  done
  touch RESULTS_GB2/done/$BUG
  echo "--- $BUG end $(date) fixed_dirs=$(ls RESULTS_GB2/fixed/$BUG 2>/dev/null | wc -l) ---"
  pkill -9 -f "[j]ava" 2>/dev/null
  sleep 3
done < /catena/rq2_rerun_bugs.txt
echo "=== RQ2 RE-RUN TBAR DONE $(date) ==="
touch /catena/rq2tbar2.done
curl -s -d "RQ2 re-run TBar (14 growingBugs sub-bugs) FINISHED" https://ntfy.sh/klee-tbar-9x42qz > /dev/null
} > /catena/tbar/rq2_tbar2.log 2>&1
