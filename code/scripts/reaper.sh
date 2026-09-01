#!/bin/bash
while true; do
  ps -eo pid,etimes,args | awk '$2>2700 && /[a]nt-launcher|[J]UnitCore|run\.dev\.tests/ {print $1}' | xargs -r kill -9 2>/dev/null
  sleep 120
done
