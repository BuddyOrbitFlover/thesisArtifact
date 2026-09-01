import os, subprocess, sys, time
props = ['classes.modified', 'classes.relevant', 'cp.compile', 'cp.test',
         'dir.bin.classes', 'dir.bin.tests', 'dir.src.classes', 'dir.src.tests',
         'tests.all', 'tests.relevant', 'tests.trigger']
with open(sys.argv[1]) as f:
    waitlist = [l.split(':')[0] for l in f.read().splitlines() if l.strip()]
workroot = sys.argv[2].rstrip('/')
fails = open('./export_failures.txt', 'a')
def export_prop(path, prop):
    r = None
    for attempt in (1, 2):
        r = subprocess.run(['defects4j', 'export', '-p', prop, '-w', path],
                           capture_output=True, text=True)
        if r.returncode == 0:
            return r.stdout
        time.sleep(3)
    fails.write('%s %s rc=%s\n%s\n---\n' % (path, prop, r.returncode, r.stderr[-500:]))
    fails.flush()
    return None
for bug in waitlist:
    d = './d4j_export/%s' % bug
    os.makedirs(d, exist_ok=True)
    for prop in props:
        fp = '%s/%s' % (d, prop)
        if os.path.exists(fp) and os.path.getsize(fp) > 0:
            continue  # resume: already exported
        res = export_prop('%s/%s' % (workroot, bug), prop)
        if res is None:
            print('FAIL %s %s' % (bug, prop), flush=True)
            res = ''
        with open(fp, 'w') as f:
            f.write(res)
    print('%s done' % bug, flush=True)
print('EXPORT COMPLETE', flush=True)
