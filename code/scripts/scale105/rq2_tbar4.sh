#!/bin/bash
# rq2_tbar4.sh — final RQ2 TBar campaign, 4 workers, shared-list claim model.
# Queue file: /catena/gb4_bugs.txt (append survivors + relaunch = resumable;
# done/ markers skip finished bugs, stale claims cleared at start).
# Per-bug: install ranking into worker C4J_location, TBAR_EXTRA_CP from
# /catena/FL/<bug>/cp.txt, paper 5h cap (timeout -k 60 19000), process-group
# scoped reap (NO global java pkill — other harnesses may be running).
exec 9>/tmp/rq2tbar4.lock
flock -n 9 || { echo "rq2_tbar4 already running - abort"; exit 1; }
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -XX:ActiveProcessorCount=5"
N=4
LIST=/catena/gb4_bugs.txt
BASE=/catena/tbar
RES=$BASE/RESULTS_GB4
mkdir -p $RES/done $RES/fixed
rm -f /catena/gb4.done   # stale finish marker from a previous (failed) run
rm -rf $RES/claim_*   # stale claims from a killed run (no workers live: flock held)
for i in $(seq 1 $N); do
  W=/catena/wk4_$i
  if [ ! -d $W ]; then   # tar pipe: rsync is not guaranteed inside the container
    mkdir -p $W
    tar -C $BASE --exclude "./RESULTS*" --exclude "./OUTPUT" --exclude "./D4J" -cf - . | tar -C $W -xf -
  fi
  [ -f $W/runTBarForCatenaD4J.py ] || { echo "worker dir $W incomplete - abort" >> $RES/run.log; exit 1; }
  mkdir -p $W/D4J/projects   # excluded from the copy; runner checkouts land here
done
echo "=== GB4 TBar start $(date) queue=$(grep -c . $LIST)" >> $RES/run.log
worker() {
  local i=$1 W=/catena/wk4_$i BUG P d kind
  cd $W || return
  while read BUG; do
    [ -z "$BUG" ] && continue
    [ -e $RES/done/$BUG ] && continue
    mkdir $RES/claim_$BUG 2>/dev/null || continue
    if [ ! -s /catena/FL/$BUG/ochiai.ranking.txt ] || [ ! -s /catena/FL/$BUG/cp.txt ]; then
      echo "--- w$i $BUG SKIP no-FL $(date)" >> $RES/run.log; touch $RES/done/$BUG; continue
    fi
    mkdir -p $W/C4J_location/105SampleBugsResult/$BUG $W/OUTPUT/NormalFL/TBar
    cp -f /catena/FL/$BUG/ochiai.ranking.txt $W/C4J_location/105SampleBugsResult/$BUG/
    export TBAR_EXTRA_CP=$(cat /catena/FL/$BUG/cp.txt)
    echo "--- w$i $BUG start $(date)" >> $RES/run.log
    echo $BUG > $W/one_bug.txt
    t0=$(date +%s)
    setsid timeout -k 60 19000 python3 runTBarForCatenaD4J.py 0 0 $W $W/one_bug.txt /gb >> $RES/w$i.log 2>&1 &
    P=$!
    wait $P
    kill -9 -- -$P 2>/dev/null   # reap the whole per-bug process group (hung test JVMs)
    if [ $(( $(date +%s) - t0 )) -lt 30 ]; then
      echo "--- w$i $BUG CRASH after $(( $(date +%s) - t0 ))s - NOT marked done" >> $RES/run.log
      continue
    fi
    for kind in FixedBugs PartiallyFixedBugs; do
      for d in $W/OUTPUT/NormalFL/TBar/*/$kind/$BUG; do
        [ -d "$d" ] && mkdir -p $RES/fixed/$BUG && cp -r "$d" $RES/fixed/$BUG/$(basename $(dirname $(dirname $d)))_$kind
      done
    done
    rm -rf $W/OUTPUT/NormalFL/TBar/*/FixedBugs/$BUG $W/OUTPUT/NormalFL/TBar/*/PartiallyFixedBugs/$BUG 2>/dev/null
    touch $RES/done/$BUG
    echo "--- w$i $BUG end $(date) fixed=$(ls $RES/fixed/$BUG 2>/dev/null | wc -l)" >> $RES/run.log
  done < $LIST
}
for i in $(seq 1 $N); do worker $i & done
wait
echo "=== GB4 TBar ALL DONE $(date) done=$(ls $RES/done | wc -l)" >> $RES/run.log
touch /catena/gb4.done
curl -s -d "GB4 TBar finished: $(ls $RES/done | wc -l) bugs done" https://ntfy.sh/klee-tbar-9x42qz > /dev/null
