#!/usr/bin/env python3
"""Differential test: Hercules passers for Validator_24_1 vs the developer fix (commons-validator 1.5.1 buggy -> 1.6 fixed).
Faithful Python port of InetAddressValidator.isValidInet6Address / isValidInet4Address (Java semantics of split/parseInt reproduced)."""
import re, random, itertools, sys

IPV6_MAX_HEX_GROUPS = 8; IPV6_MAX_HEX_DIGITS_PER_GROUP = 4; MAX_UNSIGNED_SHORT = 0xffff; IPV4_MAX_OCTET_VALUE = 255
IPV4 = re.compile(r'^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$')
HEX = re.compile(r'^[+-]?[0-9a-fA-F]+$')

def java_split_colon(s):
    if ':' not in s: return [s]
    parts = s.split(':')
    while parts and parts[-1] == '': parts.pop()
    return parts

def java_parse_hex(s):  # Integer.parseInt(s, 16); raises ValueError like NumberFormatException
    if not HEX.match(s): raise ValueError
    v = int(s, 16)
    if v > 0x7fffffff or v < -0x80000000: raise ValueError
    return v

def java_parse_int(s):
    if not re.match(r'^[+-]?[0-9]+$', s): raise ValueError
    v = int(s)
    if v > 0x7fffffff or v < -0x80000000: raise ValueError
    return v

def is_valid_inet4(a):
    m = IPV4.match(a)
    if not m: return False
    for seg in m.groups():
        if seg is None or len(seg) == 0: return False
        try: v = java_parse_int(seg)
        except ValueError: return False
        if v > IPV4_MAX_OCTET_VALUE: return False
        if len(seg) > 1 and seg.startswith('0'): return False
    return True

def prelude(a):
    compressed = '::' in a
    if compressed and a.find('::') != a.rfind('::'): return None, None
    if (a.startswith(':') and not a.startswith('::')) or (a.endswith(':') and not a.endswith('::')): return None, None
    octets = java_split_colon(a)
    if compressed:
        if a.endswith('::'): octets = octets + ['']
        elif a.startswith('::') and octets: octets = octets[1:]
    if len(octets) > IPV6_MAX_HEX_GROUPS: return None, None
    return octets, compressed

def inet6_buggy(a, line167=None):
    """1.5.1 structure. line167 = predicate(index, n_octets, validOctets) replacing `index > octets.length-1 || index > 6`."""
    octets, compressed = prelude(a)
    if octets is None: return False
    valid = 0; empty = 0
    for index, octet in enumerate(octets):
        if len(octet) == 0:
            empty += 1
            if empty > 1: return False
        else:
            empty = 0
            if '.' in octet:
                if not a.endswith(octet): return False
                cond = (index > len(octets) - 1 or index > 6) if line167 is None else line167(index, len(octets), valid)
                if cond: return False
                if not is_valid_inet4(octet): return False
                valid += 2
                continue
            if len(octet) > IPV6_MAX_HEX_DIGITS_PER_GROUP: return False
            try: v = java_parse_hex(octet)
            except ValueError: return False
            if v < 0 or v > MAX_UNSIGNED_SHORT: return False
        valid += 1
    if valid < IPV6_MAX_HEX_GROUPS and not compressed: return False
    return True

def inet6_fixed(a):
    """1.6 = developer fix (H1: last-chunk-only IPv4 rule; H2: validOctets > 8 rejection)."""
    octets, compressed = prelude(a)
    if octets is None: return False
    valid = 0; empty = 0
    for index, octet in enumerate(octets):
        if len(octet) == 0:
            empty += 1
            if empty > 1: return False
        else:
            empty = 0
            if index == len(octets) - 1 and '.' in octet:
                if not is_valid_inet4(octet): return False
                valid += 2
                continue
            if len(octet) > IPV6_MAX_HEX_DIGITS_PER_GROUP: return False
            try: v = java_parse_hex(octet)
            except ValueError: return False
            if v < 0 or v > MAX_UNSIGNED_SHORT: return False
        valid += 1
    if valid > IPV6_MAX_HEX_GROUPS or (valid < IPV6_MAX_HEX_GROUPS and not compressed): return False
    return True

PATCHES = {
 'group_17/1':  lambda i, n, v: i != n - 1 or i > 6,
 'group_17/2':  lambda i, n, v: i < n - 1 or i > 6,
 'group_17/33': lambda i, n, v: i != v or (i > n - 1 or i > 6),
 'group_17/37': lambda i, n, v: i < v or (i > n - 1 or i > 6),
}

# --- inputs
trigger = ["0:0:0:0:0:0:13.1.68.3", "0:0:0:0:0:FFFF:129.144.52.38", "::13.1.68.3", "::FFFF:129.144.52.38",
           "::ffff:192.168.1.1:192.168.1.1", "::192.168.1.1:192.168.1.1"]
hand = ["1:2:3:4:5:6:7:1.2.3.4", "1:2:3:4:5:6::1.2.3.4", "::1:2:3:4:5:6:1.2.3.4", "1:2:3:4:5::1.2.3.4", "::1.2.3.4:1.2.3.4",
        "1.2.3.4::", "::", "::1", "1::", "1:2:3:4:5:6:7:8", "1:2:3:4:5:6:7:8:9", "1.2.3.4:1.2.3.4", "1:1.2.3.4:2", "::1.2.3.4",
        "1:2:3:4:5:6:1.2.3.4", "1:2:3:4:5:6:7:1.2.3.4:", "0:0:0:0:0:0:0:1.2.3.4", "::ffff:1.2.3.4:5", "1::2::1.2.3.4", "1.2.3.4",
        "1:2:3:4:5:6:1.2.3.4:", "12345::1.2.3.4", "::0x1", "::+1", "::-1", "::1.2.3.04", "::256.1.1.1"]
rnd = random.Random(20260825)
hexch = '0123456789abcdefABCDEF'
def rand_group():
    r = rnd.random()
    if r < 0.05: return ''
    if r < 0.15: return '.'.join(str(rnd.choice([0, 1, 9, 10, 99, 100, 255, 256, 999])) if rnd.random() < 0.9 else rnd.choice(['01', '00', 'a', '']) for _ in range(rnd.choice([3, 4, 4, 4, 5])))
    if r < 0.20: return rnd.choice(['g', '0x1', '+1', '-1', '12345', 'ffff0', ' 1', '1 ', '１'])
    return ''.join(rnd.choice(hexch) for _ in range(rnd.randint(1, 5)))
def rand_addr():
    k = rnd.randint(0, 10)
    groups = [rand_group() for _ in range(k)]
    s = ':'.join(groups)
    if rnd.random() < 0.5:  # insert a '::' somewhere
        pos = rnd.randint(0, len(s))
        s = s[:pos] + '::' + s[pos:]
    if rnd.random() < 0.1: s = ':' + s
    if rnd.random() < 0.1: s = s + ':'
    return s
inputs = set(trigger + hand)
while len(inputs) < 300000: inputs.add(rand_addr())
inputs = sorted(inputs)

print(f"inputs: {len(inputs)}")
print("trigger set  buggy/fixed:", [(a, inet6_buggy(a), inet6_fixed(a)) for a in trigger[-2:]])
bug_vs_fix = [a for a in inputs if inet6_buggy(a) != inet6_fixed(a)]
print(f"buggy vs fixed disagree on {len(bug_vs_fix)} inputs, e.g. {bug_vs_fix[:6]}")
for name, pred in PATCHES.items():
    dis = [a for a in inputs if inet6_buggy(a, pred) != inet6_fixed(a)]
    print(f"{name:12s} vs developer fix: {len(dis)} disagreements" + (f"  e.g. {dis[:8]}" if dis else "  (equivalent on all tested inputs)"))
    for a in dis[:8]:
        print(f"    {a!r}: patch={inet6_buggy(a, pred)} fixed={inet6_fixed(a)}")
