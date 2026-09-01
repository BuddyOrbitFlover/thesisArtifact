#!/bin/bash
# gb4_monitor.sh — 30-min ntfy pings for the GB4 TBar campaign (+ isochk).
# Auto-stops with a final ping when /catena/gb4.done appears.
exec 8>/tmp/gb4mon.lock
flock -n 8 || exit 1
NTFY=https://ntfy.sh/klee-tbar-9x42qz
while true; do
  total=$(grep -c . /catena/gb4_bugs.txt 2>/dev/null)
  done=$(ls /catena/tbar/RESULTS_GB4/done 2>/dev/null | wc -l)
  fixed=$(ls /catena/tbar/RESULTS_GB4/fixed 2>/dev/null | wc -l)
  cores=$(ps -eo pcpu,comm | awk '$2=="java"||$2=="python3"{s+=$1} END{printf "%.1f", s/100}')
  run=""
  for c in /catena/tbar/RESULTS_GB4/claim_*; do
    [ -d "$c" ] || continue
    b=${c##*claim_}
    [ -e /catena/tbar/RESULTS_GB4/done/$b ] || run="$run$b "
  done
  iso=$(grep -c "failing=\|FAIL" /catena/isochk.log 2>/dev/null || echo 0)
  warn=""
  [ "$(printf "%.0f" $cores)" -gt 30 ] 2>/dev/null && warn="CORES HIGH! "
  if [ -f /catena/gb4.done ]; then
    curl -s -d "GB4 TBar FINISHED: $done/$total done, $fixed with fix dirs. Monitor stopping." $NTFY > /dev/null
    break
  fi
  curl -s -d "${warn}GB4 $done/$total done, $fixed fixed | running: ${run:-none}| cores $cores | isochk $iso/9" $NTFY > /dev/null
  sleep 1800
done
