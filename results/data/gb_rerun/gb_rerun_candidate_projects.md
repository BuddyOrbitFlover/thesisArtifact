# growingBugs re-run — candidate project frame (clean-design)

Purpose: a **pre-registered, ecosystem-stratified, per-project-capped** candidate frame for
re-running the external-validity experiment on growingBugs-new, replacing the pilot's
convenience sample. Counts are the **non-Defects4J unique bugs** taken verbatim from
`clean/GrowingBugRepository/NewBugs.md`.

Design rules:
- Breadth over depth (many projects, few bugs each).
- **Cap ≤ 4 bugs per project** (drawn by seeded random sample) → kills pseudo-replication.
- No ecosystem stratum dominates; deliberately more diverse than Defects4J itself.
- `Jcabi_github` (81), `Zip4j` (52), `JacksonDatabind` (33) capped hard as single-codebase blocs.
- Retained pilot projects marked ★ (continuity with the completed pilot).

## Apache Commons
| Project | Bugs (avail.) | Sample @cap 4 |
|---|--:|--:|
| IO | 22 | 4 |
| Validator | 21 | 4 |
| Pool | 17 | 4 |
| Bcel ★ | 6 | 4 |
| Graph ★ | 5 | 4 |
| Compress | 4 | 4 |
| Collections | 4 | 4 |
| Text ★ | 4 | 4 |
| **subtotal (8 projects)** | **83** | **32** |

## Apache (other)
| Project | Bugs | @cap 4 |
|---|--:|--:|
| Tika_core | 23 | 4 |
| Wicket_core | 18 | 4 |
| Johnzon_core | 11 | 4 |
| Shiro_core | 10 | 4 |
| Rdf4j_rio_turtle | 8 | 4 |
| **subtotal (5 projects)** | **70** | **20** |

## Jackson / FasterXML
| Project | Bugs | @cap 4 |
|---|--:|--:|
| JacksonDatabind (cap hard) | 33 | 4 |
| AaltoXml | 8 | 4 |
| Woodstox | 7 | 4 |
| JacksonCore | 4 | 4 |
| **subtotal (4 projects)** | **52** | **16** |

## jcabi  (excl. `Jcabi_github` 81 as a single-author outlier)
| Project | Bugs | @cap 4 |
|---|--:|--:|
| Jcabi_http | 16 | 4 |
| Jcabi_log | 9 | 4 |
| **subtotal (2 projects)** | **25** | **8** |

## Google
| Project | Bugs | @cap 4 |
|---|--:|--:|
| Gson | 25 | 4 |
| Dagger_core | 20 | 4 |
| Jimfs ★ | 2 | 2 |
| Google_java_format_core | 1 | 1 |
| **subtotal (4 projects)** | **48** | **11** |

## Independent / other
| Project | Bugs | @cap 4 |
|---|--:|--:|
| Zip4j (cap hard) | 52 | 4 |
| Spoon | 17 | 4 |
| Javapoet | 17 | 4 |
| Markedj | 17 | 4 |
| Tape | 13 | 4 |
| RTree | 12 | 4 |
| Proj4j | 9 | 4 |
| Streamex | 7 | 4 |
| Vectorz | 6 | 4 |
| Disklrucache | 6 | 4 |
| **subtotal (10 projects)** | **156** | **40** |

## Totals
- **Frame (uncapped): 33 projects, 434 bugs.**
- **Target sample (≤4/project): ~127 bugs → ~50–65 multi-hunk** (paper's ~40–50% multi-hunk fraction) — ≈5× the pilot's 14.
- Capped-sample ecosystem balance: Independent 31% · Commons 25% · Apache-other 16% · Jackson 13% · Google 9% · jcabi 6%.
- **RQ1 (divisibility):** run the pipeline on all sampled bugs.
- **RQ2 (repair):** census the resulting isolated indivisible multi-hunk set at 5h/bug; stays qualitative.

Caveats: bug counts are *total* per project — the multi-hunk n resolves only after Stage 2.
The specific ≤4 bugs per project must come from a **seeded random draw**, not hand-pick.
