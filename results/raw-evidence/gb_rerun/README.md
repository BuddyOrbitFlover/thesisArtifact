# gb_rerun/ — scaled re-run raw evidence (RQ1, collected 2026-07-14)

Pre-registered 28-project / 55-bug sample (findings repo: METHODOLOGY §4.2, FINDINGS
§3.3; sample artifacts in its `data/gb_rerun/`). Everything here was produced
2026-07-14: pre-registration → bring-up → stages 1–5 in one day.

| File | Contents |
|---|---|
| `rerun_stage5.log.gz` | Full IBugFinder run log (31 bugs, `-n 4`, paper budgets, 85 min) — ends with the verdict table |
| `rerun_verdict_artifacts.tgz` | Per-bug ground truth: 27 `working/<bug>/newBugs.json` + all 31 per-bug runner logs + the 4 `EXCEPTION_*` files of the censored bugs |
| `rerun_host_artifacts.tgz` | Orchestration + inputs: stage 1/2/4/5 scripts, vertical-slice + smoke scripts and logs (incl. the invalidated double-launch log, retained per FINDINGS honesty note), binshim v2/v3, bug lists (`rerun47`, cap-2, multi-hunk), `database.rerun47.json`, `rerun_res5.json`, the 30-min ntfy monitor, Tika `dir-layout.csv` pre-fix backup |
| `rq2/` | **The RQ2 half of the same re-run** (collected 2026-07-24): TBar on the 14 isolated multi-hunk sub-bugs — `RESULTS_GB2/`, run logs, FL rankings, drivers. 1/14 plausible, 0/14 correct (FINDINGS §4.6). See `rq2/README.md` |

Verdict integrity audit (env-noise, per-bug "raising new failing tests" counts) and
the full procedure timeline: findings repo FINDINGS §3.3 + the local
`rerun_procedure_log.md` (to be archived with the thesis).

Related sm06 state (not copied): checkouts in gb-div `/tmp/rerun`; pilot 2toMore
preserved as `2toMore.pilot14.bak`; growingBugs Tika build_files backup
`tika_buildfiles_bak20260714.tgz` in `/localhome/klee`.
