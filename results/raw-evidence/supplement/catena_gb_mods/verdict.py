import json, os
bugs = open('./2toMore').read().split()
print('%-26s %-14s %-10s %3s %5s' % ('bug', 'verdict', 'note', 'nh', 'pats'))
for b in bugs:
    nb = './working/%s/newBugs.json' % b
    exc = os.path.exists('./exceptions/EXCEPTION_%s' % b)
    if not os.path.exists(nb):
        print('%-26s %-14s %-10s' % (b, 'unknown', 'exception' if exc else 'no-output'))
        continue
    d = json.load(open(nb))
    nh = int(d['original']['num_of_hunks'])
    pats = [k for k in d if k not in ('original', 'method')]
    proper = [p for p in pats if p != '1' * nh and p.count('1') < nh]
    v = 'divisible' if proper else 'indivisible'
    print('%-26s %-14s %-10s %3d %5d' % (b, v, '+exc' if exc else '', nh, len(pats)))
