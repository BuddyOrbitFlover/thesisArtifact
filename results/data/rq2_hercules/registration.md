# Second-tool RQ2 arm: Hercules — REGISTRATION (2026-07-30, before execution)

**Decision (user): extend RQ2 with a second APR tool, Hercules** (`github.com/give-to/Hercules`,
the paper authors' own replication harness), on the **same 77 sub-bugs TBar ran**
(pilot 5 + cap-2 re-run 14 + census 58; the 9 FL-attrition sub-bugs stay excluded —
identical denominator, clean cross-tool comparability).

## Tool selection (vs the paper's other six)

Constraint set: sm06 is CPU-only (verified: full PCI class scan shows only the ASPEED
BMC display; no render nodes) → AlphaRepair (18/7), Recoder (17/3), ITER (13/2) are out
(CUDA-pinned replication stacks). Among CPU tools: SimFix's paper baseline is 3/105
plausible → near-zero expected signal on 77; ARJA-e is stochastic (breaks the §5
determinism argument) with 0 correct baseline. **Hercules: 19/105 plausible, 2 correct,
CPU, deterministic harness, and scientifically the sharpest complement — a
multi-hunk-SPECIALIZED technique on the multi-hunk benchmark, directly probing the
thesis's edit-space-bottleneck mechanism** (can simultaneous-sibling editing do what
single-location templates cannot?). Paper baselines counted from `RepairResults/`
patch dirs (TBar 20/4 · AlphaRepair 18/7 · Hercules 19/2 · Recoder 17/3 · ARJA-e 13/0 ·
ITER 13/2 · SimFix 3/2).

## Protocol

1. Paper-verbatim per-bug budget: **5 h wall** (the harness's own timeout), Normal FL =
   **our existing GZoltar 1.6.0 Ochiai rankings** (`/catena/FL/<bug>/ochiai.ranking.txt`,
   identical inputs to the TBar arm), CatenaD4J checkouts from our registries.
2. **Bring-up is incremental (§5.1):** clone + install → harness code review → single-bug
   smoke → full run. All harness adaptations follow the sanctioned pattern: backup
   originals, mechanical fixes only (expected: multi-underscore id parsing, project
   layout, classpath — the TBar §8.5/§4.6.4 family), each documented.
3. **4 workers planned** (per-worker isolated roots, chunked by parent bug), contingent
   on harness review; serial fallback if the tool resists isolation. Defunct-aware
   reaper. Results → **`RESULTS_HERC/{done,fixed-equivalent}`**; GB/GB2/GB3 untouched.
4. Attrition: bugs the harness cannot run after mechanical fixes are recorded with
   reasons and excluded, never replaced.
5. Reporting regardless of outcome: per-arm (D4J-comparison vs the paper's published
   Hercules patches, exactly as done for TBar) and cross-tool (TBar vs Hercules on the
   identical 77). Correctness judgment per the established criterion (semantic
   equivalence to dev fix), user-signed.
6. Stop rule: run to completion of the 77 in fixed chunk order; if stopped early
   (user call), the completed prefix is reported as such.

## Cost estimate (stated before running)

Bring-up 1–3 days (unknown-unknowns certain) + ≤4 days compute (77 × ≤5 h ÷ 4 workers)
+ judgment. Sequenced AFTER thesis-writing viability was flagged to the user; user chose
to proceed.

## Provenance note (added 2026-07-30, pre-execution)

`give-to/Hercules` is **not the original IBM Hercules** (never released). It is the
FSE'24 authors' **reimplementation** — README: "Since the source code is not provided
by the authors, we implement Hercules in this repository according to the description
in the paper" — with documented deviations: **Hercules-MinusHistory variant only, ODS
replacing Elixir's ranking model, some templates removed**. Consequences, pre-declared:
1. Thesis naming: "the paper's Hercules reimplementation (MinusHistory)"; comparison
   target is the FSE'24 baseline (19/105 plausible, 2 correct) produced by this code —
   never the 2019 paper's numbers.
2. No tags/releases (33 commits) → **pin and record the commit SHA at clone time**.
3. **Empirical identity check before gb:** run the harness's Chart_18_2 quick test and
   compare the produced patch against `RepairResults/Hercules` published patches
   (TBar precedent: Closure_106_2/138_1 patch-identity). Proceed to gb only on match
   or explained difference.

### Link chain (added 2026-07-30, answering "where did you get hercules from — not in either paper")

Correct: neither PDF links it. The reference is two hops deep in the FSE'24 artifact:
1. FSE'24 paper → official artifact repo `indivisible_multihunk_bug_repair` (ACM-badged,
   DOI per its STATUS.txt; local copy `clean/Multi-Hunk_Bugs/indivisible_multihunk_bug_repair/`).
2. Artifact README, "Artifact part 2" → `github.com/BaiGeiQiShi/RepairResults` (tag v1.0.0;
   local copy `clean/Multi-Hunk_Bugs/RepairResults/` — `git remote` + `git describe --tags`
   verified 2026-07-30: origin matches, tag = v1.0.0).
3. `RepairResults/README.md` §4 Hercules: "Please refer to
   [here](https://github.com/give-to/Hercules) for experiment replication." The same README
   links `give-to/TBarAPI` (§5, the TBar repo this thesis already used, remote-verified) and
   `give-to/AlphaRepairAPI` (§1) — corroborating `give-to` as the authors' replication org.

Saha et al. FSE'19 released no code, so no link exists in that paper by construction;
`give-to/Hercules` is the FSE'24 authors' reimplementation (see Provenance note above).

### Correction to the link chain (2026-07-30, after reading the PDF references)

The FSE'24 PDF **does** cite the RepairResults repo directly: ref **[7]** = "Artifact APR
Repair Tools and Results 2023. The tool evaluation part of artifact.
https://github.com/BaiGeiQiShi/RepairResults", invoked in §3.1: "More details can be
found at the tool usage repositories accessible from [7]". So the chain to Hercules is
one hop from the paper, not two: **paper ref [7] → RepairResults README §4 →
give-to/Hercules.** The Hercules URL itself is still not printed in the PDF — only
reachable via [7].

Also resolved: ref **[28]** = "GZoltar 2023. The GZoltar tool. https://gzoltar.com/" —
the paper's "Ochiai-based SBFL method [28]" (§3.1, Hercules description) is GZoltar
with Ochiai, confirming METHODOLOGY §8.4's sourcing.

### Identity check result (2026-07-30) — PASSED

Smoke (herc_smoke2.sh in chart-repro, README quick-test = short.txt single-location FL):
generation 22 s, whole smoke ~14 min. Validation: 31 patches tested, 7 Pass, 21 Fail,
3 Build Error. **Our passing set {2,7,10,26,27,31,32} is exactly the published plausible
set of RepairResults group_9 — same IDs, and all 7 patch contents byte-match
(whitespace-insensitive diff, verified on Mac). The paper's three published CORRECT
patches from that group (2, 26, 27) are all among our passers.** Explained differences,
both FL-truncation artifacts of the quick test: (a) group index 0 vs 9 — short.txt has
one location, the full ranking reaches it as its 10th group; (b) published groups 6
(line 317) and 14 (line 337) absent — their locations are not in short.txt.
Per the pre-declared criterion ("match or explained difference") → **proceed to the
gb adaptation.**

### Amendment (2026-07-30, user direction, pre-execution): full D4J-105 replication arm

User: "the scientific way i am trying to go is first see if i can replicate the study's
numbers, then try new bench" — matching the TBar precedent (105 D4J reproduction before
gb). The single-bug identity check is therefore upgraded to a **full replication of the
paper's Hercules experiment**: all 105 CatenaD4J sub-bugs, in chart-repro, with the
AUTHORS' shipped FL (`location/105SampleBugsResult`, Chart_18_2 full ranking restored
from their backup.txt) and their `105_bugs_list.txt`, unmodified code, 5 h/bug via the
harness's own logic. **Pre-declared comparison target: 19/105 plausible, 2/105 correct
(Chart_18_2, Closure_6_2).** Runs concurrently with the gb arm under the ≤32-core
budget: 2 workers now, workers 2+3 started once the gb run finishes. Results →
RESULTS_HERC_D4J. Execution order (gb launched first) noted; the arms are independent
and the thesis reports replication before generalization regardless.
