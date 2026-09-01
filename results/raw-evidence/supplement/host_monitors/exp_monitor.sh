#!/bin/bash
NTFY="${NTFY:-https://ntfy.sh/klee-tbar-9x42qz}"
INTERVAL="${INTERVAL:-1800}"
CT=chart-repro
while true; do
  read CPUP MEMU < <(podman stats --no-stream --format '{{.CPUPerc}} {{.MemUsage}}' "$CT" 2>/dev/null | tr -d '%')
  CORES=$(awk "BEGIN{printf \"%.1f\", ${CPUP:-0}/100}")
  M=$(podman exec "$CT" bash -lc '
    cd /root/CatenaD4J/scripts/generate_bugs 2>/dev/null
    P1=$(ls working 2>/dev/null | grep -c _)
    ST=$(pgrep -f "run.py|validate.py|export.py|statstics.py" >/dev/null && echo running || echo idle)
    LJ=$(ps -eo stat,comm | awk "\$2==\"java\" && \$1!~/^Z/" | wc -l)
    Z=$(ps -eo stat | grep -c ^Z)
    PD=$(cat /sys/fs/cgroup/pids.current 2>/dev/null)
    R2D=$(ls /TBarAPI/RESULTS_rem/done 2>/dev/null | wc -l)
    R2F=$(ls /TBarAPI/RESULTS_rem/fixed 2>/dev/null | wc -l)
    echo "$P1|$ST|$LJ|$Z|$PD|$R2D|$R2F"' 2>/dev/null)
  IFS='|' read P1 ST LJ Z PD R2D R2F <<< "$M"
  PRIO=default; STATUS="running"
  [ "$ST" = idle ] && [ "${P1:-0}" -ge 270 ] && { STATUS="PART1 DONE"; PRIO=high; }
  [ "$ST" = idle ] && [ "${P1:-0}" -lt 270 ] && [ "${LJ:-0}" -eq 0 ] && { STATUS="idle-check"; PRIO=high; }
  [ "${R2D:-0}" -ge 61 ] && { STATUS="PART2 DONE"; PRIO=high; }
  awk "BEGIN{exit !(${CORES:-0}>33)}" && { STATUS="CORES OVER CAP"; PRIO=urgent; }
  BODY="Status: $STATUS
Part1 isolate: ${P1:-?}/281 (stage ${ST:-?})
Cores: ${CORES:-?} / 32 cap
Live java: ${LJ:-?}  Zombies: ${Z:-?}  PIDs: ${PD:-?}
Mem: ${MEMU:-?}
Part2: ${R2D:-0}/61 done, ${R2F:-0} fixed
$(date '+%m-%d %H:%M')"
  curl -s -H "Title: sm06 [$STATUS]" -H "Priority: $PRIO" -d "$BODY" "$NTFY" >/dev/null 2>&1
  sleep "$INTERVAL"
done
