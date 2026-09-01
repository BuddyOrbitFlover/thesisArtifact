# tbar_patched_sources_rerun_20260715/ — the multi-underscore parse fixes

Applied **2026-07-15** so the RQ2 re-run (`gb_rerun/rq2/`) could run at all. Distinct
from `../tbar_patched_sources/`, which is the **pilot** build (2026-07-06) and does not
contain these fixes — see the note at the bottom.

## Why

8 of the 14 re-run sub-bugs belong to projects whose name contains `_`
(`Johnzon_core`, `Jcabi_log`, `Dagger_core`, `Google_java_format_core`). The pilot's
four projects (Text, Jfreesvg, Graph, Bcel) are single-token and never exercised this.
**TBar and the CatenaD4J runner hard-code Defects4J's single-token `<Project>_<num>` id
convention in three independent parse sites**, each failing differently:

| File | Failure before the fix |
|---|---|
| `runTBarForCatenaD4J.py` (`:76-79`) | `split('_')[0/1/2]` → project `Johnzon`, version `coreb4` → catena4j "Wrong version_id", crash in ~3 s **and a false `done` marker** |
| `Main.java` (`:39-43`) | `parseInt(elements[1])` → `NumberFormatException` → "Please input correct buggy project ID", exit in 0.15 s |
| `PathUtils.java` (`getSrcPath:12-14`) | `parseInt(words[1]) = "core"` → NFE at `DataPreparer.loadPaths:58`, exit in 6.5 s |

Same fix in each: project name = all `_`-separated tokens but the last (two last, for
the runner's `<project>_<bug>_<cid>`); id = the trailing token(s).

The false done-marker is the reason this matters beyond convenience — unfixed, the
runner would have recorded all 8 foreign-project sub-bugs as "run" after a 3 s crash.

## Files

| File | |
|---|---|
| `Main.java`, `PathUtils.java`, `runTBarForCatenaD4J.py` | the patched versions actually used in the run |
| `*.premultiunderscore.bak` | the untouched originals, as backed up on the host before patching |
| `multiunderscore.diff` | unified diff of each pair — the complete change |

Both TBar classes were recompiled into the host's `patched/` dir with
`javac -cp "patched:target/dependency/*" -d patched …` (rc=0) and take precedence on
the classpath; `grep` confirmed these are the only `split("_")` sites in the normal-FL
flow (`MainPerfectFL.java` / `Main_NFL.java` are the unused perfect-FL / no-FL variants).

## Relation to the pilot snapshot

`../tbar_patched_sources/PathUtils.java` is byte-identical to
`PathUtils.java.premultiunderscore.bak` here (md5 `5c4e71dd2ec6f4f0b5a20b594510dedf`).
It is kept unchanged on purpose: it is the correct record of what the **pilot** ran.
`Main.java` and `runTBarForCatenaD4J.py` were not patched at pilot time and appear here
for the first time.

Findings repo: **FINDINGS §4.6.4**; METHODOLOGY §8.5/§8.6 (Defects4J-shaped tooling
assumptions as an external-validity result).
