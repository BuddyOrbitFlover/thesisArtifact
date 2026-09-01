# Scale-to-105 extension — REGISTRATION (2026-08-06, before execution)

Goal: extend the gb repair population from 77 to at least 105 run sub-bugs,
mirroring the paper's D4J sample size, with BOTH tools (TBar + Hercules) on
every added sub-bug. Registered after the 77-bug results exist (stated
openly); selection integrity holds because every inclusion below is
determined by pre-existing, result-independent rules and by the pipeline,
never by hand-picking bugs.

## Sources, in fixed order

**S1 — FL repair of the 9 FL-attrition sub-bugs** (already isolated, already
in the population; dropped only because FL generation failed):
Cli_parser_1_1, Jchronic_1_1, Shiro_core_203_1, Spoon_16_1, Zip4j_35_1,
Zip4j_39_1, Zip4j_44_1, Zip4j_46_1, Zip4j_47_1.
Procedure: per-bug diagnosis of the rq2_fl.sh flow (preconditions, checkout,
compile, GZoltar, ranking); fixes are tooling/benchmark adaptations under the
established backup-first, document-in-§8.5 pattern. A bug whose FL cannot be
repaired stays attrition, recorded, never replaced.

**S2 — Diagnosis of the 13 crash-class exception bugs** (Part 1 died in the
runner, not on a protocol budget):
- task-should-end (runner.py:159), 10 bugs: Javapoet_2, RTree_1, RTree_6,
  RTree_7, Tika_core_9, Tika_core_23, Wicket_core_1, Zip4j_1,
  Dropwizard_spring_1, JacksonModuleJsonSchema_1.
- compile-failure parse AssertionError (runner.py:347), 3 bugs: IO_31,
  Tika_core_24, Tika_core_28.
Procedure: collect per-bug run logs, fix root causes (fidelity-neutral
parser/layout fixes only), re-run Part 1 paper-verbatim. Divisible outcomes
feed isolation, FL, and repair. Unfixable stays attrition.

**S3 — EXCLUDED in-protocol: the 14 budget-censored exception bugs**
(11 generator.run() 1 h timeouts: Dagger_core_19, Markedj_5, Pool_12,
Spoon_13, Tika_core_31, Zip4j_37, Zip4j_38, Zip4j_42, Zip4j_45, Shazamcrest_1,
Sparsebitset_1; 3 test-run 900 s timeouts: Pool_14, Tape_6, Zip4j_10).
These are the gb analog of the paper's No_data outcomes. They enter only an
optional extended-budget side experiment, DEVIATION-marked, reported
separately, never in the in-protocol counts.

**S4 — tiny-breadth worklist continuation**, strictly top-down from the first
unprocessed entry of `tiny_breadth_worklist.tsv` (position 36 onward), same
ordering rationale as registered on 2026-07-26 (bugs-per-bring-up, then clone
confidence). Runs until the total run count reaches 105 or the hard stop.
The hard stop date is set at S4 launch, before any S4 results exist.

## Rules (all arms)

1. Paper-verbatim budgets everywhere (Part 1: 1 h/bug, 2048 patterns, 900 s
   test cap; repair: 5 h/bug shared gen+val for Hercules, 5 h TBar).
2. Both tools on every added sub-bug; cross-tool comparison stays on
   identical sets.
3. Take-all past 105: finish the source/project in progress when the count
   crosses 105; never stop mid-project on a result.
4. NEW dedup rule (from the Tascalate_concurrent_1_1 ≡ 2_1 finding):
   byte-identical src patch + identical trigger test across original-bug IDs
   counts as ONE sub-bug; duplicates recorded and excluded from rates.
5. Attrition recorded with its reason, never replaced.
6. The original 77-bug results stay untouched; reporting gives both the
   pre-registered strata (pilot/cap-2/census) and the scaled set.

## Status at registration

77 run (RESULTS_GB/GB2/GB3 + RESULTS_HERC), 9 FL-attrition, 27 exceptions
(14 protocol-censored, 13 crash-class), tiny-breadth processed through
position 35. Exception classification derived 2026-08-06 from
census_exceptions.tgz (all 27 tails read; four classes, counts 11/3/10/3).
