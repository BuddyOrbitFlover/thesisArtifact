#!/usr/bin/env python3
"""Pre-registered seeded draw for the growingBugs re-run sample.

Frame: gb_rerun_candidate_projects.md (2026-07-09) — 33 projects, cap <=4 bugs/project.
Population: non-Defects4J unique bugs, verbatim from clean/GrowingBugRepository/NewBugs.md.

Draw procedure (pre-registered):
  SEED = 20260714 (date of the draw)
  For each project P (independently, order-invariant):
      ids = sorted available bug IDs of P from NewBugs.md
      if len(ids) <= 4: take all
      else: random.Random(f"{SEED}:{P}").sample(ids, 4), then sorted
Any count mismatch between NewBugs.md and the frame file is reported, never silently fixed.

DECISION 2026-07-14 (user, pre-results): the 5 Defects4J-v2.0-known frame projects are
EXCLUDED (project-level D4J independence, METHODOLOGY §4.1 criterion 1). Their draws are
still printed for the record but marked EXCLUDED and left out of totals and the
machine-readable list. Final sample at CAP=2: 28 projects / 55 bugs (see
gb_rerun_sample.md); the earlier cap-4 draw over the same 28 projects gave 107 bugs.
"""
import random
import re
import sys

SEED = 20260714
CAP = 2  # revised 4->2 on 2026-07-14 pre-results (user: smaller sample, keep breadth)
NEWBUGS = "clean/GrowingBugRepository/NewBugs.md"
EXCLUDED = {"Collections", "Compress", "Gson", "JacksonCore", "JacksonDatabind"}

# Frame (project -> expected available count), from gb_rerun_candidate_projects.md.
# Stratum order preserved for the report. ★ = retained pilot project (Part 1 already run).
FRAME = {
    "Apache Commons": [("IO", 22), ("Validator", 21), ("Pool", 17), ("Bcel", 6),
                       ("Graph", 5), ("Compress", 4), ("Collections", 4), ("Text", 4)],
    "Apache (other)": [("Tika_core", 23), ("Wicket_core", 18), ("Johnzon_core", 11),
                       ("Shiro_core", 10), ("Rdf4j_rio_turtle", 8)],
    "Jackson / FasterXML": [("JacksonDatabind", 33), ("AaltoXml", 8), ("Woodstox", 7),
                            ("JacksonCore", 4)],
    "jcabi": [("Jcabi_http", 16), ("Jcabi_log", 9)],
    "Google": [("Gson", 25), ("Dagger_core", 20), ("Jimfs", 2), ("Google_java_format_core", 1)],
    "Independent / other": [("Zip4j", 52), ("Spoon", 17), ("Javapoet", 17), ("Markedj", 17),
                            ("Tape", 13), ("RTree", 12), ("Proj4j", 9), ("Streamex", 7),
                            ("Vectorz", 6), ("Disklrucache", 6)],
}
PILOT = {"Bcel", "Graph", "Text", "Jimfs"}


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def expand(idspec):
    idspec = re.sub(r"</?br/?>", "", idspec).replace(" ", "")
    out = []
    for part in idspec.split(","):
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-")
            out.extend(range(int(a), int(b) + 1))
        else:
            out.append(int(part))
    return sorted(set(out))


def parse_newbugs(path):
    bugs = {}
    for line in open(path, encoding="utf-8"):
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 6 or not cells[0].isdigit():
            continue
        pid = re.sub(r"<br/?>", "", cells[1]).strip()
        try:
            ids = expand(cells[5])
        except ValueError:
            print(f"UNPARSEABLE ID CELL: {cells[1]!r}: {cells[5]!r}", file=sys.stderr)
            continue
        bugs[pid] = ids
    return bugs


def main():
    newbugs = parse_newbugs(NEWBUGS)
    lookup = {norm(k): (k, v) for k, v in newbugs.items()}
    total_avail = sum(len(v) for v in newbugs.values())
    print(f"NewBugs.md parsed: {len(newbugs)} projects, {total_avail} bugs "
          f"(document says 1109)\n")

    problems, grand_avail, grand_drawn = [], 0, 0
    all_drawn_bugids = []
    for stratum, projects in FRAME.items():
        print(f"## {stratum}")
        for name, expected in projects:
            hit = lookup.get(norm(name))
            if hit is None:
                problems.append(f"{name}: NOT FOUND in NewBugs.md")
                print(f"  {name:<24} NOT FOUND")
                continue
            pid, ids = hit
            if len(ids) != expected:
                problems.append(f"{name}: frame says {expected}, NewBugs.md has {len(ids)}")
            if len(ids) <= CAP:
                drawn = ids
            else:
                drawn = sorted(random.Random(f"{SEED}:{pid}").sample(ids, CAP))
            star = " ★" if name in PILOT else ""
            if name in EXCLUDED:
                print(f"  {pid:<24}   avail {len(ids):>2}  drawn {len(drawn)}: "
                      f"{','.join(map(str, drawn))}  [EXCLUDED 2026-07-14: D4J project]")
                continue
            grand_avail += len(ids)
            grand_drawn += len(drawn)
            all_drawn_bugids += [f"{pid}_{b}" for b in drawn]
            print(f"  {pid:<24}{star:<2} avail {len(ids):>2}  drawn {len(drawn)}: "
                  f"{','.join(map(str, drawn))}")
        print()

    print(f"TOTAL: {grand_avail} available, {grand_drawn} drawn "
          f"(seed {SEED}, cap {CAP}/project)")
    print(f"\n# Machine-readable draw ({len(all_drawn_bugids)} bugs):")
    for b in all_drawn_bugids:
        print(b)
    if problems:
        print("\n!! COUNT DISCREPANCIES (frame vs NewBugs.md) — resolve before running:")
        for p in problems:
            print(f"  - {p}")


if __name__ == "__main__":
    main()
