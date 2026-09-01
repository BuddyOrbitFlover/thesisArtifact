#!/bin/bash
WH="$1"; CHUNK="$2"; D4J=/root/defects4j; RES=/TBarAPI/RESULTS
mkdir -p "$RES/done" "$RES/fixed" "$RES/logs"
while read -r bug; do
  [ -z "$bug" ] && continue
  [ -e "$RES/done/$bug" ] && { echo "$(date +%T) SKIP $bug"; continue; }
  echo "$(date +%T) START $bug"
  printf '%s\n' "$bug" > "$WH/onebug.txt"
  timeout -k 30 4200 bash -c "cd '$WH' && python3 runTBarForCatenaD4J.py 0 0 '$WH' onebug.txt '$D4J'" >> "$RES/logs/$bug.log" 2>&1
  for fb in $(find "$WH/OUTPUT" -type d -path "*FixedBugs/$bug" 2>/dev/null); do
    mkdir -p "$RES/fixed/$bug"; cp -r "$fb"/. "$RES/fixed/$bug/" 2>/dev/null
  done
  touch "$RES/done/$bug"
  echo "$(date +%T) DONE $bug"
done < "$CHUNK"
echo "$(date +%T) WORKER FINISHED"
