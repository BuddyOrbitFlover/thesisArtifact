# Scale-up extension — REGISTRATION (2026-07-26, before execution)

**Goal (user, 2026-07-26): maximise bugs run through the pipeline within a ~1.5-week
window, combining the already-expanded 28 frame projects with a breadth batch of small
(1–2 bug) projects.** Registered before execution; amends and absorbs the census-B
registration (`gb_census_b_registration.md`, same directory, committed 7d2c259 — nothing
from it has run yet, so this supersedes it cleanly).

Two arms, run in parallel (sm06 compute unattended ∥ manual bring-up):

## Arm 1 — Backbone: 28 frame projects, uncapped (ZERO bring-up)

Identical to census-B: the full 28-project frame = 364 bugs, **171 fresh multi-hunk**
(`census_b_fresh_multihunk.txt`; 39 already dispositioned and adopted). Repos already on
sm06. This is the guaranteed part — it needs only compute.

## Arm 2 — Breadth batch: small projects, greedy by bug-per-effort

Population: the **130 non-frame, non-D4J-shared projects with ≤2 bugs** (172 bugs total;
86×1-bug + 42×2-bug + 2 name-resolved). All have growingBugs framework data locally
(patches/tests/build files); **none have source repos** — each must be cloned from
upstream. That clone step is the entire bring-up cost and the binding constraint.

**Pre-registered ordering** — `tiny_breadth_worklist.tsv` (committed with this doc),
ranked by: (1) 2-bug before 1-bug (more bugs per clone), (2) clone-confidence
`github-exact` → `apache-map` → `redhat-hunt`/`hunt`. Clone URLs were extracted from each
project's `report.url` (GitHub issue links give the exact repo; Apache-Jira links map to
`github.com/apache/<repo>`):

| Confidence | Projects | Bugs | Clone URL source |
|---|--:|--:|---|
| github-exact | 55 | 75 | exact, embedded in the worklist |
| apache-map | 60 | 81 | `github.com/apache/<repo>`, one resolve step |
| redhat-hunt / hunt | 15 | 16 | manual |

**Worked strictly top-down; hard stop at the 1.5-week mark (target 2026-08-05).**
Whatever is brought up by then is the arm-2 sample. Ordering is fixed here and is
**result-independent** (bug-count + URL-confidence only, known before any run), so
stopping early introduces no selection bias.

## Pre-declared rules (both arms)

1. **Protocol paper-verbatim:** stage 5 IBugFinder 1 h/bug, 2048 patterns, 900 s test
   cap, `-n 4`; RQ2 GZoltar 1.6.0 Ochiai FL + TBar 5 h/bug (`timeout -k 60 19000`),
   patched harness.
2. **Adoption:** existing pilot/cap-2 dispositions kept; single-hunk bugs excluded after
   stage 2 (`Single_divided`).
3. **Attrition:** any project failing clone/checkout/build/export is recorded with its
   reason and **excluded, never replaced**. Expected 20–40 % attrition on the unvetted
   tail — the completed set is reported as-is. Benchmark-artifact fixes follow the
   established backup-first, scope-to-revision, document-in-§8.5 pattern.
4. **TBar capacity is the RQ2 ceiling.** At 5 h/bug × 4 workers ≈ 20 sub-bugs/day; over
   the ~5 TBar-days of the window ≈ **~100 sub-bugs max**. Arm 1 alone yields ~75, so RQ2
   runs arm-1 sub-bugs first, then arm-2 sub-bugs in worklist order until the clock stops.
   RQ2 will therefore be **backbone-heavy**; arm 2's value is concentrated in **RQ1
   breadth** (distinct-project count), which is the cheaper, more scalable measure.
5. **Results dirs:** divisibility → `working/` (additive; `2toMore` backed up first);
   repair → **`RESULTS_GB3`** (GB/GB2 untouched). 4-worker TBar chunked by parent project
   so same-parent sub-bugs never run concurrently (workdir collision); per-bug 5 h budget
   unchanged. Implementation note in METHODOLOGY (pilot/cap-2 ran serial; D4J baseline ran
   4 workers) — not a paper-parameter deviation.
6. **Pseudo-replication:** arm 2 is naturally cap-2; arm 1 abandons the cap (Zip4j 39/210
   of arm-1 multi-hunk). Committed mitigation: report per-project, plus a cap-2/cap-4
   sensitivity slice (the seeded draws are subsets that already exist).
7. **Reporting:** four strata always reported regardless of outcome — pilot / cap-2 re-run
   / arm-1 backbone / arm-2 breadth — plus combined.

## Expected end state (order-of-magnitude, stated before running)

| | before | after (target; ~30 % attrition folded in) |
|---|--:|--:|
| Distinct projects in RQ1 | ~30 | **~110–130** |
| Determined multi-hunk (RQ1) | 45 | **~230–250** (approaching paper's 257) |
| RQ2 sub-bugs | 19 | **~90–100** (approaching paper's 105) |

RQ1 becomes decisively separable from D4J's 54.1 % and carries a genuine breadth claim
(~8× the paper's project count). RQ2 nears paper scale in n but its plausible-rate CI
(±~6 pp) still likely overlaps 19 % — the claim stays *consistency/generalization*, not
*difference*.
