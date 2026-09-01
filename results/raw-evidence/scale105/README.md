# scale105 — raw evidence for the scale-to-105 phase (2026-07-26 → 2026-08-13)

Everything the census scale-up, the S1/S2 rescues, the S5 expansion and the final
GB4 campaigns produced. Full chronology and every decision:
`census_procedure_log.md` in the notes repo (imh-bugs-external-validity);
result tables in `FINDINGS.md` Parts 3-5 there.

## Contents

- `census/` — RQ2 census TBar arm (58 sub-bugs) raw pulls:
  `rq2c_results.tgz` (RESULTS_GB3 patches + done markers),
  `rq2c_devfixes.tgz` (developer fixes used for judging),
  `rq2c_registries.tgz` (sub-bug registries), `census_exceptions.tgz`
  (27 stage-5 exception files), `pats0_check.tgz` (pats=0 resolution evidence).
- `hercules/` — all three Hercules arms: `herc_gb_pull.tgz`
  (RESULTS_HERC, 77 gb sub-bugs), `herc_d4j_pull.tgz` (RESULTS_HERC_D4J,
  paper's 105 D4J sub-bugs), `herc_gb4_pull_20260813.tgz` (RESULTS_HERC_GB4,
  the 15 GB4 sub-bugs, md5 19b043d0e6cf17a86d0986d0606c78ce: 15/15 validated,
  0 plausible, 0 attrition), `herc_gb5_pull_20260815.tgz` (RESULTS_HERC_GB5,
  the 5 S6 survivors, md5 09f7b74dc445e681cc0744d0000e4f7c: 5/5 validated,
  0 plausible; 2802 candidate patches, zero passers — closes Hercules gb
  coverage at 97, the same population as the TBar arm).
- `gb4/` — final TBar campaign (15 sub-bugs = 9 FL-rescued + 2 S2 + 4 S5):
  `gb4_results_20260812.tgz` (RESULTS_GB4 done/fixed + run log),
  `gb4_tbarlog_20260812.log.gz` (full worker logs).
- `gb5/` — GB5 TBar campaign (5 S6 survivors): `gb5_results_20260814.tgz`
  (RESULTS_GB5 + the six new sub-bug registries; JacksonDatabind_126_1 and
  _135_2 plausible, both judged overfitting).
- `sm06_pull_20260813/` — 1282-file raw pull from gb-div
  (md5 f1cbce07b81d1846a0c1e2a4c3da27a7): all campaign logs (fl_san, fl_san2,
  fl_s5, isochk, s5_stage5, s5_avro_retry), S5 stage outputs (database.s5.json,
  newBugs.json per bug, statistics), FL rankings for the 15 GB4 bugs, minted
  sub-bug registries, the `.bak20260806`/`.bak20260811` safety copies
  (coordfix originals, parser lstrip fix, env-test exclusion files), binshim
  versions, and the Hercules orchestration.
- `../scripts/scale105/` — the exact scripts that ran: rq2_herc.sh
  (md5 dfafe954… = launch-time value from the 2026-07-30 log entry, byte-identical),
  herc_gb4.sh, rq2_tbar4.sh, fl_san.sh, fl_san2.sh, fl_s5.sh, s5_pipeline.sh,
  gb4_monitor.sh, binshim_defects4j_v4, coordfix.py.

md5 of every file: run `md5 -r` over this tree; launch-time values are recorded
in the procedure log entries.

## Not included

- rq2_herc_d4j.sh + chart-repro orchestration files (live in the other
  container, small follow-up pull).
