# gb_rerun/rq2/ — RQ2 repair on the pre-registered re-run sample (collected 2026-07-24)

TBar repair evidence for the **14 isolated multi-hunk sub-bugs** derived from the
scaled re-run of `../` (RQ1). Findings repo: **FINDINGS §4.6**; protocol:
METHODOLOGY §8.6 (pilot protocol verbatim, 5 h/bug paper cap).

**Result: 1/14 plausible (Woodstox_6_1, overfitting), 0/14 correct.**
4 searches exhausted, 10 budget-censored at the full 18 000 s.

| Path | What it is |
|---|---|
| `RESULTS_GB2/done/` | 14 completion markers — one per sub-bug, set identical to `scripts/rq2_rerun_bugs.txt` |
| `RESULTS_GB2/fixed/Woodstox_6_1/` | the **16 plausible patch variants** (14 `ConditionalExpressionMutator` + 1 `OperatorMutator` + 1 `StatementRemover`) — all neutralize a downstream sanity check instead of fixing the integer overflow; judgment: FINDINGS §4.6.3 |
| `RESULTS_GB2/fixed/AaltoXml_9_2/` | 4 `LiteralExpressionMutator` **PartiallyFixedBugs** patches — partial ≠ plausible under the paper's definition; this is what the live monitor miscounted as a second fix (FINDINGS §4.6.2) |
| `rq2_tbar2.log.gz` | the TBar run log — per-bug `start` / `end … fixed_dirs=N` markers, the source of every wall time and termination class in FINDINGS §4.6.2 |
| `rq2_fl2.log` | the FL phase log (GZoltar 1.6.0 Ochiai, `relevant_tests`, 120 s/test cap) |
| `rq2_fl_rankings.tgz` | `FL/<bug>/` for all 14: `ochiai.ranking.txt` (what TBar consumed), `cp.txt` (`TBAR_EXTRA_CP` classpath), `info.txt` (failing-test and non-zero-component counts) |
| `scripts/rq2_fl2.sh` | FL driver — flock-guarded, resumable, per-bug `cp.txt` |
| `scripts/rq2_tbar2.sh` | TBar driver — serial, `timeout -k 60 19000` (= paper 5 h), installs each ranking into `C4J_location/105SampleBugsResult/<bug>/`, orphan `pkill` between bugs |
| `scripts/rq2_rerun_bugs.txt` | the 14 sub-bug ids, in run order |
| `completion_markers.txt` | mtimes of the host's `rq2fl2.done` / `rq2tbar2.done` phase markers |

Run window: FL 2026-07-14 14:52 → 15:09; TBar 2026-07-15 09:20:20 → 2026-07-17
13:12:04 (51.9 h wall, 14/14).

## Read this with

- **`../../scripts/tbar_patched_sources_rerun_20260715/`** — the three multi-underscore
  parse fixes without which this run cannot be reproduced: 8 of the 14 sub-bugs belong
  to projects whose name contains `_`, and TBar hard-codes Defects4J's single-token
  `<Project>_<num>` id convention in three places. The `scripts/tbar_patched_sources/`
  snapshot is the **pilot** build and predates these fixes.
- `../README.md` — the RQ1 half of the same re-run (stage-5 evidence, verdict artifacts).
- `rerun_procedure_log.md` in the thesis artifact repo — full timeline, including the
  watcher that never fired and the false done-marker the runner emitted before the fix.

## Not copied

Per-bug checkouts (`/catena/tbar/D4J/projects/<bug>`), TBar's cumulative
`OUTPUT/NormalFL/` tree (of which `RESULTS_GB2/fixed` is the collected per-run copy),
and the recompiled `patched/*.class` files — all reproducible from the sources and
scripts archived here.
