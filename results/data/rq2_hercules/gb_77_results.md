# Hercules gb-77 arm — RESULTS (run completed 2026-08-02, pulled + analyzed 2026-08-03)

Run: `rq2_herc.sh` (gb-div container, paper-verbatim 5 h/bug = harness 18000 s logic,
give-to/Hercules @ eedd7e1ad UNMODIFIED, one-bug-per-invocation orchestration; config
in `registration.md`). Post-disk-incident relaunch 2026-08-01 13:46 PDT; last done
marker Zip4j_32_2 2026-08-02 ~14:32 PDT. Pre-incident markers that survived the
conservative invalidation cutoff retained (earliest: Javapoet_11_1, 07-31).

Pull provenance: `herc_gb_pull.tgz` md5 `06fd91d6bfa5c6f770611fe745490a1a`
(matched sm06 ↔ Mac), extracted to `sm06-localhome/herc_gb_2026-08-03/`
(RESULTS_HERC + herc_buglist.txt + projects/ dev-patch metadata).

## Census (recomputed from done markers 2026-08-03)

- 77/77 done, **0 attrition** (all checkouts + compiles succeeded).
- 76/77 generated ≥1 candidate patch; **23,464 validated patch candidates** total.
- 1 bug generated no patches: **Jfreesvg_1_1** (`done:no_patches:genrc=1`) —
  the one bug TBar repaired CORRECTLY (token-identical NPChecker patch). The single
  cross-tool correct fix on gb is invisible to Hercules.
- **6/77 bugs plausible (7.8 %)**, 70 passing patch instances:

| bug | passing / validated | passing patch families |
|---|---|---|
| Tascalate_concurrent_1_1 | 1 / 188 | SharedFunctions.java:38 condition rewrite |
| Tascalate_concurrent_2_1 | 2 / 212 | same edit, twice (two groups) |
| Zip4j_32_1 | 8 / 189 | sentinel-init zeroing ×7 + getter swap ×1 |
| Zip4j_32_2 | 8 / 189 | identical set to 32_1 |
| Validator_24_1 | 4 / 1051 | line-167 condition variants |
| Woodstox_6_1 | 47 / 521 | throwInternal-guard neutering variants |

## Correctness analysis vs shipped developer sub-bug patches

Criterion (paper §3.1, same as all prior judgments): correct ⇔ identical or
semantically equivalent to the developer patch (`projects/<P>/<bid>/<cid>.src.patch`).
**Final (2026-08-30): 1/6 correct - Validator_24_1; the other five overfitting.** Per bug:

1. **Tascalate_concurrent_1_1 & _2_1** — dev fix relocates
   `return forwardException(failure);` in `AbstractCompletableTask.java` (delete
   L325, insert before L334). Hercules instead rewrites the wrap condition in
   `SharedFunctions.java:38` to
   `if ((e instanceof CompletionException) && (e instanceof ExecutionException))` —
   for the JDK classes this conjunction is unsatisfiable (RuntimeException-branch vs
   checked-Exception branch), so the patch degenerates to "always re-wrap in a new
   CompletionException", which defeats the self-suppression trigger
   (`testSuppressedSelfAddition`) by never passing the same instance through.
   Different file, different mechanism → NOT equivalent. → overfitting.
2. **Zip4j_32_1 & _32_2** — dev fix inserts the sentinel guard
   `if (zip64ExtendedInfo.getOffsetLocalHeader() != -1) { … }` in
   `HeaderReader.java` (the two sub-bugs differ only in guard extent, close at 426
   vs 428). Hercules passers: (a) 7 operator-spellings (`*=`, `%=`, `&=`, `/=`,
   `<<=`, `>>=`, `>>>=` with -1) that all rewrite the three sentinel
   initializations in `Zip64ExtendedInfo.java:28-30` to value 0, changing the
   sentinel convention globally instead of guarding one read; (b) a
   `setUncompressedSize(getCompressedSize())` getter swap in HeaderReader.
   → overfitting (both sub-bugs).
3. **Validator_24_1** — dev fix is two hunks in `InetAddressValidator.java`:
   (H1) restructure the embedded-IPv4 check to
   `if (index == octets.length - 1 && octet.contains("."))`, (H2) L191 add
   `validOctets > IPV6_MAX_HEX_GROUPS ||` rejection. Hercules' 4 passers are
   single-line L167 condition rewrites; the best (`group_17/2`:
   `index < octets.length - 1 || index > 6`) captures H1's intent
   ("IPv4 part must be last") but NO passer touches H2. RE-JUDGED 2026-08-30: the method's
   `octets.length > 8` pre-check plus the retained `index > 6` disjunct make
   H2 unreachable in the patched program, so all four passers are
   semantically equivalent to the dev patch (differential test
   `code/difftest_validator.py`: 0 disagreements over 300k+ structured
   inputs for every passer; confirmed by independent case analysis).
   Single-hunk equivalent of a two-hunk fix (the paper's §4 OA/EOH
   pattern, live). → CORRECT.
4. **Woodstox_6_1** — dev fix corrects the output-limit computation via a new
   `_outputLimit(...)` helper (define-and-use, DU relationship). All 47 Hercules
   passers instead mutate the guard of the `ExceptionUtil.throwInternal(...)`
   sanity check at `BasicStreamReader.java:2057` so it can't fire (incl. the
   literally-always-false `(outPtr < outBuf.length) && (outPtr >= outBuf.length)`,
   group_3/10). The trigger failure IS that throwInternal
   (`TestAttributeLimits::testMaxAttrMaxIntValue$catena_0`). → overfitting.
   **Cross-tool convergence:** TBar's plausible patches for the same bug use the
   same three tricks (guard flip `>`, statement removal, defeating conjunct), and
   TBar `ConditionalExpressionMutator/Patch_782_559` is **character-identical** to
   Hercules `group_3/18` (`… && (checkCDataEnd(outBuf, outPtr))`). Two unrelated
   tools independently emit the same overfitting patch.

## Cross-tool comparison on the identical 77 (final, 2026-08-30)

| | plausible bugs | correct (final) |
|---|---|---|
| TBar (census 58 + pilot 5 + rerun 14) | 9/77 (11.7 %) | 1 (Jfreesvg_1_1, token-identical) |
| Hercules | 6/77 (7.8 %) | 1 (Validator_24_1, semantically equivalent) |

- Overlap (both plausible): Tascalate_concurrent_1_1, Tascalate_concurrent_2_1,
  Woodstox_6_1. Hercules-only: Zip4j_32_1, Zip4j_32_2, Validator_24_1.
  TBar-only: Dagger_core_13_1, Jcabi_aether_1_1, Jcabi_aether_1_2,
  Spring_context_support_2_1, Zip4j_29_1, Jfreesvg_1_1.
- Paper baseline, Hercules: D4J-105 = 19 plausible (18.1 %) / 2 correct.
  gb-77 = 6 plausible (7.8 %) / 1 correct (final 2026-08-30). Repair-scarcity
  direction confirmed and amplified on the independent population.

## Benchmark-construction findings (new, for §8.5 / threats)

- **Duplicate sub-bug:** Tascalate_concurrent_1_1 ≡ Tascalate_concurrent_2_1 —
  byte-identical `1.src.patch` (md5 6cff2348e4b485888675580763661a84), identical
  (empty) test patch and identical trigger test, listed under two different
  original bug IDs. Both tools "repair" both copies → inflates plausible counts
  by one for every tool; the gb→Catena isolation pipeline has no cross-original
  dedup. Registry rows are also duplicated (`bugs-registry.csv` lists 1,1 / 2,1
  twice each).
- **Near-duplicate sub-bugs:** Zip4j_32_1 vs _32_2 dev patches differ only in the
  guard's closing position; Hercules passes the identical patch set on both.

## Final verdicts (2026-08-30)

Criterion: correct ⇔ identical or semantically equivalent to dev patch.
Validator_24_1 CORRECT (re-judged; see the per-bug entry above); the other
five Hercules-plausible bugs overfitting. Woodstox_6_1 overfitting for both
techniques (same mechanism, partly identical patch).

## Raw done markers (77, verbatim)

See `RESULTS_HERC/done/` in the pull; plausible rows repeated here:

```
Tascalate_concurrent_1_1  done:genrc=0:vrc=0:pats=188:pass=1
Tascalate_concurrent_2_1  done:genrc=0:vrc=0:pats=212:pass=2
Validator_24_1            done:genrc=0:vrc=0:pats=1051:pass=4
Woodstox_6_1              done:genrc=0:vrc=0:pats=521:pass=47
Zip4j_32_1                done:genrc=0:vrc=0:pats=189:pass=8
Zip4j_32_2                done:genrc=0:vrc=0:pats=189:pass=8
Jfreesvg_1_1              done:no_patches:genrc=1
```

## Validation-censoring census (added 2026-08-03, after the Math_18_1 diagnosis)

Method: per bug, compare ranked patches (rank.txt in the patches tarball)
vs verdicts rendered (results/<bug>.txt). Mismatch = the shared 18000 s
gen+val budget cut the ranked list (the Math_18_1 mechanism).

Result: 70/76 patch-producing bugs FULLY VALIDATED (verdicts final).
6 validation-censored, all at ~300 min total:

| bug | ranked | validated | pass | note |
|---|---|---|---|---|
| Sparsebitset_2_1 | 2333 | 747 | 0 | verdict = not-plausible-within-budget |
| Woodstox_2_1 | 962 | 650 | 0 | " |
| Woodstox_5_1 | 1621 | 1188 | 0 | " |
| Zip4j_20_1 | 426 | 119 | 0 | " |
| Zip4j_30_1 | 751 | 712 | 0 | " |
| Woodstox_6_1 | 1678 | 521 | 47 | already plausible; count of passers may understate |

Implications: the 6/77 plausible headline can only be UNDERSTATED by this,
never inflated; the paper's protocol has the identical property (validation
depth = f(throughput)), so cross-population comparison remains apples-to-apples.
Thesis tables must carry a termination column: fully-validated vs
validation-censored (5 not-plausible verdicts are censored).
Optional sensitivity analysis (post-D4J-arm): out-of-budget tail validation
of the 5 censored bugs (~2.7k patches), DEVIATION-marked, analogous to the
TBar 1h-vs-5h side experiment.
