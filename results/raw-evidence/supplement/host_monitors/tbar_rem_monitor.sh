#!/bin/bash
NTFY="${NTFY:-https://ntfy.sh/klee-tbar-9x42qz}"
INTERVAL="${INTERVAL:-3600}"   # 1 hour
CT=chart-repro; TOTAL=61
while true; do
  read CPUP MEMU < <(podman stats --no-stream --format '{{.CPUPerc}} {{.MemUsage}}' "$CT" 2>/dev/null | tr -d '%')
  CORES=$(awk "BEGIN{printf \"%.1f\", ${CPUP:-0}/100}")
  M=$(podman exec "$CT" bash -lc '
    D=$(ls /TBarAPI/RESULTS_rem/done 2>/dev/null | wc -l)
    F=$(ls /TBarAPI/RESULTS_rem/fixed 2>/dev/null | wc -l)
    FB=$(ls /TBarAPI/RESULTS_rem/fixed 2>/dev/null | tr "\n" " ")
    W=$(pgrep -fc "[r]un_worker_rem")
    LJ=$(ps -eo stat,comm | awk "\$2==\"java\" && \$1!~/^Z/" | wc -l)
    Z=$(ps -eo stat | grep -c ^Z)
    PD=$(cat /sys/fs/cgroup/pids.current 2>/dev/null)
    echo "$D|$F|$W|$LJ|$Z|$PD|$FB"' 2>/dev/null)
  IFS='|' read D F W LJ Z PD FB <<< "$M"
  PRIO=default; STATUS="running"
  [ "${W:-0}" -eq 0 ] && [ "${D:-0}" -lt "$TOTAL" ] && { STATUS="WORKERS DIED"; PRIO=urgent; }
  [ "${D:-0}" -ge "$TOTAL" ] && { STATUS="PART2 DONE"; PRIO=high; }
  awk "BEGIN{exit !(${CORES:-0}>33)}" && { STATUS="CORES OVER CAP"; PRIO=urgent; }
  BODY="Closure+Lang TBar (5h/bug)
Status: $STATUS
Done: ${D:-?}/$TOTAL   Fixed: ${F:-0}
Fixed bugs: ${FB:-none}
Workers: ${W:-?}/4   Live-java: ${LJ:-?}
Cores: ${CORES:-?} / 32 cap
Zombies: ${Z:-?}   PIDs: ${PD:-?}   Mem: ${MEMU:-?}
$(date '+%m-%d %H:%M')"
  curl -s -H "Title: sm06 Closure+Lang [$STATUS]" -H "Priority: $PRIO" -d "$BODY" "$NTFY" >/dev/null 2>&1
  sleep "$INTERVAL"
done
