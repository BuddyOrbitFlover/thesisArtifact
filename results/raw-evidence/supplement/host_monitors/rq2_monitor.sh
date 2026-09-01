#!/bin/bash
exec 9>/tmp/rq2mon.lock
flock -n 9 || { echo "monitor already running"; exit 1; }
NTFY=https://ntfy.sh/klee-tbar-9x42qz
while true; do
  D61=$(podman exec chart-repro bash -lc 'ls /TBarAPI/RESULTS_rem/done 2>/dev/null | wc -l' 2>/dev/null || echo "?")
  F61=$(podman exec chart-repro bash -lc 'ls /TBarAPI/RESULTS_rem/fixed 2>/dev/null | wc -l' 2>/dev/null || echo "?")
  W=$(podman exec chart-repro bash -lc 'pgrep -xc python3' 2>/dev/null || echo "?")
  D5=$(podman exec gb-div bash -lc 'ls /catena/tbar/RESULTS_GB/done 2>/dev/null | wc -l' 2>/dev/null || echo "?")
  F5=$(podman exec gb-div bash -lc 'ls /catena/tbar/RESULTS_GB/fixed 2>/dev/null | wc -l' 2>/dev/null || echo "?")
  CUR=$(podman exec gb-div bash -lc 'grep "^--- " /catena/tbar/rq2_tbar.log 2>/dev/null | tail -1' 2>/dev/null)
  CPU=$(podman stats --no-stream --format "{{.Name}}:{{.CPUPerc}}" 2>/dev/null | tr "\n" " ")
  curl -s -d "ClosureLang: $D61/61 done, $F61 fixed, $W/4 workers | RQ2gb: $D5/5 done, $F5 with patches | last: $CUR | cpu: $CPU" $NTFY >/dev/null
  if [ "$D61" = "61" ] && [ "$D5" = "5" ]; then
    curl -s -d "ALL TBAR RUNS COMPLETE (61/61 + 5/5) - monitor exiting" $NTFY >/dev/null
    exit 0
  fi
  sleep 1800
done
