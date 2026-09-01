# S6 expansion registration (2026-08-13)

User decision 2026-08-13: reach >= 105 run sub-bugs (currently 92) using ONLY
the arm-B population: D4J-v2.0-shared projects, gb-only bug IDs. This
supersedes the S5 reserve (apache-map) as the next fill source; the reserve
remains the registered backstop if S6 yield still undershoots 105.

## Selection rule (result-independent, fixed before any run)

ALL remaining gb-only bug IDs of the 10 D4J-shared projects from
NewBugs.md @ f198b74 (authoritative), i.e. everything arm B's cap-2 rule left
behind. The cap-2 rule of the S5 registration is explicitly lifted for this
arm (user decision; recorded, not silent). Cli (41-42), Codec (19) and
Csv (17) are already exhausted by arm B.

-> `s6_bugs.txt`, 101 bugs / 7 projects:
Collections 31,35 (2) · Compress 52,53 (2) · Gson 3-25 (23) ·
JacksonCore 30,31 (2) · JacksonDatabind 122-126,128-129,131-133,135-156 (32) ·
Lang 73,76,80-84 (7) · Math 3-35 (33).

Note: NewBugs.md's count column says JacksonDatabind 33 but its own ID list
enumerates 34; per-ID verification against active-bugs.csv is authoritative
(all 101 selected IDs present, patches/<id>.src.patch present, checked on the
Mac copy @ f198b74, 2026-08-13).

Like arm B, this arm deliberately relaxes the project-level D4J-independence
criterion — that is its purpose (new bugs in D4J's own projects). Reported
as arm-B-extension; never silently pooled into the gb-new population.

## Dedup

- Overlap with arm B's 18: comm = 0 (checked 2026-08-13).
- The 7 projects appear in no other arm (census/tinyb/pilot/re-run/S5-A
  exclude D4J-shared projects by design; verified for arm B on 2026-08-10).
- D4J-side runs (TBar/Hercules D4J-105) use D4J bug IDs; zero ID overlap by
  the gb-only definition.

## Protocol

Unchanged and paper-verbatim: stages 1-5 with 1 h/bug, 2048 patterns,
900 s compile/test caps; repair = GZoltar 1.6.0 Ochiai FL + TBar 5 h/bug,
then Hercules (rq2_herc protocol) on the same minted set. FL harness carries
the documented S8.5 adaptations (classpath sanitizer; GZoltar timelimit
raised where suites need it). Isolation-check gate applies as in S5.
Repos: all 10 already cloned (S5 clone stage); binshim v4/v5 map covers Gson.
Stage 5 runs in isolated dirs (generate_bugs_s6*) for the Math/Gson
namespace reason recorded in the S5 amendment. OPEN implementation item
(inherited from S5, becomes real only if Math/Gson mint sub-bugs):
/catena/projects/{Math,Gson} registry dirs are D4J-occupied; minted gb
sub-bugs from these two projects need a registry alias before RQ2 runs.

## Expected yield (stated before running)

Arm-B observed rate: 18 parents -> 1 usable run sub-bug. S5-overall rate:
52 -> 4. Applied to 101 parents: ~5-8 usable expected, pool ~97-100.
Reaching 105 will likely ALSO need the apache-map reserve; S6 is worked
first per user direction 2026-08-13 ("13 or more, D4J-shared gb-only IDs").

## Amendment 2026-08-13 (post-smoke): Math_20 dropped

Smoke gate: 100/101 OK, 1 FAIL = Math_20. Diagnosis (gb-div, 2026-08-13):
both revisions of active-bugs row 20 exist in commons-math.git, but the
framework's own patches/Math/20.src.patch fails to apply at its pinned
revision (git apply -p1: "patch failed:
.../optimization/direct/CMAESOptimizer.java:24"; -p0/-p2 path-fail).
Framework-side mined-revision skew (S2 class, but inside growingBugs
itself); bug unusable without modifying the gb dataset. DROPPED as
attrition per the smoke criterion (unmodified framework must check the
bug out). S6 list: 101 -> 100. Chain resumed from stage 1.
