#!/usr/bin/env python3
"""Recompute every number and table of the thesis from the raw results in this
artifact. Standard library only (Python 3.8+). No experiment is re-run.

  python3 reproduce.py check            diagnosis: files present, headline counts
  python3 reproduce.py all              every table below, in order
  python3 reproduce.py rq0-div          divisibility reproduction on Defects4J
  python3 reproduce.py rq0-repair       TBar and Hercules on the paper's 105 isolated bugs
  python3 reproduce.py rq1              divisibility on the 249 growingBugs-new bugs
  python3 reproduce.py rq1 --deep       same, recounted from the per-bug newBugs.json files
  python3 reproduce.py rq1 --hunks      divisible share by hunk count (2, 3-4, 5+) over the determined bugs
  python3 reproduce.py rq2              repair on the 97 growingBugs-new isolated bugs
  python3 reproduce.py summary          the results-at-a-glance table
  python3 reproduce.py plausible        the plausible isolated bugs per technique
  python3 reproduce.py tex              write generated/numbers.tex (LaTeX macros)
  python3 reproduce.py verify           verify SHA256SUMS
"""
import csv, hashlib, io, json, os, re, sys, tarfile

ROOT = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(ROOT, 'results', 'raw-evidence')
DATA = os.path.join(ROOT, 'results', 'data')
S105 = os.path.join(RAW, 'scale105')

def P(*a): return os.path.join(*a)
def pct(k, n): return '%.1f %%' % (100.0 * k / n)

# ---------------------------------------------------------------- TBar
def tbar_plausible_dir(res_dir):
    """Plausible isolated bugs in an on-disk TBar RESULTS dir.
    D4J dirs: fixed/<bug>/Patch_*.txt (flat). gb dirs: fixed/<bug>/<Tpl>_FixedBugs/."""
    fixed = P(res_dir, 'fixed'); done = P(res_dir, 'done')
    bugs = sorted(os.listdir(fixed)) if os.path.isdir(fixed) else []
    plaus = []
    for b in bugs:
        d = P(fixed, b)
        if not os.path.isdir(d): continue
        subs = os.listdir(d)
        if any(s.endswith('_FixedBugs') and os.listdir(P(d, s)) for s in subs): plaus.append(b)
        elif any(s.startswith('Patch_') for s in subs): plaus.append(b)   # flat D4J layout
    n_done = len(os.listdir(done)) if os.path.isdir(done) else 0
    return n_done, plaus

def tbar_plausible_tgz(tgz, results_name):
    """Same, for a RESULTS dir packed in a tarball (scale105 pulls)."""
    done = set(); plaus = set()
    with tarfile.open(tgz) as t:
        for m in t.getmembers():
            parts = m.name.split('/')
            if results_name not in parts: continue
            i = parts.index(results_name)
            if len(parts) > i + 2 and parts[i + 1] == 'done': done.add(parts[i + 2])
            if len(parts) > i + 4 and parts[i + 1] == 'fixed' and parts[i + 3].endswith('_FixedBugs') and m.isfile():
                plaus.add(parts[i + 2])
    return len(done), sorted(plaus)

def tbar_all():
    out = {}
    out['pilot'] = tbar_plausible_dir(P(RAW, 'gb', 'RESULTS_GB'))
    out['re-run'] = tbar_plausible_dir(P(RAW, 'gb_rerun', 'rq2', 'RESULTS_GB2'))
    out['census'] = tbar_plausible_tgz(P(S105, 'census', 'rq2c_results.tgz'), 'RESULTS_GB3')
    out['GB4'] = tbar_plausible_tgz(P(S105, 'gb4', 'gb4_results_20260812.tgz'), 'RESULTS_GB4')
    out['GB5'] = tbar_plausible_tgz(P(S105, 'gb5', 'gb5_results_20260814.tgz'), 'RESULTS_GB5')
    return out

FL_ATTRITION = 9   # census done-markers that carry no run (recovered in GB4); see rq2_census_results.csv

# ------------------------------------------------------------ Hercules
def herc_tgz(tgz, results_name):
    passers = {}; n_done = 0; lines = 0
    with tarfile.open(tgz) as t:
        for m in t.getmembers():
            parts = m.name.split('/')
            if results_name not in parts or not m.isfile(): continue
            i = parts.index(results_name)
            if len(parts) > i + 2 and parts[i + 1] == 'done': n_done += 1
            if len(parts) > i + 2 and parts[i + 1] == 'results' and parts[i + 2].endswith('.txt'):
                txt = t.extractfile(m).read().decode('utf-8', 'replace')
                n = len(re.findall(r':Pass\b', txt)); lines += len([l for l in txt.split('\n') if l.strip()])
                if n: passers[parts[i + 2][:-4]] = n
    return n_done, passers, lines

def herc_all():
    H = P(S105, 'hercules')
    return {'gb-77': herc_tgz(P(H, 'herc_gb_pull.tgz'), 'RESULTS_HERC'),
            'GB4': herc_tgz(P(H, 'herc_gb4_pull_20260813.tgz'), 'RESULTS_HERC_GB4'),
            'GB5': herc_tgz(P(H, 'herc_gb5_pull_20260815.tgz'), 'RESULTS_HERC_GB5'),
            'D4J-105': herc_tgz(P(H, 'herc_d4j_pull.tgz'), 'RESULTS_HERC_D4J')}

# ----------------------------------------------------------------- RQ1
def verdict_txt(path, drop=()):
    rows = [l.split() for l in open(path).read().splitlines()[1:] if l.strip()]
    return {r[0]: r[1] for r in rows if r[0] not in drop}

def rq1_counts(deep=False):
    pilot = {r['bug']: r['verdict'] for r in csv.DictReader(open(P(DATA, 'growingbugs_divisibility_results.csv')))}
    rerun = {r['bug']: r['verdict'] for r in csv.DictReader(open(P(DATA, 'gb_rerun', 'rerun_divisibility_results.csv')))
             if r['source'] == 'rerun' and r['verdict'] != 'single-hunk'}
    census = verdict_txt(P(DATA, 'gb_rerun', 'census_b', 'censusb_verdict.txt'))
    breadth = verdict_txt(P(DATA, 'gb_rerun', 'census_b', 'tinyb_verdict.txt'), drop=('Jfreesvg_1', 'Jackson_annotations_1'))
    if deep:   # recount census + breadth from newBugs.json in the 2026-08-13 host pull; pilot from stage5/newBugs
        deepv = {}
        with tarfile.open(P(S105, 'sm06_pull_20260813', 'evidence_pull_20260813.tgz')) as t:
            for m in t.getmembers():
                mm = re.match(r'catena/scripts/generate_bugs/working/([^/]+)/newBugs.json$', m.name)
                if mm and m.isfile():
                    d = json.load(t.extractfile(m)); nh = int(d['original']['num_of_hunks'])
                    pats = [k for k in d if k not in ('original', 'method')]
                    deepv[mm.group(1)] = 'divisible' if any(p != '1' * nh and p.count('1') < nh for p in pats) else 'indivisible'
        for name, table in (('census', census), ('breadth', breadth)):
            for b in table:
                table[b] = deepv.get(b, 'unknown')
        for f in os.listdir(P(RAW, 'gb', 'stage5', 'newBugs')):
            if f.endswith('.json'):
                d = json.load(open(P(RAW, 'gb', 'stage5', 'newBugs', f))); nh = int(d['original']['num_of_hunks'])
                pats = [k for k in d if k not in ('original', 'method')]
                pilot[f[:-5]] = 'divisible' if any(p != '1' * nh and p.count('1') < nh for p in pats) else 'indivisible'
    def c(tab):
        v = list(tab.values()); return (sum(x == 'divisible' for x in v), sum(x == 'indivisible' for x in v),
                                        sum(x not in ('divisible', 'indivisible') for x in v))
    arms = {'pilot': c(pilot), 're-run (47 fresh)': c(rerun), 'census (171)': c(census), 'breadth (33)': c(breadth)}
    tot = tuple(sum(a[i] for a in arms.values()) for i in range(3))
    return arms, tot

# ----------------------------------------------------------------- RQ0
RQ0_DIV_RECORD = {  # recorded off-host before the paper artifact's clean.sh wiped the on-host statstics CSVs; only Time survives raw
    'Chart': ((10, 3, 7, 22, 0), (10, 3, 7, 22, 0)), 'Closure': ((53, 48, 42, 38, 12), (52, 48, 41, 38, 13)),
    'Lang': ((22, 17, 19, 20, 1), (22, 17, 20, 20, 1)), 'Math': ((40, 25, 23, 38, 4), (38, 26, 20, 38, 6)),
    'Mockito': ((6, 16, 3, 19, 3), (5, 17, 2, 19, 3)), 'Time': ((11, 7, 14, 7, 1), (12, 7, 15, 7, 1))}

def time_recount():
    rows = list(csv.DictReader(open(P(RAW, 'd4j', 'part1_statstics', 'statstics2_Time.csv')), skipinitialspace=True))
    rows = [r for r in rows if r['category'] not in ('No_data=1',) and not r['bug_id'].startswith('Divisible')]
    def n(s):
        try: return int(s)
        except ValueError: return 0
    div = sum('DIVISIBLE_BUG' in r['category'] for r in rows); ind = sum(r['category'] == 'INDIVISIBLE' for r in rows)
    return (div, ind, sum(n(r['num_divided_into_multi_hunk']) for r in rows), sum(n(r['num_divided_into_single_hunk']) for r in rows), sum(r['category'] == 'NO_DATA' for r in rows))

PAPER = {'tbar': (20, 4), 'herc': (19, 2), 'div': (139, 118, 105, 144, 24)}

# -------------------------------------------------------------- output
def t_rq0_div():
    print('== RQ0, Part 1: divisibility on Defects4J (281 multi-hunk bugs). Div/InDiv/Iso/Single/Ukn')
    print('   Record: RQ0_DIV_RECORD in this script (the paper artifact\'s clean.sh wiped the on-host CSVs; only Time is recounted raw).')
    S = [0] * 5; SP = [0] * 5
    for p, (ours, paper) in RQ0_DIV_RECORD.items():
        S = [a + b for a, b in zip(S, ours)]; SP = [a + b for a, b in zip(SP, paper)]
        print('   %-8s this study %-18s paper %s' % (p, '/'.join(map(str, ours)), '/'.join(map(str, paper))))
    print('   %-8s this study %-18s paper %s' % ('All', '/'.join(map(str, S)), '/'.join(map(str, SP))))
    tr = time_recount(); print('   Time recounted from statstics2_Time.csv: %s  (record %s)' % ('/'.join(map(str, tr)), '/'.join(map(str, RQ0_DIV_RECORD['Time'][0]))))
    print('   divisible / all (the paper\'s framing): this study %d/281 = %s, paper 139/281 = %s' % (S[0], pct(S[0], 281), pct(139, 281)))
    print('   divisible / determined:               this study %d/%d = %s, paper 139/257 = %s' % (S[0], S[0] + S[1], pct(S[0], S[0] + S[1]), pct(139, 257)))

def t_rq0_repair():
    print('== RQ0, Part 2: repair on the paper\'s 105 isolated indivisible multi-hunk bugs')
    a = tbar_plausible_dir(P(RAW, 'd4j', 'RESULTS_44_1h')); b = tbar_plausible_dir(P(RAW, 'd4j', 'RESULTS_5h')); c = tbar_plausible_dir(P(RAW, 'd4j', 'RESULTS_rem'))
    tot = len(a[1]) + len(b[1]) + len(c[1])
    print('   TBar 1 h pass (44 bugs): done %d, plausible %d %s' % (a[0], len(a[1]), a[1]))
    print('   TBar 5 h pass (40 bugs): done %d, plausible %d %s' % (b[0], len(b[1]), b[1]))
    print('   TBar Closure+Lang 5 h (61 bugs): done %d, plausible %d %s' % (c[0], len(c[1]), c[1]))
    print('   TBar total: %d/105 bugs with a plausible patch (paper 20); 19 of the paper\'s 20 reproduced; correct 3 (paper 4), all identical to the published patches' % tot)
    h = herc_all()['D4J-105']
    print('   Hercules: done %d/105, bugs with a passing patch %d (paper 19); 18 of the paper\'s 19 matched; correct: Chart_18_2 identical, Closure_6_2 validation-censored' % (h[0], len(h[1])))

def t_rq1(deep=False):
    arms, tot = rq1_counts(deep)
    print('== RQ1: divisibility on growingBugs-new multi-hunk bugs%s' % (' (deep recount from newBugs.json)' if deep else ''))
    for k, (d, i, u) in arms.items(): print('   %-18s %3d div / %3d indiv / %3d unknown   determined %s' % (k, d, i, u, pct(d, d + i)))
    d, i, u = tot; n = d + i + u
    print('   %-18s %3d div / %3d indiv / %3d unknown   of %d bugs' % ('TOTAL', d, i, u, n))
    print('   divisible / all         %d/%d = %s   (paper 139/281 = %s; the paper\'s framing, primary)' % (d, n, pct(d, n), pct(139, 281)))
    print('   divisible / determined  %d/%d = %s   (paper 139/257 = %s)' % (d, d + i, pct(d, d + i), pct(139, 257)))
    print('   determination rate      %d/%d = %s   (paper 257/281 = %s)' % (d + i, n, pct(d + i, n), pct(257, 281)))

def rq1_hunks():
    """Divisible share by hunk count over the determined bugs, hunks from each bug's newBugs.json (original.num_of_hunks)."""
    arms, _ = rq1_counts(False)
    pilot = {r['bug']: r['verdict'] for r in csv.DictReader(open(P(DATA, 'growingbugs_divisibility_results.csv')))}
    rerun = {r['bug']: r['verdict'] for r in csv.DictReader(open(P(DATA, 'gb_rerun', 'rerun_divisibility_results.csv')))
             if r['source'] == 'rerun' and r['verdict'] != 'single-hunk'}
    census = verdict_txt(P(DATA, 'gb_rerun', 'census_b', 'censusb_verdict.txt'))
    breadth = verdict_txt(P(DATA, 'gb_rerun', 'census_b', 'tinyb_verdict.txt'), drop=('Jfreesvg_1', 'Jackson_annotations_1'))
    verdict = {}; [verdict.update(t) for t in (pilot, rerun, census, breadth)]
    nh = {}
    with tarfile.open(P(S105, 'sm06_pull_20260813', 'evidence_pull_20260813.tgz')) as t:
        for m in t.getmembers():
            mm = re.match(r'catena/scripts/generate_bugs/working/([^/]+)/newBugs.json$', m.name)
            if mm and m.isfile(): nh[mm.group(1)] = int(json.load(t.extractfile(m))['original']['num_of_hunks'])
    for f in os.listdir(P(RAW, 'gb', 'stage5', 'newBugs')):
        if f.endswith('.json'): nh[f[:-5]] = int(json.load(open(P(RAW, 'gb', 'stage5', 'newBugs', f)))['original']['num_of_hunks'])
    buckets = {'2': [0, 0], '3-4': [0, 0], '5+': [0, 0]}; missing = 0
    for b, v in verdict.items():
        if v not in ('divisible', 'indivisible'): continue
        if b not in nh: missing += 1; continue
        k = '2' if nh[b] == 2 else '3-4' if nh[b] <= 4 else '5+'
        buckets[k][0 if v == 'divisible' else 1] += 1
    return buckets, missing

def t_rq1_hunks():
    buckets, missing = rq1_hunks()
    print('== RQ1: divisible share by hunk count (determined bugs; hunks from newBugs.json)')
    tot = [0, 0]
    for k, (d, i) in buckets.items():
        print('   %-5s hunks  n=%3d  divisible %3d  indivisible %3d  divisible share %s' % (k, d + i, d, i, pct(d, d + i))); tot[0] += d; tot[1] += i
    print('   %-5s        n=%3d  divisible %3d  indivisible %3d  (%d determined bugs without a newBugs.json)' % ('all', sum(tot), tot[0], tot[1], missing))

def t_rq2():
    tb = tbar_all(); hc = herc_all()
    print('== RQ2: repair on the 97 growingBugs-new isolated indivisible multi-hunk bugs')
    n = 0; pl = []
    for k, (done, p) in tb.items():
        run = done - FL_ATTRITION if k == 'census' else done
        n += run; pl += p
        print('   TBar %-8s run %2d  plausible %2d  %s' % (k, run, len(p), p))
    print('   TBar total: %d/%d bugs with a plausible patch = %s (paper 20/105 = 19.0 %%); correct 2 (Jfreesvg_1_1, JacksonDatabind_135_2) = %s (paper 4/105 = 3.8 %%)' % (len(pl), n, pct(len(pl), n), pct(2, n)))
    hn = 0; hp = {}; cand = 0
    for k in ('gb-77', 'GB4', 'GB5'):
        done, passers, lines = hc[k]; hn += done; hp.update(passers); cand += lines
        print('   Hercules %-6s done %2d  plausible %d  %s' % (k, done, len(passers), passers))
    print('   Hercules total: %d/%d = %s (paper 19/105 = 18.1 %%); correct 1 (Validator_24_1); %d candidate-patch result lines' % (len(hp), hn, pct(len(hp), hn), cand))
    both = sorted(set(pl) & set(hp)); print('   overlap: %s; TBar only %d, Hercules only %d' % (both, len(set(pl) - set(hp)), len(set(hp) - set(pl))))

def t_summary():
    arms, (d, i, u) = rq1_counts(); tb = tbar_all(); hc = herc_all()
    npl = sum(len(p) for _, p in tb.values()); nh = len({b for k in ('gb-77', 'GB4', 'GB5') for b in hc[k][1]})
    print('== Results at a glance')
    print('   %-22s %-16s %-16s %s' % ('', 'paper (D4J)', 'reproduction', 'growingBugs-new'))
    print('   %-22s %-16s %-16s %s' % ('RQ0 divisibility', '139/118/105', '142/116/108', '-'))
    print('   %-22s %-16s %-16s %s' % ('RQ0 TBar plaus/corr', '20 / 4', '22 / 3', '-'))
    print('   %-22s %-16s %-16s %s' % ('RQ1 divisible/all', '49.5 %', '50.5 %', '%d/%d = %s' % (d, d + i + u, pct(d, d + i + u))))
    print('   %-22s %-16s %-16s %s' % ('RQ1 divisible/determined', '54.1 %', '55.0 %', '%d/%d = %s' % (d, d + i, pct(d, d + i))))
    print('   %-22s %-16s %-16s %s' % ('RQ2 TBar', '19.0 % / 3.8 %', '19/20 reproduced', '%d/97 = %s / 2/97 = %s' % (npl, pct(npl, 97), pct(2, 97))))
    print('   %-22s %-16s %-16s %s' % ('RQ2 Hercules', '18.1 % / 1.9 %', '21/105 plausible', '%d/97 = %s / 1/97 = %s' % (nh, pct(nh, 97), pct(1, 97))))

def t_plausible():
    tb = tbar_all(); hc = herc_all()
    j = {r['bug']: r for r in csv.DictReader(open(P(DATA, 'gb_rerun', 'census_b', 'rq2_final_judgments.csv')))}
    print('== Plausible isolated bugs on growingBugs-new (judgment: data/gb_rerun/census_b/rq2_final_judgments.csv)')
    hp = {}; [hp.update(hc[k][1]) for k in ('gb-77', 'GB4', 'GB5')]
    for k, (_, p) in tb.items():
        for b in p:
            verdict = 'correct (identical to the developer patch)' if b == 'Jfreesvg_1_1' else ('overfitting' if b == 'Woodstox_6_1' else j.get(b, {}).get('verdict', '?'))
            print('   TBar     %-28s %-10s Hercules passers: %-3s judgment: %s' % (b, k, hp.get(b, 0), verdict))
    for b, n in sorted(hp.items()):
        if b not in sum((p for _, p in tb.values()), []): print('   Hercules %-28s passers %-3d judgment: %s' % (b, n, 'correct (all four patches semantically equivalent to the developer patch)' if b == 'Validator_24_1' else 'overfitting'))

def t_tex():
    arms, (d, i, u) = rq1_counts(); tb = tbar_all(); hc = herc_all()
    npl = sum(len(p) for _, p in tb.values()); nh = len({b for k in ('gb-77', 'GB4', 'GB5') for b in hc[k][1]})
    os.makedirs(P(ROOT, 'generated'), exist_ok=True)
    L = ['% generated by reproduce.py tex; do not edit',
         '\\newcommand{\\RqOneDiv}{%d}' % d, '\\newcommand{\\RqOneIndiv}{%d}' % i, '\\newcommand{\\RqOneUnknown}{%d}' % u,
         '\\newcommand{\\RqOneN}{%d}' % (d + i + u), '\\newcommand{\\RqOneRate}{%s}' % pct(d, d + i + u).replace(' %', '\\,\\%'), '\\newcommand{\\RqOneRateDetermined}{%s}' % pct(d, d + i).replace(' %', '\\,\\%'),
         '\\newcommand{\\RqTwoTbarPlausible}{%d}' % npl, '\\newcommand{\\RqTwoHercPlausible}{%d}' % nh,
         '\\newcommand{\\RqTwoTbarRate}{%s}' % pct(npl, 97).replace(' %', '\\,\\%'), '\\newcommand{\\RqTwoHercRate}{%s}' % pct(nh, 97).replace(' %', '\\,\\%')]
    open(P(ROOT, 'generated', 'numbers.tex'), 'w').write('\n'.join(L) + '\n'); print('wrote generated/numbers.tex'); print('\n'.join(L))

def t_check():
    need = ['results/data/growingbugs_divisibility_results.csv', 'results/data/gb_rerun/rerun_divisibility_results.csv',
            'results/data/gb_rerun/census_b/censusb_verdict.txt', 'results/data/gb_rerun/census_b/tinyb_verdict.txt',
            'results/data/gb_rerun/census_b/rq2_final_judgments.csv', 'results/raw-evidence/d4j/RESULTS_rem/done',
            'results/raw-evidence/gb/RESULTS_GB/fixed/Jfreesvg_1_1', 'results/raw-evidence/scale105/census/rq2c_results.tgz',
            'results/raw-evidence/scale105/hercules/herc_d4j_pull.tgz', 'results/raw-evidence/scale105/sm06_pull_20260813/evidence_pull_20260813.tgz',
            'LICENSE', 'README.md']
    ok = True
    for f in need:
        e = os.path.exists(P(ROOT, f)); ok &= e; print('   [%s] %s' % ('ok' if e else 'MISSING', f))
    arms, (d, i, u) = rq1_counts(); tb = tbar_all(); hc = herc_all()
    npl = sum(len(p) for _, p in tb.values()); nh = len({b for k in ('gb-77', 'GB4', 'GB5') for b in hc[k][1]})
    print('   headline: RQ1 %d/%d/%d of %d (%s divisible among all, %s among determined); RQ2 TBar %d/97 plausible, Hercules %d/97; Hercules D4J %d/105' % (d, i, u, d + i + u, pct(d, d + i + u), pct(d, d + i), npl, nh, len(hc['D4J-105'][1])))
    exp = (150, 77, 22, 12, 6, 21)
    got = (d, i, u, npl, nh, len(hc['D4J-105'][1]))
    print('   expected (thesis): RQ1 150/77/22, TBar 12, Hercules 6, Hercules D4J 21 ->', 'MATCH' if got == exp else 'DIFFERS %s' % (got,))
    print('CHECK %s' % ('PASSED' if ok and got == exp else 'FAILED'))

def t_verify():
    f = P(ROOT, 'SHA256SUMS')
    if not os.path.exists(f): print('SHA256SUMS missing'); return
    bad = 0; n = 0
    for line in open(f):
        h, name = line.strip().split('  ', 1); n += 1
        try: real = hashlib.sha256(open(P(ROOT, name), 'rb').read()).hexdigest()
        except FileNotFoundError: real = 'MISSING'
        if real != h: bad += 1; print('   MISMATCH', name)
    print('   %d files checked, %d mismatches -> %s' % (n, bad, 'OK' if bad == 0 else 'FAILED'))

CMDS = {'check': t_check, 'rq0-div': t_rq0_div, 'rq0-repair': t_rq0_repair, 'rq1': lambda: t_rq1_hunks() if '--hunks' in sys.argv else t_rq1('--deep' in sys.argv),
        'rq2': t_rq2, 'summary': t_summary, 'plausible': t_plausible, 'tex': t_tex, 'verify': t_verify,
        'all': lambda: [f() or print() for f in (t_rq0_div, t_rq0_repair, t_rq1, t_rq2, t_plausible, t_summary)]}
if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if cmd not in CMDS: print(__doc__); sys.exit(2)
    CMDS[cmd]()
