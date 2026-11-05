#!/usr/bin/env python3
"""Split a map SVG into click-by-click layers for a slide that builds.

Each layer keeps the full canvas, so the layers stack exactly. Layer N is
shown on click N in the HTML deck; the PDF shows every layer. Line numbers
refer to the master SVG, so re-run after editing a master and check them.

Slide 9:  images/package-dependency-map.svg -> images/map-build/pdm-step*.svg
Slide 12: images/meridian-packages.svg      -> images/map-build/mer-step*.svg
"""
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
IMAGES = os.path.join(HERE, '..', '..', 'images')
OUT = os.path.join(IMAGES, 'map-build')


def r(a, b):
    return list(range(a, b + 1))


MAPS = {
    'pdm': {
        'src': 'package-dependency-map.svg',
        'rest': 8,  # this step gets every line not listed
        'steps': {
            0: r(157, 167),                                   # Legend
            1: r(68, 69) + [77, 85],                          # Framework boundary + fflib Apex Common
            2: r(28, 47),                                     # Business layer
            3: r(92, 93) + r(97, 98) + r(103, 104),           # Third-party managed packages
            4: r(50, 51) + [53, 54, 59, 60, 132, 139] + r(144, 147),  # Common boundary + two Project Commons
            5: [56, 62, 63, 148],                             # Org-wide Common
            6: [57, 64, 65, 149],                             # Universal Common
            7: [70, 71, 73, 74, 75, 76, 78, 79, 81, 82, 83, 84, 86, 87, 152, 153, 154],  # Rest of Framework
            9: [24, 25, 131],                                 # Remaining Happy Soup, last
        },
    },
    'mer': {
        'src': 'meridian-packages.svg',
        'rest': 0,  # nothing should be left over; title only on click 0
        'steps': {
            1: r(21, 26) + [31, 32, 38, 39],                  # Business boundary, warehouse project, fulfillment, maintenance
            2: r(43, 47) + [49, 50, 98, 99],                  # Project Common + warehouse-common
            3: [28, 29, 30, 35, 36, 37],                      # Rest of Business: sales, service, marketing
            4: r(54, 57) + r(59, 61) + [95, 96, 97, 100],     # Org-wide Common
            5: [83, 84, 86, 87, 90, 91, 102, 103],            # Integration API
            6: r(65, 68) + r(70, 73) + r(76, 79) + [101],     # Framework
        },
    },
}


def split(prefix, cfg):
    lines = open(os.path.join(IMAGES, cfg['src']), encoding='utf-8').read().split('\n')
    head_end = next(i for i, l in enumerate(lines) if '</style>' in l)
    header = [l for l in lines[:head_end + 1] if '<title' not in l]
    header[0] = re.sub(r'role="img" aria-labelledby="[^"]*"', 'aria-hidden="true"', header[0])

    steps = {k: list(v) for k, v in cfg['steps'].items()}
    assigned = {n for v in steps.values() for n in v}
    steps.setdefault(cfg['rest'], [])
    stack, parents = [], {}
    for idx in range(head_end + 1, len(lines)):
        n, s = idx + 1, lines[idx].strip()
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
            steps[cfg['rest']].append(n)

    os.makedirs(OUT, exist_ok=True)
    for step, nums in sorted(steps.items()):
        out = list(header)
        for n in sorted(nums):
            if n not in parents:  # group wrappers, blanks and comments
                continue
            groups = parents[n]
            out.append(''.join(groups) + lines[n - 1].strip() + '</g>' * len(groups))
        out.append('</svg>')
        with open(os.path.join(OUT, f'{prefix}-step{step}.svg'), 'w', encoding='utf-8') as f:
            f.write('\n'.join(out) + '\n')
        print(prefix, step, sum(1 for n in nums if n in parents))


for prefix, cfg in MAPS.items():
    split(prefix, cfg)
