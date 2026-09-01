# Census-B extension — REGISTRATION (2026-07-25, before execution)

**Design B: lift the per-project cap and run the *entire* 28-project frame — a census
of all 364 non-Defects4J bugs — through the Part-1/Part-2 pipeline.** Registered here
before any execution; push this commit before running anything.

## Relation to the existing arms (containment, nothing re-run)

- Frame: `../gb_rerun_candidate_projects.md` (2026-07-09) minus the 5 D4J-v2.0-known
  projects — identical to the cap-2 re-run's frame. **No new projects; all 28 are
  already brought up** (2026-07-14 bring-up, checkout smoke 93/93 on the cap-4 set).
- The cap-2 sample (55) and the pilot's frame-project bugs are strict subsets of the
  census. **All existing dispositions are adopted verbatim; no bug is re-run.**
- This is a **post-results extension** (the cap-2 results exist and are published in
  FINDINGS §3.3/§4.6). Honesty measures: this registration is committed before
  execution; results will be reported in three strata — pilot / pre-registered cap-2 /
  census extension — plus combined, **regardless of outcome**.

## Exact numbers (derived 2026-07-25 from `parse_patches/patches/<P>/<id>.json`; the
enumeration reproduces the re-run's 31 fresh multi-hunk bugs exactly)

| | |
|---|--:|
| Census bugs (28 projects) | 364 |
| Multi-hunk (≥2 hunks) | **210** (57.7 %) |
| — already dispositioned (re-run 31 + pilot frame-projects 8) | 39 |
| — **fresh workload, this arm** | **171** |
| Expected determined (87 % observed) | ~149 |
| Expected new RQ2 sub-bugs (0.45/MH observed) | ~75–80 → RQ2 total ~95 |

Fresh multi-hunk per project: Zip4j 39, Tika_core 15, Dagger_core 10, Spoon 10,
Validator 9, Pool 9, Javapoet 9, IO 7, Jcabi_http 7, RTree 7, Wicket_core 6,
Johnzon_core 6, Proj4J 6, Markedj 5, Rdf4j_rio_turtle 4, Jcabi_log 4, Shiro_core 3,
Tape 3, Streamex 3, Vectorz 3, AaltoXml 2, Woodstox 2, Disklrucache 2.

Machine-readable: [`census_b_fresh_multihunk.txt`](census_b_fresh_multihunk.txt) (171).

## Pre-declared rules

1. **Protocol paper-verbatim, unchanged:** stage 5 = IBugFinder 1 h/bug, 2048 patterns,
   900 s test cap, `-n 4`; RQ2 = GZoltar 1.6.0 Ochiai FL (relevant_tests, 120 s/test) +
   TBar 5 h/bug (`timeout -k 60 19000`), patched harness as in the re-run.
2. **Adoption:** every bug with a pilot or cap-2 disposition keeps it; single-hunk bugs
   (hunk JSONs, stage 2 — already computed for all 364) take no further part.
3. **Attrition:** a bug failing checkout/build/export is recorded with its reason and
   **excluded, never replaced**. Benchmark-artifact fixes follow the established
   pattern (backup first, scope to affected revisions, document in METHODOLOGY §8.5).
4. **Pseudo-replication disclosure:** the census abandons the registered cap; Zip4j
   alone is 39/210 of census multi-hunk (18.6 %). Committed mitigation: results
   reported per-project, and a **sensitivity analysis at cap-2 and cap-4** (the seeded
   draws already exist and are subsets) alongside the census figures.
5. **TBar execution: 4 parallel workers**, chunked by parent project so same-parent
   sub-bugs never run concurrently (workdir collision). Per-bug 5 h wall budget
   unchanged; precedent: the study's own D4J baseline ran 4 workers (`wkrem_0–3`).
   Implementation note in METHODOLOGY (pilot and cap-2 re-run happened to run serial);
   not a paper-parameter deviation. Results dir: **`RESULTS_GB3`** (GB/GB2 untouched).
6. **Stopping rule:** the arm is the full 171-bug list; if wall-clock forces an early
   stop, the completed subset is reported as such (list order is alphabetical and was
   fixed at registration — no result-dependent ordering).

## Expected wall-clock (sm06)

Stage 1 (checkout+export, 171 bugs, resumable): ~2–6 h · stage 4 (split tests): ~1–2 h ·
stage 5: ~10–14 h · FL: ~0.5 d · TBar: ~285 h serial ≈ **~3 days at 4 workers** ·
total ≈ **4–6 days sm06 wall**.

## What this buys (stated before running)

- RQ1 at ~185–200 determined across all arms: a divisibility rate holding near ⅔
  becomes decisively distinguishable from D4J's 54.1 % (z ≈ 3–4).
- RQ2 at ~95 sub-bugs: the plausible-rate CI narrows to roughly ±6 pp; a difference
  from the paper's 19 % becomes testable but is **not guaranteed to reach
  significance**. The correct-rate comparison stays qualitative at any feasible n.
