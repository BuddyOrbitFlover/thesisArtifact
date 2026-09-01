# Raw experiment evidence — External Validity of Indivisible Multi-Hunk Bug Techniques

Raw artifacts backing the findings repository
[`imh-bugs-external-validity`](https://github.com/BuddyOrbitFlover/imh-bugs-external-validity)
(bachelor thesis; external-validity study of Xin et al., *"Detecting, Creating,
Repairing, and Understanding Indivisible Multi-Hunk Bugs"*, FSE 2024).

Collected in three passes from the compute host `sm06`: **2026-07-06** (baseline +
pilot, all experiments of that stage complete), **2026-07-14** (RQ1 re-run), and
**2026-07-24** (RQ2 re-run + the TBar sources it needed). All experiments are now
complete. This repo is **evidence, not documentation** — for methodology, result
tables and interpretation see the findings repo (METHODOLOGY.md / FINDINGS.md).

The 2026-07-24 pass was a full `sm06:~` transfer; the trees collected on 07-06 came
back **byte-identical** (1 603 files re-verified by md5), so the collection channel is
verified lossless.

## Layout

### `d4j/` — Defects4J baseline (RQ0, FINDINGS Part 2)
| Path | What it is |
|---|---|
| `RESULTS_44_1h/` | TBar on the first 44 repair bugs at the 1 h pilot budget — `done/` markers + `fixed/<bug>/` plausible-patch dirs (FINDINGS §2.1–2.3) |
| `RESULTS_5h/` | the 5 h re-run of the 40 bugs unrepaired at 1 h (timeout-sensitivity arm) |
| `RESULTS_rem/` | the Closure+Lang completion run (61 bugs @ 5 h) — 61 `done/` markers, 11 `fixed/<bug>/` patch sets (FINDINGS §2.7) |
| `part1_statstics/` | per-project divisibility CSVs. **Note:** five of six are post-wipe empty shells — the artifact's `clean.sh` deleted the real all-6 CSVs (lesson recorded in the lab notebook); only `statstics2_Time.csv` holds live data (matching the all-6 Time row). The authoritative Part-1 table is FINDINGS Part 1, captured before the wipe. |
| `my_bugs_list.txt` / `remaining_bugs_list.txt` | the 44- and 61-bug target lists |
| `patch_review.txt` | manual patch review notes from the 44-bug correctness pass |

### `gb/` — growingBugs generalization (RQ1 + RQ2, FINDINGS Parts 3–4)
| Path | What it is |
|---|---|
| `stage5/` | RQ1 divisibility evidence: per-bug `newBugs.json` + run logs (`newBugs/`), exception files with tracebacks (`exceptions/`), stage-5/rescue run logs (`stage5.log`, `rescue.log` — first rescue, invalidated by double launch — and `rescue2.log`, the clean re-runs), hunk-parsed patches (`hunk_patches/`), split tests (`gb_res5.json`), stage-1 metadata (`gb_database.json`), bug list (`2toMore`) |
| `catena_registry_export/` | the 13 exported sub-bugs (per-project `bugs-registry.csv` + per-cid src/test patches and trigger tests) — the RQ2 checkout registry |
| `FL/` | final GZoltar/Ochiai rankings per repair sub-bug (`ochiai.ranking.txt` + `info.txt`), the files TBar consumed |
| `FL_raw/` | raw GZoltar outputs (spectra with Ochiai scores, coverage matrix, statistics) per sub-bug |
| `RESULTS_GB/` | RQ2 TBar outcomes: 5 `done/` markers; `fixed/Jfreesvg_1_1/` = the 11 plausible patch variants incl. the token-identical developer fix (`NullPointerChecker_FixedBugs/Patch_194_76.txt`; judgment: FINDINGS §4.3) |
| `rq2_tbar.log` | the RQ2 run log (per-bug start/end timestamps → termination classification) |

### `logs/`
Full TBar stdout logs (gzipped) captured from inside both containers:
`TBar_d4j_closure_lang.log.gz` (61-bug completion run) and `TBar_gb.log.gz`
(all RQ2 attempts, including the two `StackOverflowError` crashes of
Jfreesvg_1_1's first attempts — FINDINGS §4.5).

### `gb_rerun/` — pre-registered scaled re-run (RQ1 + RQ2, FINDINGS §3.3 + §4.6)
| Path | What it is |
|---|---|
| *(top level)* | RQ1 half — stage-5 log, per-bug verdict artifacts, orchestration. See `gb_rerun/README.md` |
| `rq2/` | RQ2 half (collected 2026-07-24): `RESULTS_GB2/` outcomes for the 14 isolated multi-hunk sub-bugs, TBar + FL run logs, the 14 FL rankings, and the FL/TBar drivers. **1/14 plausible (Woodstox_6_1, overfitting), 0/14 correct.** See `gb_rerun/rq2/README.md` |

### `scripts/`
The run harnesses written for this study (`rq2_fl.sh` — FL generation;
`rq2_tbar.sh` — resumable serial TBar driver; `gz2ranking.py` — GZoltar→TBar
ranking converter) and two TBar source snapshots:

- `tbar_patched_sources/` — the **pilot** build (2026-07-06): four patched files
  (`PathUtils.java`: unknown-project layouts + `TBAR_EXTRA_CP` classpaths;
  `ContextReader.java` + `Dictionary.java`: recursion/cycle guards;
  `NormalFLTBarRunner.sh`: classpath-first override). Adaptation rationale:
  METHODOLOGY §8.6.3; the crashes they fix: FINDINGS §4.5.
- `tbar_patched_sources_rerun_20260715/` — the **re-run** build (2026-07-15): three
  multi-underscore parse fixes (`runTBarForCatenaD4J.py`, `Main.java`,
  `PathUtils.java`) plus their pre-patch originals and the diffs. Required by the 8
  re-run sub-bugs whose project name contains `_`; without them TBar exits in
  0.15–6.5 s, in one case leaving a **false done-marker**. FINDINGS §4.6.4.

**Reproducing `gb_rerun/rq2/` needs the second snapshot** — the pilot one predates
these fixes and is kept unchanged as the pilot's own record.

### `supplement/` — second collection pass (completeness audit, 2026-07-06)
| Path | What it is |
|---|---|
| `catena_gb_mods/` | **Every modification to the CatenaD4J artifact clone**: `catena_gb_modifications.diff.gz` (full git diff — mostly regenerated stage-4 data replacing shipped Defects4J files), `code_modifications.diff` (script-only: the `rsplit` underscore fixes + `n_jobs` tuning), untracked-file inventory, and the custom tools `export_metadata2.py` (robust stage-1 exporter), `verdict.py`, `rescue2.sh`, `tableGB` (adopted assertion tables). `export_failures.txt` is empty = the final resumable stage-1 run completed failure-free. |
| `tbarapi_harness/` | The scripts that produced every `d4j/` result: `run_worker.sh` / `run_worker_5h.sh` / `run_worker_rem.sh`, `reaper.sh` (hung-JVM watchdog), `retry40.txt`, plus the TBarAPI clone's diff + untracked inventory. |
| `host_monitors/` | The ntfy monitoring scripts (`exp_monitor.sh`, `tbar_monitor.sh`, `rq2_monitor.sh`). |
| `container_extras/binshim/` | The transparent `defects4j` PATH wrapper (Jimfs checkout self-heal; METHODOLOGY §8.5). |
| `closure_lang_partials/` | **Raw per-worker OUTPUT trees** from the Closure+Lang completion run — the per-mutator `FixedBugs` patch originals (of which `d4j/RESULTS_rem/fixed` is the collected copy). No `PartiallyFixedBugs` were produced in this run. |
| `rq2_tbar_inputs/` | Exactly what TBar consumed per RQ2 sub-bug: converted `Ochiai.txt` rankings + `FailedTestCases` files. |
| `part1_remnants/` | The only Part-1 raw survivors of the `clean.sh` wipe: the Time-only re-run's per-bug `newBugs.json` + logs, plus a listing of the working dir. |

### Known unrecoverable (recorded for honesty)
- **PartiallyFixedBugs and the TBar.log of the 44-bug 1 h and 5 h runs** — these lived
  in worker dirs / container filesystem of the *original* `chart-repro` container,
  destroyed when it was recreated on 2026-07-03 (before the completion run). All
  plausible patches and done-markers from those runs were persisted to the bind mount
  by design and are complete under `d4j/`. No finding used the lost partials.
- **The all-six-project Part-1 `statstics2` CSVs and per-bug outputs** — wiped by the
  artifact's own `clean.sh` during a Time re-run (the lesson is recorded in the lab
  notebook). The FINDINGS Part 1 table was captured before the wipe and is the
  authoritative record; `part1_remnants/` holds what physically survives.

## Provenance

- Host: `sm06` (2× AMD EPYC 7713), rootless Podman containers `chart-repro`
  (Defects4J side) and `gb-div` (growingBugs side); exact environment and tool
  commits: findings repo METHODOLOGY §6 and §11.
- Paper ground truth used for comparisons: `BaiGeiQiShi/RepairResults` (TBar
  plausible/correct patch sets), fetched 2026-07-06.
