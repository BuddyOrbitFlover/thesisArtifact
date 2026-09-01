#!/bin/bash
# herc_gb4.sh — Hercules (give-to/Hercules @ eedd7e1ad, UNMODIFIED code) on the 15
# GB4 sub-bugs (9 FL-rescued + 2 S2 + 4 S5). Protocol byte-identical to rq2_herc.sh
# (the 77-bug run) except: fixed list /catena/gb4_bugs.txt (guard 15), results dir
# RESULTS_HERC_GB4, worker dirs hgb4_*, own lock + ping prefix. Modes:
# launcher (default) | worker N | watchdog.
# One bug per Main_NFL/validator invocation, so hercules_valid_v2.py's sys.exit()
# only ever affects the current bug. 5h/bug budget = the harness's own 18000s logic.
NTFY=https://ntfy.sh/klee-tbar-9x42qz
R=/catena/RESULTS_HERC_GB4
export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8 -XX:ActiveProcessorCount=5"

ping() { curl -s -m 10 -d "$1" $NTFY >/dev/null 2>&1; }

if [ "$1" = "worker" ]; then
  i=$2; W=/catena/hgb4_$i
  cd "$W" || exit 1
  n=$(wc -l < chunk.txt); k=0
  while read -r BUG; do
    [ -z "$BUG" ] && continue
    k=$((k+1))
    [ -f "$R/done/$BUG" ] && continue
    CID=${BUG##*_}; rest=${BUG%_*}; BID=${rest##*_}; PROJ=${rest%_*}
    echo "=== $BUG ($k/$n) $(date) PROJ=$PROJ BID=$BID CID=$CID ==="
    rm -rf "$W/projects" "$W/patches" "$W/results" "$W/tmp" "$W/time_info.txt" "$W/gen.log"
    mkdir -p "$W/projects"
    if ! timeout 1800 catena4j checkout -p "$PROJ" -v "${BID}b${CID}" -w "$W/projects/$BUG"; then
      echo "ATTRITION:checkout" > "$R/done/$BUG"; ping "HERCGB4 w$i: $BUG ATTRITION checkout"; continue
    fi
    if ! ( cd "$W/projects/$BUG" && timeout 1800 defects4j compile ); then
      echo "ATTRITION:compile" > "$R/done/$BUG"; ping "HERCGB4 w$i: $BUG ATTRITION compile"; continue
    fi
    echo "$BUG" > one.txt
    timeout -k 30 18000 java -cp Hercules-1.0-SNAPSHOT-jar-with-dependencies.jar \
      org.example.hercules.Main_NFL "$W/projects" /catena /catena/FL one.txt gen.log
    grc=$?
    cp gen.log "$R/genlogs/$BUG.gen.log" 2>/dev/null
    if [ ! -d "patches/$BUG" ]; then
      echo "done:no_patches:genrc=$grc" > "$R/done/$BUG"
      ping "HERCGB4 w$i: $BUG done (0 patches, genrc=$grc)"; continue
    fi
    python3 hercules_valid_v2.py "$W/projects"
    vrc=$?
    cp "results/$BUG.txt" "$R/results/$BUG.txt" 2>/dev/null
    cp time_info.txt "$R/time/$BUG.txt" 2>/dev/null
    tar -czf "$R/patches/$BUG.tgz" "patches/$BUG" 2>/dev/null
    p=$(grep -c ":Pass" "results/$BUG.txt" 2>/dev/null); p=${p:-0}
    tot=$(wc -l < "results/$BUG.txt" 2>/dev/null); tot=${tot:-0}
    echo "done:genrc=$grc:vrc=$vrc:pats=$tot:pass=$p" > "$R/done/$BUG"
    d=$(ls "$R/done" | wc -l)
    ping "HERCGB4 w$i: $BUG done pass=$p/$tot (total $d/15)"
  done < chunk.txt
  ping "HERCGB4 worker $i FINISHED ($(ls "$R/done" | wc -l)/15 done overall)"
  exit 0
fi

if [ "$1" = "watchdog" ]; then
  while true; do
    sleep 1800
    d=$(ls "$R/done" 2>/dev/null | wc -l)
    a=$(pgrep -f "[h]erc_gb4.sh worker" | wc -l)
    pl=$(grep -l "pass=[1-9]" "$R"/done/* 2>/dev/null | wc -l)
    ping "HERCGB4 status: $d/15 done, bugs-with-plausible=$pl, workers=$a, load=$(cut -d' ' -f1 /proc/loadavg)"
    for pid in $(pgrep -f "[h]gb4_.*Main_NFL"); do
      et=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' '); st=$(ps -o stat= -p "$pid" 2>/dev/null)
      [ -n "$et" ] && [ "$et" -gt 21600 ] && [ "${st#Z}" = "$st" ] && kill -9 "$pid" && ping "HERCGB4 reaper: killed gen pid $pid (>6h)"
    done
    [ "$a" -eq 0 ] && { ping "HERCGB4 ALL WORKERS EXITED: $d/15 done"; exit 0; }
  done
fi

# ---- launcher ----
exec 9>/catena/herc_gb4.lock
flock -n 9 || { echo "already running (herc_gb4.lock held)"; exit 1; }
mkdir -p "$R/done" "$R/results" "$R/patches" "$R/time" "$R/genlogs" "$R/logs"
N=$(grep -c . /catena/gb4_bugs.txt)
echo "bug list: $N bugs"
[ "$N" -eq 15 ] || { echo "ABORT: expected exactly 15 bugs in gb4_bugs.txt, got $N"; exit 1; }
for b in $(cat /catena/gb4_bugs.txt); do
  [ -s "/catena/FL/$b/ochiai.ranking.txt" ] || { echo "ABORT: no FL ranking for $b"; exit 1; }
done
sort /catena/gb4_bugs.txt > /catena/hercgb4_buglist.txt
for i in 0 1 2 3; do
  W=/catena/hgb4_$i
  rm -rf "$W"; mkdir -p "$W/projects"
  tar -C /catena/hercules -cf - --exclude=patches --exclude=results --exclude=tmp \
    --exclude=C4J_results --exclude=location . | tar -C "$W" -xf -
  [ -f "$W/Hercules-1.0-SNAPSHOT-jar-with-dependencies.jar" ] || { echo "ABORT: worker $i copy incomplete (jar)"; exit 1; }
  [ -f "$W/hercules_valid_v2.py" ] || { echo "ABORT: worker $i copy incomplete (validator)"; exit 1; }
  [ -f "$W/_Applier.py" ] || { echo "ABORT: worker $i copy incomplete (_Applier)"; exit 1; }
  awk -v i=$i -v n=4 -v N=$N 'BEGIN{c=int((N+n-1)/n)} NR>i*c && NR<=(i+1)*c' /catena/hercgb4_buglist.txt > "$W/chunk.txt"
  echo "worker $i: $(wc -l < "$W/chunk.txt") bugs ($(head -1 "$W/chunk.txt") .. $(tail -1 "$W/chunk.txt"))"
done
for i in 0 1 2 3; do
  setsid bash /catena/herc_gb4.sh worker $i > "$R/logs/worker_$i.log" 2>&1 < /dev/null &
done
setsid bash /catena/herc_gb4.sh watchdog > "$R/logs/watchdog.log" 2>&1 < /dev/null &
ping "HERCGB4 launched: $N bugs, 4 workers + watchdog"
echo "launched 4 workers + watchdog; results -> $R"
