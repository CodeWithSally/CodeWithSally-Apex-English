#!/usr/bin/env python3
"""Split images/package-dependency-map.svg into click-by-click layers for slide 9.

Each layer keeps the full 1600x900 canvas, so the layers stack exactly.
Layer N is shown on click N (8 is everything not listed) in the HTML deck. The PDF shows every layer.
Line numbers refer to package-dependency-map.svg; re-run after editing it.
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
IMAGES = os.path.join(HERE, '..', '..', 'images')
SRC = os.path.join(IMAGES, 'package-dependency-map.svg')
OUT = os.path.join(IMAGES, 'map-build')

def r(a, b):
    return list(range(a, b + 1))

STEPS = {
    0: r(157, 167),                                   # Legend
    1: r(68, 69) + [77, 85],                          # Framework boundary + fflib Apex Common
    2: r(28, 47),                                     # Business layer
    3: r(92, 93) + r(97, 98) + r(103, 104),           # Third-party managed packages
    4: r(50, 51) + [53, 54, 59, 60, 132, 139] + r(144, 147),  # Common boundary + two Project Commons
    5: [56, 62, 63, 148],                             # Org-wide Common
    6: [57, 64, 65, 149],                             # Universal Common
    7: [70, 71, 73, 74, 75, 76, 78, 79, 81, 82, 83, 84, 86, 87, 152, 153, 154],  # Rest of Framework
    9: [24, 25, 131],                                 # Remaining Happy Soup, last
}

lines = open(SRC, encoding='utf-8').read().split('\n')
head_end = next(i for i, l in enumerate(lines) if '</style>' in l)
header = lines[:head_end + 1]
body_start, body_end = head_end + 1, len(lines) - 2  # last real line is </svg>

assigned = {n for v in STEPS.values() for n in v}
STEPS[8] = []
stack, parents = [], {}
for idx in range(body_start, body_end + 1):
    n, line = idx + 1, lines[idx]
    s = line.strip()
    if re.match(r'<g\b', s) and not s.endswith('/>') and '</g>' not in s:
        stack.append(s)
        continue
    if s == '</g>':
        stack.pop()
        continue
    if not s or s.startswith('<!--') or s.startswith('</svg'):
        continue
    parents[n] = list(stack)
    if n not in assigned:
        STEPS[8].append(n)

os.makedirs(OUT, exist_ok=True)
for step, nums in sorted(STEPS.items()):
    out = list(header)
    out[0] = out[0].replace('role="img" aria-labelledby="pdm-title"', 'aria-hidden="true"')
    out = [l for l in out if '<title' not in l]
    for n in sorted(nums):
        if n not in parents:  # group wrappers, blanks and comments
            continue
        groups = parents.get(n, [])
        out.append(''.join(groups) + lines[n - 1].strip() + '</g>' * len(groups))
    out.append('</svg>')
    with open(os.path.join(OUT, f'pdm-step{step}.svg'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(out) + '\n')
    print(step, sum(1 for n in nums if n in parents))
