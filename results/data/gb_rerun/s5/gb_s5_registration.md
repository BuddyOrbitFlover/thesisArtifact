# S5 expansion registration (2026-08-10)

Amendment to the scale-to-105 plan (supersedes the S4 worklist as the fill
source; user decision 2026-08-10). Goal: RQ2 pool from ~89 (83 adopted + up
to 6 in-flight FL rescues) to ~105 isolated multi-hunk sub-bugs.

## Selection rules (result-independent, fixed before any run)

**Arm A — untouched tiny projects (gb-only population).** All remaining
github-exact rows of the pre-registered `tiny_breadth_worklist.tsv` whose
project was never run in any prior arm, minus the 5 pilot-project rows
(Dbutils, Jackson_annotations, Jfreesvg, Ognl, Rdf_jena) and dead-upstream
Doubleclick_core. Every project has <= 2 gb bugs. Repos already cloned on
sm06 during scale-up B2 (zero bring-up).
-> `s5_armA_bugs.txt`, 34 bugs / 25 projects.

**Arm B — same-project/new-bugs (D4J-shared projects, gb-only bug IDs).**
The 10 D4J-v2.0 projects for which growingBugs carries bugs NOT in Defects4J
(authoritative source: NewBugs.md @ f198b74). Cap 2 bugs/project, tie-break =
LOWEST bug IDs (deterministic, chosen before results). gb `Math` and `Gson`
are new-bug-only numbering; D4J's Math ships separately as `Math_4j` (never
touched). This arm deliberately relaxes the project-level D4J-independence
criterion (METHODOLOGY S4.1 crit 1) — that is its purpose: it probes whether
*new bugs in D4J's own projects* behave like D4J bugs or like gb-new bugs.
Reported as a separate arm; never silently pooled into the gb-new population.
-> `s5_armB_bugs.txt`, 18 bugs / 10 projects
(Cli 41,42 · Codec 19 · Collections 29,30 · Compress 48,50 · Csv 17 ·
Gson 1,2 · JacksonCore 28,29 · JacksonDatabind 112,121 · Lang 69,71 ·
Math 1,2).

**Reserve.** The 57 untouched apache-map worklist projects (77 bugs),
`s5_reserve_apachemap.tsv`, worked in worklist order ONLY if the S5 yield
undershoots the 105 target. No other top-up sources.

## Dedup verification (2026-08-10, on Mac copies @ f198b74)
- Project-level: arm A = worklist rows minus the 29 tinyb-run projects and
  5 pilot projects; arm B projects excluded from every prior arm by design.
- Bug-level: comm of the 52 IDs against censusb_verdict + tinyb_verdict +
  census_b_fresh_multihunk = EMPTY.
- All 52 IDs present in active-bugs.csv with patches/<id>.src.patch @ f198b74.

## Protocol
Pipeline and parameters unchanged and paper-verbatim: stages 1-5 with
1 h/bug, 2048 patterns, 900 s compile/test caps; repair = GZoltar 1.6.0
Ochiai FL + TBar 5 h/bug. FL harness carries the documented S8.5 tooling
adaptations (classpath sanitizer; GZoltar `timelimit` raised from its 600 s
default where suites need it — first proven on Zip4j 2026-08-10).
TBar output dir for S5: RESULTS_S5 (implementation note).
Expected yield: 52 raw bugs x ~0.3 sub-bugs/bug (historical) = ~15-16.

Runbook: `~/Documents/Bachelorarbeit/s5_runbook.md`. RQ2 blocks (sub-bug
export with binary-key cid rule, FL, TBar chunking) get written once the
stage-5 verdict table exists, per established pattern.

## Amendment 2026-08-10 (pre-run): namespace isolation
gb `Math` is a renumbered new-only project, so gb Math_1/2 share NAMES with
D4J Math_1/2 (different bugs). Stage 5 therefore runs in an isolated
`generate_bugs_s5` dir (fresh working/); the equivalent aliasing for the RQ2
registry step (`/catena/projects/Math/` is D4J-occupied) lands with the RQ2
blocks. No change to bug selection.
