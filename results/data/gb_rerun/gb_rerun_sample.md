# growingBugs re-run — PRE-REGISTERED SAMPLE (FINAL, cap 2; revised 2026-07-14 pre-results)

Frame: `gb_rerun_candidate_projects.md` (2026-07-09), minus the 5 Defects4J-v2.0-known
projects → 28 foreign-only projects. **Cap revised 4→2 on 2026-07-14 (user decision,
before any Part-1/Part-2 results existed): sample = 55 bugs, 47 fresh.**
Population: non-Defects4J unique bugs per `NewBugs.md` @ growingBugs `f198b74` (pinned).

## Draw procedure (deterministic, no hand-picking)
- Script: `gb_rerun_seeded_draw.py`. **SEED = 20260714**, CAP = 2.
- Per project P, independently: `ids = sorted NewBugs.md IDs of P`; if ≤CAP take all,
  else `random.Random(f"20260714:{P}").sample(ids, CAP)`, sorted.
- The earlier cap-4 registration (33→28 projects / 107 bugs) is fully reproducible from
  the same script with CAP=4; the cap-2 draw is a prefix-subset of it (same seed stream).

## Decision log (all pre-results)
1. **2026-07-14:** 5 D4J-v2.0-known frame projects (Collections, Compress, Gson,
   JacksonCore, JacksonDatabind) EXCLUDED — project-level D4J independence
   (METHODOLOGY §4.1 crit 1). No post-draw replacements.
2. **2026-07-14 (after checkout smoke, before any experiment):** cap 4→2 — user needs
   a smaller sample; breadth (all 28 projects) retained over depth.

## Validation
- Checkout smoke on sm06 (2026-07-14): **93/93 of the cap-4 fresh set OK** after two
  growingBugs data fixes (below) — the cap-2 fresh 47 is a subset, so fully covered.
- All drawn bugs exist in `active-bugs.csv` @ f198b74; all project dirs present.

## growingBugs artifact fixes applied on sm06 (documented, backed up, scoped)
1. **Tika_core `dir-layout.csv` conflicting duplicate rows** (30 revs affected;
   framework parses last-row-wins → wrong bare `src/main/java` layout while patches
   prove `tika-core/...`). Removed the 4 spurious rows for bugs 29/36's revs.
   Backup: `dir-layout.csv.bak20260714`.
2. **Tika_core `build_files/<rev>/` self-nested junk copies** (dir copied into itself
   during mining; plain `cp *` in Tika_core.pm:86 dies on the nested dir). Deleted the
   nested dirs for the same 4 revs. Backup: `/localhome/klee/tika_buildfiles_bak20260714.tgz`.
   → Both belong in METHODOLOGY §8.5 (benchmark-artifact adaptations, Jimfs-symlink family).

## THE SAMPLE (28 projects, 55 bugs; ★ = pilot project, Part 1 already done)

| Project | drawn | | Project | drawn |
|---|---|---|---|---|
| IO | 12, 16 | | Jcabi_log | 4, 9 |
| Validator | 8, 15 | | Dagger_core | 3, 17 |
| Pool | 5, 21 | | Jimfs ★ | 1, 2 |
| Bcel ★ | 3, 5 | | Google_java_format_core | 1 |
| Graph ★ | 1, 2 | | Zip4j | 11, 25 |
| Text ★ | 1, 4 | | Spoon | 7, 9 |
| Tika_core | 6, 36 | | Javapoet | 3, 15 |
| Wicket_core | 10, 16 | | Markedj | 1, 14 |
| Johnzon_core | 4, 8 | | Tape | 2, 8 |
| Shiro_core | 176, 181 | | RTree | 3, 4 |
| Rdf4j_rio_turtle | 1, 2 | | Proj4J | 4, 6 |
| AaltoXml | 2, 9 | | Streamex | 2, 4 |
| Woodstox | 1, 6 | | Vectorz | 2, 4 |
| Jcabi_http | 8, 14 | | Disklrucache | 1, 2 |

**Totals: 55 drawn; ★ pilot-covered 8 (Bcel 3,5 · Graph 1,2 · Text 1,4 · Jimfs 1,2) →
47 fresh across 24 new projects.** Pilot projects not in the frame stay pilot-only.

## Experiment steps (paper-verbatim, as pilot)
1. **Part 1 — divisibility:** stages 1–4, then stage 5 IBugFinder (1h/bug, 2048
   patterns, 900s test cap). Multi-hunk n resolves after stage 2 (expect ~20–27).
2. **Part 2 — repair:** GZoltar 1.6.0 Ochiai FL + TBar at 5h/bug (pilot-patched
   harness) on the isolated multi-hunk sub-bugs; manual correctness vs dev patch.

## Machine-readable draw (55; ★-project bugs marked reuse)
```
IO_12 IO_16 Validator_8 Validator_15 Pool_5 Pool_21
Tika_core_6 Tika_core_36 Wicket_core_10 Wicket_core_16
Johnzon_core_4 Johnzon_core_8 Shiro_core_176 Shiro_core_181
Rdf4j_rio_turtle_1 Rdf4j_rio_turtle_2 AaltoXml_2 AaltoXml_9
Woodstox_1 Woodstox_6 Jcabi_http_8 Jcabi_http_14 Jcabi_log_4 Jcabi_log_9
Dagger_core_3 Dagger_core_17 Google_java_format_core_1
Zip4j_11 Zip4j_25 Spoon_7 Spoon_9 Javapoet_3 Javapoet_15
Markedj_1 Markedj_14 Tape_2 Tape_8 RTree_3 RTree_4
Proj4J_4 Proj4J_6 Streamex_2 Streamex_4 Vectorz_2 Vectorz_4
Disklrucache_1 Disklrucache_2
Bcel_3(reuse) Bcel_5(reuse) Graph_1(reuse) Graph_2(reuse)
Text_1(reuse) Text_4(reuse) Jimfs_1(reuse) Jimfs_2(reuse)
```
