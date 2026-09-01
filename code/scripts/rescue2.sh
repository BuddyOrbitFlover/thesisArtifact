#!/bin/bash
exec 9>/tmp/rescue2.lock
flock -n 9 || { echo "rescue2 already running — abort"; exit 1; }
export PATH=/root/binshim:/gb/framework/bin:$PATH
cd /catena/scripts/generate_bugs
{
  echo "=== RESCUE2 START $(date) ==="
  for b in Text_5 Graph_4; do
    echo "--- clean isolated re-run: $b ---"
    rm -rf working/$b working/data/$b exceptions/EXCEPTION_$b
    python3 run.py -b $b -n 1 -m ../construct_database/d4j_export/database.json -t ./gb_res5.json -p ../parse_patches/patches
    pkill -9 -f "[j]ava" 2>/dev/null
    sleep 2
  done
  echo "=== RESCUE2 DONE $(date) ==="
  python3 verdict.py
  curl -s -d "growingBugs rescue2 (Text_5+Graph_4) FINISHED" https://ntfy.sh/klee-tbar-9x42qz >/dev/null
} > rescue2.log 2>&1
