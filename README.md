# Reproduction Package for "Experimental Assessment of External Validity, An Initial Exploration of Studies Using Defects4J"

[![MIT License (scripts)](https://img.shields.io/badge/scripts-MIT-brightgreen.svg?style=flat)](LICENSE)
[![CC BY 4.0 (data and documentation)](https://img.shields.io/badge/data-CC%20BY%204.0-brightgreen.svg?style=flat)](LICENSE)

Prepared following the SoSy-Lab checklist for reproduction artifacts
(https://gitlab.com/sosy-lab/doc/-/wikis/Reproduction-Artifacts).

## Authors

Kanghyun Lee, Ludwig-Maximilians-Universität München, Institut für Informatik, SoSy-Lab.
Bachelor's thesis, 2026. Supervisor: Dr. Stefan Winter. Mentor: Sophia Hans.

The thesis is an external-validity study of Xin, Wu, Tang, Liu, Reiss, and Xuan,
"Detecting, Creating, Repairing, and Understanding Indivisible Multi-Hunk Bugs",
Proc. ACM Softw. Eng. 1, FSE, Article 121 (2024), https://doi.org/10.1145/3660828
("the subject paper" below). Its three research questions: RQ0, can the subject paper's
Defects4J results be reproduced (divisibility classification of 281 multi-hunk bugs, repair
of its 105 isolated indivisible multi-hunk bugs with TBar and Hercules)? RQ1, does the
divisibility finding hold on 249 multi-hunk bugs from 60 growingBugs projects that
Defects4J does not contain? RQ2, does the repair finding hold on 97 isolated indivisible
multi-hunk bugs created from growingBugs-new bugs?

## Contents

This artifact consists of five parts:
  1. Setup of the analysis script (and, for re-running experiments, of the tools)
  2. Introductory example task: one isolated bug, from raw run output to its verdict
  3. Running the exemplary benchmark set: the 10-project pilot (26 bugs)
  4. Running the full experiments (several weeks of wall-clock time)
  5. Running the analysis of the experimental data: every table and number of the thesis

The artifact also contains all raw data of the experiment runs. If you only want to
reproduce the claims of the thesis on that data, go straight to Section 5; it needs
Python 3 and about 10 seconds.

The raw data of the experiment runs are in folder `results/raw-evidence/` (unaltered run
outputs pulled from the compute host) and, as machine-readable tables derived from them,
in `results/data/`. The benchmark tasks are the bug lists inside those folders
(`2toMore` files and `catena/*_bugs.txt` inside the host pull) and the benchmarks
themselves are Defects4J 2.0.0 and growingBugs at commit `f198b74`, obtained from their
upstream repositories (not redistributed here).

```
README.md, LICENSE, SHA256SUMS      this file, licensing, checksums of every file
reproduce.py                        recomputes every table and number (Python 3.8+, no dependencies)
make_archive.sh                     rebuilds SHA256SUMS and the zip archive
generated/numbers.tex               LaTeX macros written by `reproduce.py tex`
code/
  scripts/                          orchestration, monitoring and analysis scripts written for the study
  scripts/scale105/                 the exact run scripts of the final campaigns (md5 recorded in the log)
  patches/                          diffs against the paper's pipeline (CatenaD4J) and harness (TBarAPI)
  tbar_patched_sources*/            the patched TBar/TBarAPI sources (recursion guards, underscore parsing)
results/
  data/                             machine-readable result tables (CSV, verdict files, judgments)
  raw-evidence/                     unaltered run outputs pulled from the compute host (see "Provenance")
```

## 1. Setup

### Requirements

For the data analysis (Section 5): any operating system with Python 3.8 or newer. No
other software, no compilation, no network access. Tested on macOS 26.5 with Python 3.9.6; the script uses only the
standard library, so any Python 3.8+ works.

For re-running the experiments (Sections 3 and 4): a Linux host with rootless Podman or
Docker; Defects4J 2.0.0; growingBugs at commit `f198b74`
(https://github.com/liuhuigmail/GrowingBugRepository); CatenaD4J / IBugFinder and TBarAPI
from the subject paper's artifact (TBarAPI at `eed31ef`); the Hercules reimplementation at
`eedd7e1` (https://github.com/give-to/Hercules); GZoltar 1.6.0 (bundled in TBarAPI);
JDK 1.8.0_452; Python 3.8.10 in the containers. The study ran on the LMU host `sm06`
(2 x AMD EPYC 7713, 128 cores, about 2 TB RAM, Ubuntu 24.04, containers capped at 32 CPUs,
JVMs at `ActiveProcessorCount=5`). Budgets are the paper's: isolation 1 h per bug, at most
2048 partial programs, 900 s per test run; repair 5 h per bug and technique.

### Installation

None for Section 5. Clone the repository and enter the directory:

```
git clone https://github.com/BuddyOrbitFlover/thesisArtifact.git
cd thesisArtifact
```

For Sections 3 and 4, set up the benchmark, the containers and the tools as described
in the thesis (chapter 3); `code/patches/*.diff` and
`code/tbar_patched_sources*/` are the changes to apply to the paper's tools.

### First run

To check that everything works as expected, run:

```
python3 reproduce.py check
```

The script should output the following (only timings may differ):

```
   [ok] results/data/growingbugs_divisibility_results.csv
   [ok] results/data/gb_rerun/rerun_divisibility_results.csv
   [ok] results/data/gb_rerun/census_b/censusb_verdict.txt
   [ok] results/data/gb_rerun/census_b/tinyb_verdict.txt
   [ok] results/data/gb_rerun/census_b/rq2_final_judgments.csv
   [ok] results/raw-evidence/d4j/RESULTS_rem/done
   [ok] results/raw-evidence/gb/RESULTS_GB/fixed/Jfreesvg_1_1
   [ok] results/raw-evidence/scale105/census/rq2c_results.tgz
   [ok] results/raw-evidence/scale105/hercules/herc_d4j_pull.tgz
   [ok] results/raw-evidence/scale105/sm06_pull_20260813/evidence_pull_20260813.tgz
   [ok] LICENSE
   [ok] README.md
   headline: RQ1 150/77/22 of 249 (60.2 % divisible among all, 66.1 % among determined); RQ2 TBar 12/97 plausible, Hercules 6/97; Hercules D4J 21/105
   expected (thesis): RQ1 150/77/22, TBar 12, Hercules 6, Hercules D4J 21 -> MATCH
CHECK PASSED
```

`python3 reproduce.py verify` additionally checks every file of the bundle against
`SHA256SUMS` and ends with `1907 files checked, 0 mismatches -> OK`.

## 2. Example task

The example is one of the two correct TBar patches of the study, for the isolated bug
`Jfreesvg_1_1` (a bug isolated from growingBugs bug `Jfreesvg_1`). Its raw run output is in
`results/raw-evidence/gb/RESULTS_GB/`: the completion marker `done/Jfreesvg_1_1` and the
patch `fixed/Jfreesvg_1_1/NullPointerChecker_FixedBugs/Patch_194_76.txt`, which is
identical to the developer patch.

Run, from the command line:

```
python3 reproduce.py plausible
```

This lists every isolated bug with a plausible patch, per technique, with the run it came
from, the number of passing Hercules candidates, and the correctness judgment recorded in
`results/data/gb_rerun/census_b/rq2_final_judgments.csv`. The first line of the output is
the example:

```
   TBar     Jfreesvg_1_1                 pilot      Hercules passers: 0   judgment: correct (identical to the developer patch)
```

To see how such a verdict is produced from a raw growingBugs bug (isolation, isolation
check, fault localization, repair, judgment), see the protocol in the thesis
(chapter 3); the scripts are in `code/scripts/`. The expected outputs of the
example are the files of `results/raw-evidence/gb/` for the five pilot isolated bugs.

## 3. Running the exemplary benchmark set

Running the experiments takes a vast amount of time (the full study consumed several
weeks of wall-clock time on a 128-core host; upper bound per bug and technique: 1 h for
isolation plus 5 h for repair), so this is not expected to be the primary use of this
artifact. The study's own produced data are in `results/raw-evidence/` and are used by the
analysis of Section 5.

The exemplary benchmark set is the pilot: 10 growingBugs projects with 26 bugs, listed in
`results/raw-evidence/gb/stage5/2toMore` (multi-hunk bugs) and in Table 3.1 of the
thesis. To run it, set up the tools as in
Section 1 and run the pipeline stages with that bug list; the divisibility
stage takes about one day on 8 cores, the repair stage up to 5 h per isolated bug.

The expected outcome is the pilot part of the RQ1 and RQ2 outputs in Section 5:
9 divisible / 1 indivisible / 4 unknown multi-hunk bugs, 5 isolated indivisible multi-hunk
bugs run, TBar plausible for `Jfreesvg_1_1` (see the lines `pilot` in the logs of
`reproduce.py rq1` and `reproduce.py rq2` in "Full Logs").

## 4. Running experiments

Reproducing all experiments requires a Linux host with the tools of Section 1; the study
used 32 CPUs per container and up to 4 repair workers in parallel, each JVM limited to
5 processors and 1 GB heap. Caution: running all experiments takes several weeks.

### Executing benchmarks

The campaign scripts are in `code/scripts/scale105/` (`s5_pipeline.sh` for isolation,
`fl_s5.sh` for fault localization, `rq2_tbar4.sh` and `rq2_herc.sh`, `herc_gb4.sh` for
repair), the earlier pilot and pre-registered-run scripts in `code/scripts/` (`rq2_fl.sh`,
`rq2_tbar.sh`, `run_worker*.sh`), and the bug lists inside
`results/raw-evidence/scale105/sm06_pull_20260813/evidence_pull_20260813.tgz`
(`catena/*_bugs.txt`). Each script prints, per bug, a completion marker
(`done/<bug>`) and leaves its outputs in the `RESULTS_*` layout that `reproduce.py` reads,
so a re-run can be analyzed with the commands of Section 5 by pointing the paths at the
top of `reproduce.py` to the new results.

At the end of a repair campaign the marker directory holds one file per bug; for the final
97-bug set the expected state is `done` = 97 for TBar and 97 result files for Hercules,
as counted in the log of `reproduce.py rq2`.

## 5. Analysis of experimental data

The study's own produced data are in `results/raw-evidence/` (raw) and `results/data/`
(derived tables); `reproduce.py` reads the raw files wherever they exist and the derived
tables only where the raw files did not survive on the host (noted in the output).

Run `python3 reproduce.py all` to recompute every table and number of the thesis. The
commands below run the parts individually; the expected outputs are in "Full Logs".

| Thesis element | Command | Expected result |
|---|---|---|
| Table "Divisibility reproduction vs. the paper's Table 1" (RQ0, Part 1) | `python3 reproduce.py rq0-div` | All: this study 142/116/108/144/21, paper 139/118/105/144/24; divisible among all 142/281 = 50.5 % vs 139/281 = 49.5 %; Time recounted from the surviving raw CSV 11/7/14/7/1 |
| Table "TBar repair reproduction over the full 105-bug set"; claim "19 of the paper's 20 plausibly repaired bugs, 3 correct patches identical to the developer patches" | `python3 reproduce.py rq0-repair` | TBar 4 + 7 + 11 = 22 bugs with a plausible patch; 19 of 20 reproduced; 3 correct |
| Claim "Hercules replication: 21/105, 18 of the paper's 19 matched" | `python3 reproduce.py rq0-repair`; per-bug record in `results/data/rq2_hercules/d4j_105_results.md` | 21 bugs |
| Table "Divisibility of multi-hunk bugs: 249 growingBugs-new bugs vs. 281 Defects4J bugs" (RQ1) | `python3 reproduce.py rq1` | 150 div / 77 indiv / 22 unknown; 150/249 = 60.2 % divisible among all (the paper's framing; paper 139/281 = 49.5 %); among determined bugs 150/227 = 66.1 %; determination 227/249 = 91.2 % |
| Same, recounted from the per-bug `newBugs.json` files instead of the verdict tables | `python3 reproduce.py rq1 --deep` | identical numbers |
| Claim "the divisible share rises with the number of hunks" (Section 4.2, discussed in 5.1) | `python3 reproduce.py rq1 --hunks` | 2 hunks 48/89 = 53.9 %, 3-4 hunks 49/78 = 62.8 %, 5+ hunks 53/60 = 88.3 % (227 determined bugs) |
| Table "Repair of isolated indivisible multi-hunk bugs on the identical 97" (RQ2) | `python3 reproduce.py rq2` | TBar 12/97 = 12.4 %, 2 correct; Hercules 6/97 = 6.2 %, 1 correct; overlap Tascalate pair + Woodstox_6_1 |
| Claims about individual plausible patches (Jfreesvg_1_1 and JacksonDatabind_135_2 correct for TBar, Validator_24_1 for Hercules; the others overfitting) | `python3 reproduce.py plausible` | 12 TBar and 6 Hercules bugs with their judgments |
| Claim "the four Validator_24_1 Hercules patches are semantically equivalent to the developer patch" (Section 4.3) | `python3 code/difftest_validator.py` | 0 disagreements on 300 000 inputs for each of the four patches; buggy vs. developer patch disagree on 3 |
| Table "Results at a glance" | `python3 reproduce.py summary` | the rows of the thesis table |
| Unknown-bug reasons (22 unknown RQ1 bugs: 13 generator timeouts, 6 test-run timeouts, 3 split-test compile failures) | `results/data/gb_rerun/census_b/*_verdict.txt` (note column), `results/raw-evidence/gb/stage5/exceptions/`, `results/raw-evidence/scale105/census/census_exceptions.tgz` | one EXCEPTION file per unknown bug with the traceback |
| The two further isolation runs of the repair set (26 and 63 multi-hunk bugs) | `results/data/gb_rerun/s5/s5_stage5_verdicts.csv`, `results/data/gb_rerun/s6/s6_stage5_verdicts.csv`; raw: `results/raw-evidence/scale105/sm06_pull_20260813/` (S5) and `results/raw-evidence/scale105/s6/` (S6, `RECOUNT.md`) | S5 8 div / 12 indiv / 1 single / 5 unknown; S6 21 / 15 / 27 |
| Tooling findings (chapter 3 adaptations, chapter 5) | `code/patches/*.diff`, `code/tbar_patched_sources*/` | each failure with its fix and the diff |
| The individual patches behind every plausible count | `results/raw-evidence/*/RESULTS_*/fixed/<bug>/` (TBar) and `results/raw-evidence/scale105/hercules/*.tgz` (`RESULTS_HERC*/patches`, `results/<bug>.txt`) | patch files; `:Pass` lines mark plausible Hercules patches |
| LaTeX macros with the headline numbers | `python3 reproduce.py tex` | writes `generated/numbers.tex` |

How the counts are defined (as in the thesis, section 3.8): a growingBugs bug is divisible
when its `newBugs.json` holds a proper sub-pattern of its hunks, indivisible when only the
all-ones pattern remains, unknown when the run ended without the file; the divisibility rate
is divisible / all multi-hunk bugs (the paper's framing), reported alongside divisible /
determined and the determination rate. A TBar isolated bug is plausibly repaired when its
`fixed/<bug>/` directory holds at least one patch in a `*_FixedBugs` folder
(`*_PartiallyFixedBugs` patches are not plausible); a Hercules isolated bug is plausibly
repaired when its `results/<bug>.txt` contains at least one `:Pass` line. A patch is correct
when it is identical or semantically equivalent to the developer patch; the judgments are in
`results/data/gb_rerun/census_b/rq2_final_judgments.csv`; the thesis appendix gives a one-line reason per judgment.

The output of `reproduce.py rq1` lists the four steps in which the population was
assembled (pilot, pre-registered run, census, small projects) before the total; the thesis
reports the total only, the per-step lines are provenance.

### Provenance of the raw evidence

`results/raw-evidence/` is the study's evidence collection at commit `f34d356` of the
author's internal evidence repository, pulled from the host in passes on 2026-07-06, 2026-07-14, 2026-07-24 (pilot, RQ1 re-run,
RQ2 re-run; `d4j/`, `gb/`, `gb_rerun/`, `supplement/`), 2026-08-13 to 2026-08-15 (`scale105/`:
the census TBar run, all Hercules runs, the GB4 and GB5 runs, and a 1 282-file host pull
with every stage output, fault-localization ranking and run script), and 2026-08-28
(`scale105/s6/`: the S6 isolation run). The census and small-project verdict tables in
`results/data/` were amended on 2026-08-27 with the verdicts of the 13 bugs re-run on
2026-08-06; `reproduce.py rq1 --deep` recounts
them from the per-bug files.

Known gap: the Defects4J divisibility statistics CSVs of five projects were deleted by
the paper artifact's `clean.sh` after they had been recorded; `RQ0_DIV_RECORD` in
`reproduce.py` is the record, and the surviving Time CSV matches its row.

## Full Logs

This section contains the full log output for each of the commands named above, as run on
2026-09-01 on the final bundle.

- `python3 reproduce.py check`
```
   [ok] results/data/growingbugs_divisibility_results.csv
   [ok] results/data/gb_rerun/rerun_divisibility_results.csv
   [ok] results/data/gb_rerun/census_b/censusb_verdict.txt
   [ok] results/data/gb_rerun/census_b/tinyb_verdict.txt
   [ok] results/data/gb_rerun/census_b/rq2_final_judgments.csv
   [ok] results/raw-evidence/d4j/RESULTS_rem/done
   [ok] results/raw-evidence/gb/RESULTS_GB/fixed/Jfreesvg_1_1
   [ok] results/raw-evidence/scale105/census/rq2c_results.tgz
   [ok] results/raw-evidence/scale105/hercules/herc_d4j_pull.tgz
   [ok] results/raw-evidence/scale105/sm06_pull_20260813/evidence_pull_20260813.tgz
   [ok] LICENSE
   [ok] README.md
   headline: RQ1 150/77/22 of 249 (60.2 % divisible among all, 66.1 % among determined); RQ2 TBar 12/97 plausible, Hercules 6/97; Hercules D4J 21/105
   expected (thesis): RQ1 150/77/22, TBar 12, Hercules 6, Hercules D4J 21 -> MATCH
CHECK PASSED
```

- `python3 reproduce.py rq0-div`
```
== RQ0, Part 1: divisibility on Defects4J (281 multi-hunk bugs). Div/InDiv/Iso/Single/Ukn
   Record: RQ0_DIV_RECORD in this script (the paper artifact's clean.sh wiped the on-host CSVs; only Time is recounted raw).
   Chart    this study 10/3/7/22/0        paper 10/3/7/22/0
   Closure  this study 53/48/42/38/12     paper 52/48/41/38/13
   Lang     this study 22/17/19/20/1      paper 22/17/20/20/1
   Math     this study 40/25/23/38/4      paper 38/26/20/38/6
   Mockito  this study 6/16/3/19/3        paper 5/17/2/19/3
   Time     this study 11/7/14/7/1        paper 12/7/15/7/1
   All      this study 142/116/108/144/21 paper 139/118/105/144/24
   Time recounted from statstics2_Time.csv: 11/7/14/7/1  (record 11/7/14/7/1)
   divisible / all (the paper's framing): this study 142/281 = 50.5 %, paper 139/281 = 49.5 %
   divisible / determined:               this study 142/258 = 55.0 %, paper 139/257 = 54.1 %
```

- `python3 reproduce.py rq0-repair`
```
== RQ0, Part 2: repair on the paper's 105 isolated indivisible multi-hunk bugs
   TBar 1 h pass (44 bugs): done 44, plausible 4 ['Chart_18_2', 'Chart_22_4', 'Chart_25_3', 'Chart_2_5']
   TBar 5 h pass (40 bugs): done 40, plausible 7 ['Math_12_1', 'Math_18_1', 'Math_28_1', 'Math_28_2', 'Math_28_3', 'Time_12_1', 'Time_12_3']
   TBar Closure+Lang 5 h (61 bugs): done 61, plausible 11 ['Closure_106_2', 'Closure_138_1', 'Closure_141_2', 'Closure_22_1', 'Closure_84_1', 'Lang_30_1', 'Lang_41_1', 'Lang_41_2', 'Lang_41_3', 'Lang_50_1', 'Lang_50_2']
   TBar total: 22/105 bugs with a plausible patch (paper 20); 19 of the paper's 20 reproduced; correct 3 (paper 4), all identical to the published patches
   Hercules: done 105/105, bugs with a passing patch 21 (paper 19); 18 of the paper's 19 matched; correct: Chart_18_2 identical, Closure_6_2 validation-censored
```

- `python3 reproduce.py rq1`
```
== RQ1: divisibility on growingBugs-new multi-hunk bugs
   pilot                9 div /   1 indiv /   4 unknown   determined 90.0 %
   re-run (47 fresh)   18 div /   9 indiv /   4 unknown   determined 66.7 %
   census (171)        99 div /  60 indiv /  12 unknown   determined 62.3 %
   breadth (33)        24 div /   7 indiv /   2 unknown   determined 77.4 %
   TOTAL              150 div /  77 indiv /  22 unknown   of 249 bugs
   divisible / all         150/249 = 60.2 %   (paper 139/281 = 49.5 %; the paper's framing, primary)
   divisible / determined  150/227 = 66.1 %   (paper 139/257 = 54.1 %)
   determination rate      227/249 = 91.2 %   (paper 257/281 = 91.5 %)
```

- `python3 reproduce.py rq1 --deep`
```
== RQ1: divisibility on growingBugs-new multi-hunk bugs (deep recount from newBugs.json)
   pilot                9 div /   1 indiv /   4 unknown   determined 90.0 %
   re-run (47 fresh)   18 div /   9 indiv /   4 unknown   determined 66.7 %
   census (171)        99 div /  60 indiv /  12 unknown   determined 62.3 %
   breadth (33)        24 div /   7 indiv /   2 unknown   determined 77.4 %
   TOTAL              150 div /  77 indiv /  22 unknown   of 249 bugs
   divisible / all         150/249 = 60.2 %   (paper 139/281 = 49.5 %; the paper's framing, primary)
   divisible / determined  150/227 = 66.1 %   (paper 139/257 = 54.1 %)
   determination rate      227/249 = 91.2 %   (paper 257/281 = 91.5 %)
```

- `python3 reproduce.py rq2`
```
== RQ2: repair on the 97 growingBugs-new isolated indivisible multi-hunk bugs
   TBar pilot    run  5  plausible  1  ['Jfreesvg_1_1']
   TBar re-run   run 14  plausible  1  ['Woodstox_6_1']
   TBar census   run 58  plausible  7  ['Dagger_core_13_1', 'Jcabi_aether_1_1', 'Jcabi_aether_1_2', 'Spring_context_support_2_1', 'Tascalate_concurrent_1_1', 'Tascalate_concurrent_2_1', 'Zip4j_29_1']
   TBar GB4      run 15  plausible  1  ['Zip4j_47_1']
   TBar GB5      run  5  plausible  2  ['JacksonDatabind_126_1', 'JacksonDatabind_135_2']
   TBar total: 12/97 bugs with a plausible patch = 12.4 % (paper 20/105 = 19.0 %); correct 2 (Jfreesvg_1_1, JacksonDatabind_135_2) = 2.1 % (paper 4/105 = 3.8 %)
   Hercules gb-77  done 77  plausible 6  {'Tascalate_concurrent_1_1': 1, 'Validator_24_1': 4, 'Woodstox_6_1': 47, 'Zip4j_32_2': 8, 'Zip4j_32_1': 8, 'Tascalate_concurrent_2_1': 2}
   Hercules GB4    done 15  plausible 0  {}
   Hercules GB5    done  5  plausible 0  {}
   Hercules total: 6/97 = 6.2 % (paper 19/105 = 18.1 %); correct 1 (Validator_24_1); 29955 candidate-patch result lines
   overlap: ['Tascalate_concurrent_1_1', 'Tascalate_concurrent_2_1', 'Woodstox_6_1']; TBar only 9, Hercules only 3
```

- `python3 reproduce.py summary`
```
== Results at a glance
                          paper (D4J)      reproduction     growingBugs-new
   RQ0 divisibility       139/118/105      142/116/108      -
   RQ0 TBar plaus/corr    20 / 4           22 / 3           -
   RQ1 divisible/all      49.5 %           50.5 %           150/249 = 60.2 %
   RQ1 divisible/determined 54.1 %           55.0 %           150/227 = 66.1 %
   RQ2 TBar               19.0 % / 3.8 %   19/20 reproduced 12/97 = 12.4 % / 2/97 = 2.1 %
   RQ2 Hercules           18.1 % / 1.9 %   21/105 plausible 6/97 = 6.2 % / 1/97 = 1.0 %
```

- `python3 reproduce.py plausible`
```
== Plausible isolated bugs on growingBugs-new (judgment: data/gb_rerun/census_b/rq2_final_judgments.csv)
   TBar     Jfreesvg_1_1                 pilot      Hercules passers: 0   judgment: correct (identical to the developer patch)
   TBar     Woodstox_6_1                 re-run     Hercules passers: 47  judgment: overfitting
   TBar     Dagger_core_13_1             census     Hercules passers: 0   judgment: overfitting
   TBar     Jcabi_aether_1_1             census     Hercules passers: 0   judgment: overfitting
   TBar     Jcabi_aether_1_2             census     Hercules passers: 0   judgment: overfitting
   TBar     Spring_context_support_2_1   census     Hercules passers: 0   judgment: overfitting
   TBar     Tascalate_concurrent_1_1     census     Hercules passers: 1   judgment: overfitting
   TBar     Tascalate_concurrent_2_1     census     Hercules passers: 2   judgment: overfitting
   TBar     Zip4j_29_1                   census     Hercules passers: 0   judgment: overfitting
   TBar     Zip4j_47_1                   GB4        Hercules passers: 0   judgment: overfitting
   TBar     JacksonDatabind_126_1        GB5        Hercules passers: 0   judgment: overfitting
   TBar     JacksonDatabind_135_2        GB5        Hercules passers: 0   judgment: correct
   Hercules Validator_24_1               passers 4   judgment: correct (all four patches semantically equivalent to the developer patch)
   Hercules Zip4j_32_1                   passers 8   judgment: overfitting
   Hercules Zip4j_32_2                   passers 8   judgment: overfitting
```

- `python3 reproduce.py tex`
```
wrote generated/numbers.tex
% generated by reproduce.py tex; do not edit
\newcommand{\RqOneDiv}{150}
\newcommand{\RqOneIndiv}{77}
\newcommand{\RqOneUnknown}{22}
\newcommand{\RqOneN}{249}
\newcommand{\RqOneRate}{60.2\,\%}
\newcommand{\RqOneRateDetermined}{66.1\,\%}
\newcommand{\RqTwoTbarPlausible}{12}
\newcommand{\RqTwoHercPlausible}{6}
\newcommand{\RqTwoTbarRate}{12.4\,\%}
\newcommand{\RqTwoHercRate}{6.2\,\%}
```

- `python3 reproduce.py verify`
```
   1907 files checked, 0 mismatches -> OK
```

## Integrity

`SHA256SUMS` lists every file of the bundle; `python3 reproduce.py verify` checks them.
`make_archive.sh` regenerates the list.

## Publication

The artifact is published on GitHub: repository
https://github.com/BuddyOrbitFlover/thesisArtifact. To obtain it:
`git clone https://github.com/BuddyOrbitFlover/thesisArtifact.git`.
The thesis appendix names the release that corresponds to the submitted thesis (`v1.0`).

## Used Aids

During the preparation of this work, the author used Claude Code and Gemini to draft content and to improve writing style, sentence structure, wording, and grammar. Claude Code was additionally used, under the author's direction, to draft the pipeline scripts, the analysis script, the toolchain adaptations, and READMEs/MD files.
No AI tool executed an experiment or took a methodological decision. After using these tools, the author reviewed and edited all content as needed and takes full responsibility for the content of this thesis.

## License

Scripts written for this study (`code/scripts/**`, `reproduce.py`, `make_archive.sh`) are
licensed under the MIT License; documentation and result data (`README.md`,
`results/**`) under the Creative Commons Attribution 4.0 International
License; `code/patches/**` and `code/tbar_patched_sources*/**` are modifications of the
subject paper's tools and remain under their upstream licenses. Copyright 2026 Kanghyun Lee.
The full text is in `LICENSE`.
