#!/bin/bash
# s5_pipeline.sh — S5 expansion (52 bugs: 34 arm-A tiny + 18 arm-B D4J-shared
# gb-only). Registration: thesis-findings/data/gb_rerun/s5/gb_s5_registration.md
# Paper-verbatim params throughout (1h/2048/900s stage 5).
#
# HOST (sm06):        bash /localhome/klee/catena_gb/s5_pipeline.sh clone
# CONTAINER (gb-div): podman exec gb-div bash -lc \
#                       'bash /catena/s5_pipeline.sh <lists|smoke|stage1|stage2|mhfilter|stage4|stage5|status>'
# Run stages in that order; each writes progress to /catena/s5_pipeline.log
# (clone logs to stdout on the host). Stage 5 detaches and pings ntfy.
set -u
STAGE=${1:?usage: clone|lists|smoke|stage1|stage2|mhfilter|stage4|stage5|status}
LOG=/catena/s5_pipeline.log
NTFY=https://ntfy.sh/klee-tbar-9x42qz

BUGS52="Aws_maven_1 Confluence_http_authenticator_1 Fluo_api_1 Fluo_api_3 Github_release_plugin_1 Github_release_plugin_2 JacksonDataformatBinary_avro_1 JacksonDataformatBinary_avro_2 JacksonDataformatsText_properties_1 JacksonDataformatsText_properties_2 Jackson_datatype_hibernate4_1 Jnagmp_1 Kafka_graphite_1 Metrics_opentsdb_1 Metrics_opentsdb_2 Rdf4j_query_1 Rdf4j_rio_api_1 Rdf4j_rio_api_2 Rdf4j_rio_jsonld_1 Rdf4j_rio_jsonld_2 Rdf4j_rio_rdfjson_1 Rdf4j_rio_rdfjson_2 Rdf4j_rio_rdfxml_1 Rocketmq_mqtt_cs_1 Rocketmq_mqtt_ds_1 Slack_java_webhook_1 Snomed_owl_toolkit_1 Snomed_owl_toolkit_2 Stash_jenkins_postreceive_webhook_1 Subethasmtp_1 Suffixtree_1 Template_benchmark_1 Tempus_fugit_1 Weak_lock_free_1 Cli_41 Cli_42 Codec_19 Collections_29 Collections_30 Compress_48 Compress_50 Csv_17 Gson_1 Gson_2 JacksonCore_28 JacksonCore_29 JacksonDatabind_112 JacksonDatabind_121 Lang_69 Lang_71 Math_1 Math_2"

case $STAGE in

clone)  # HOST. Bare-clone the 10 arm-B repos into the GLOBAL repo dir
  GBH=/localhome/klee/growingbugs/project_repos
  for pair in \
    commons-cli:https://github.com/apache/commons-cli.git \
    commons-codec:https://github.com/apache/commons-codec.git \
    commons-collections:https://github.com/apache/commons-collections.git \
    commons-compress:https://github.com/apache/commons-compress.git \
    commons-csv:https://github.com/apache/commons-csv.git \
    gson:https://github.com/google/gson.git \
    jackson-core:https://github.com/FasterXML/jackson-core.git \
    jackson-databind:https://github.com/FasterXML/jackson-databind.git \
    commons-lang:https://github.com/apache/commons-lang.git \
    commons-math:https://github.com/apache/commons-math.git ; do
    n=${pair%%:*}; u=${pair#*:}
    if [ -d $GBH/$n.git ]; then echo "SKIP $n.git (exists)"; else
      git clone --bare "$u" $GBH/$n.git && echo "CLONED $n.git" || echo "FAIL $n.git"
    fi
  done ;;

lists)
  tr ' ' '\n' <<< "$BUGS52" | grep . > /catena/s5_bugs.txt
  sed 's/_[0-9]*$//' /catena/s5_bugs.txt | sort -u > /catena/s5_projects.txt
  echo "s5 lists: $(wc -l < /catena/s5_bugs.txt) bugs, $(wc -l < /catena/s5_projects.txt) projects" | tee -a $LOG ;;

smoke)  # checkout every bug once (B-phase smoke pattern), report OK/FAIL count
  export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
  mkdir -p /tmp/s5smoke   # checkout fails if the workdir PARENT is missing
  ok=0; fail=0
  while read BUG; do
    P=${BUG%_*}; I=${BUG##*_}; W=/tmp/s5smoke/$BUG
    rm -rf $W
    if defects4j checkout -p $P -v ${I}b -w $W < /dev/null > /tmp/s5smoke_last.log 2>&1; then
      ok=$((ok+1)); else fail=$((fail+1)); echo "SMOKE-FAIL $BUG: $(tail -1 /tmp/s5smoke_last.log | cut -c1-160)" >> $LOG
    fi
    rm -rf $W
  done < /catena/s5_bugs.txt
  echo "smoke: OK=$ok FAIL=$fail (details in $LOG)" | tee -a $LOG ;;

stage1)
  export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH
  cd /catena/scripts/construct_database
  echo "=== s5 stage1 $(date)" >> $LOG
  touch .s5_start   # stale exception_* from earlier arms must not false-flag
  rm -f exception_* export_failures.txt   # clean census per attempt
  mkdir -p /tmp/s5co   # checkout dies if the workroot parent is missing
  python3 check_out_projects.py /catena/s5_bugs.txt /tmp/s5co >> $LOG 2>&1
  find . -maxdepth 1 -name "exception_*" -newer .s5_start | sed 's/^/stage1 exception: /' >> $LOG
  python3 export_metadata2.py /catena/s5_bugs.txt /tmp/s5co >> $LOG 2>&1
  [ -s export_failures.txt ] && sed 's/^/export failure: /' export_failures.txt >> $LOG
  # convert hardcodes d4j_export/database.json -> move-aside dance
  [ -f d4j_export/database.json ] && mv d4j_export/database.json d4j_export/database.main.keep
  python3 convert_metadata.py /catena/s5_bugs.txt /tmp/s5co d4j >> $LOG 2>&1
  mv d4j_export/database.json d4j_export/database.s5.json
  [ -f d4j_export/database.main.keep ] && mv d4j_export/database.main.keep d4j_export/database.json
  python3 -c "import json;d=json.load(open('d4j_export/database.s5.json'));print('database.s5.json bugs:',len(d))" | tee -a $LOG ;;

stage2)
  cd /catena/scripts/parse_patches
  echo "=== s5 stage2 $(date)" >> $LOG
  while read P; do
    python3 parse_defects4j_v2_0.py /gb $P >> $LOG 2>&1 && echo "parsed $P" || echo "PARSE-FAIL $P" | tee -a $LOG
  done < /catena/s5_projects.txt ;;

mhfilter)
  python3 - <<'PY' | tee -a $LOG
import json, os
mh, sh, miss = [], [], []
for bug in open('/catena/s5_bugs.txt').read().split():
    p, i = bug.rsplit('_', 1)
    f = f'/catena/scripts/parse_patches/patches/{p}/{i}.json'
    if not os.path.isfile(f): miss.append(bug); continue
    nh = json.load(open(f)).get('num_of_hunks', 0)
    (mh if nh >= 2 else sh).append((bug, nh))
open('/catena/s5_mh.txt','w').write('\n'.join(b for b,_ in mh)+'\n')
print(f's5 mhfilter: {len(mh)} multi-hunk -> /catena/s5_mh.txt, {len(sh)} single-hunk excluded, {len(miss)} MISSING-JSON')
for b,n in mh: print(f'  MH {b} nh={n}')
if miss: print('  MISSING:', ' '.join(miss))
PY
  ;;

stage4)
  cd /catena/scripts/split_tests
  echo "=== s5 stage4 $(date)" >> $LOG
  mkdir -p /tmp/s5split
  [ -d running ] && [ ! -d running_pre_s5_bak ] && cp -a running running_pre_s5_bak
  python3 run.py ./tableGB -d /gb -f /catena/s5_mh.txt -w /tmp/s5split \
    -m ../construct_database/d4j_export/database.s5.json >> $LOG 2>&1
  # ISOLATED stage-5 dir: shared working/ holds shipped D4J dirs incl.
  # Math_1/Math_2, which gb Math_1/2 would collide with (D4J-renumbering)
  G5=/catena/scripts/generate_bugs_s5
  mkdir -p $G5/working/data $G5/exceptions
  find /catena/scripts/generate_bugs -maxdepth 1 -type f -exec cp -n {} $G5/ \;
  # runner.py imports these local PACKAGE dirs — link them (read-only code)
  ln -sfn ../generate_bugs/ProjectManager $G5/ProjectManager
  ln -sfn ../generate_bugs/timeout_decorator $G5/timeout_decorator
  cp running/res5.json $G5/s5_res5.json
  python3 -c "import json;d=json.load(open('$G5/s5_res5.json'));print('s5_res5.json bugs:',len(d))" | tee -a $LOG ;;

stage5)
  cd /catena/scripts/generate_bugs_s5 || { echo "run stage4 first (creates the isolated dir)"; exit 1; }
  if pgrep -f "[p]ython3 run.py" > /dev/null; then echo "ABORT: another IBugFinder run.py is live (serial point)"; exit 1; fi
  export PATH=/root/binshim:/gb/framework/bin:/catena:$PATH   # detached child inherits
  rm -f /catena/s5_stage5.done
  rm -f exceptions/EXCEPTION_* 2>/dev/null
  cp /catena/s5_mh.txt 2toMore
  echo "=== s5 stage5 launch $(date) targets=$(wc -l < 2toMore)" >> $LOG
  setsid bash -c '
    cd /catena/scripts/generate_bugs_s5
    ( while [ ! -f /catena/s5_stage5.done ]; do          # mini-reaper: hung test
        sleep 600                                        # JVMs (Tape_6 lesson);
        for pid in $(ps -eo pid=,etimes=,comm= | awk "\$3==\"java\" && \$2>2700 {print \$1}"); do
          grep -aqi -e gzoltar -e tbar /proc/$pid/cmdline 2>/dev/null && continue  # never kill FL or a live TBar search
          kill -9 $pid 2>/dev/null && echo "reaped hung java $pid $(date)" >> /catena/s5_pipeline.log
        done
      done ) &
    python3 run.py -m ../construct_database/d4j_export/database.s5.json \
      -t ./s5_res5.json -p ../parse_patches/patches -n 4 > s5_stage5.log 2>&1
    python3 verdict.py >> s5_stage5.log 2>&1
    touch /catena/s5_stage5.done
    curl -s -d "S5 stage5 DONE" https://ntfy.sh/klee-tbar-9x42qz > /dev/null
  ' > /dev/null 2>&1 < /dev/null &
  echo "stage5 detached; log s5_stage5.log, marker /catena/s5_stage5.done" ;;

status)
  tail -5 $LOG 2>/dev/null
  echo "---"
  tail -3 /catena/scripts/generate_bugs_s5/s5_stage5.log 2>/dev/null
  echo "analyzed: $(ls /catena/scripts/generate_bugs_s5/working/*/newBugs.json 2>/dev/null | wc -l)/$(wc -l < /catena/s5_mh.txt 2>/dev/null)  done-marker: $(ls /catena/s5_stage5.done 2>/dev/null || echo absent)" ;;

esac
