# S6 stage-5 pull (2026-08-28)

Source: `/localhome/klee/catena_gb/scripts/generate_bugs_s6` on sm06, packed as
`s6_stage5_pull_20260828.tgz` (md5 9075ac5eb0f127c7b89f6f9d7f3e5bb2, verified on the Mac).
Contents: `2toMore` (63 bugs), `verdict.py`, `s6_res5.json` and the other `*_res5.json`,
`s6_verdict_host_20260828.txt` (verdict.py run on the host), `exceptions/` (30 markers),
`working/<bug>/newBugs.json` (36) and per-bug logs under 2 MB.

Recount (verdict.py rule: divisible iff a proper sub-pattern exists in newBugs.json;
unknown iff no newBugs.json and an exception marker):

| | divisible | indivisible | unknown |
|---|---|---|---|
| raw newBugs.json + markers, recounted on the Mac | 21 | 15 | 27 |
| verdict.py on the host | 21 | 15 | 27 |
| `thesis-findings/data/gb_rerun/s6/s6_stage5_verdicts.csv` | 21 | 15 | 27 |

Row-for-row agreement across all 63 bugs. 30 markers vs 27 unknown: Gson_13, Gson_24 and
JacksonDatabind_124 carry a marker and a newBugs.json (one proper pattern each); verdict.py
counts them as divisible with note `+exc`, as does the CSV.
