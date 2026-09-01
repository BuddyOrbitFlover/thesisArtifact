#!/bin/bash
EMAIL="lee.kangreg@gmail.com"
CTR="chart-repro"
TOTAL=44
INTERVAL=1800          # 30 minutes
NTFY="https://ntfy.sh/klee-tbar-9x42qz"

notify() {
  if [ -n "$NTFY" ]; then curl -s -H "Title: $1" -d "$2" "$NTFY" >/dev/null
  else printf '%s\n' "$2" | mail -s "$1" "$EMAIL"; fi
}

while true; do
  ts=$(date '+%F %H:%M')
  if ! podman exec "$CTR" true 2>/dev/null; then
    notify "TBar monitor: container unreachable" "[$ts] cannot reach $CTR"; sleep "$INTERVAL"; continue
  fi
  d=$(podman exec "$CTR" bash -lc 'ls /TBarAPI/RESULTS_5h/done 2>/dev/null | wc -l'); d=${d:-0}
  r=$(podman exec "$CTR" bash -lc 'pgrep -xc python3'); r=${r:-0}
  c=$(podman exec "$CTR" bash -lc 'ps -eo pcpu,comm' | awk '/[j]ava/{s+=$1} END{printf "%d", s/100}'); c=${c:-0}
  z=$(podman exec "$CTR" bash -lc 'ps -eo stat' | grep -c '^Z')
  f=$(podman exec "$CTR" bash -lc 'find /root/wk_*/OUTPUT -type d -path "*FixedBugs/*" 2>/dev/null' \
        | sed -E 's#.*FixedBugs/##' | sort -u | tr '\n' ' ')
  st="OK"
  [ "$c" -gt 32 ] && st="ALERT cores=$c>32"
  [ "$z" -gt 10 ] && st="$st zombies=$z"
  [ "$r" -eq 0 ] && { [ "$d" -ge "$TOTAL" ] && st="DONE" || st="ENDED $d/$TOTAL"; }
  body="TBar run @ $ts
status : $st
done   : $d / $TOTAL
workers: $r / 4
cores  : ~$c  (budget 32)
zombies: $z
fixed  : ${f:-none yet}"
  notify "TBar ${st} ($d/$TOTAL, ${c}c)" "$body"
  [ "$r" -eq 0 ] && { notify "TBar monitor stopping" "$body"; break; }
  sleep "$INTERVAL"
done
