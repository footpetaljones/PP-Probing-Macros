#!/usr/bin/env python3
"""Scenario tests for the probing macros using tools/sim_macros.py.

  python3 tools/test_macros.py                 run scenarios on the working tree
  python3 tools/test_macros.py --compare REV   also run REV's macros and diff traces

Machine model: probe tip 0.100, positioning WCS 1 (G54) offset X10 Y5 Z-8,
measuring WCS 2 (G55) starts at X3 Y3 Z3 so a wrong update is obvious.
"""
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim_macros import (Interp, World, Wall, Slab, Box, Cylinder, Floor, GcodeError,  # noqa: E402
                        OVERTRAVEL, TIP_DIA)

POS = (10.0, 5.0, -8.0)          # G54 offset (machine)
FEEDS = {'_probe_rough_feed_per_min': 10.0, '_probe_fine_feed_per_min': 1.0,
         '_probe_rapid_feed_per_min': 50.0}
R = TIP_DIA / 2


def w(x, y, z):
    """machine coordinate -> positioning WCS coordinate"""
    return (x - POS[0], y - POS[1], z - POS[2])


def scenarios():
    s = []
    # name, macro, world, start(machine), params, expected {(wcs, axis): offset}
    s.append(('x_edge +X', 'probe_x_edge', World([Wall('X', 12.0, +1)]), (11.5, 6, -8.5),
              {'_first_position_to_probe': w(12.5, 0, 0)[0], '_measuring_wcs': 2, '_x_wcs_offset': 0.0},
              {(2, 'X'): 12.0}))
    s.append(('x_edge -X', 'probe_x_edge', World([Wall('X', 9.0, -1)]), (9.5, 6, -8.5),
              {'_first_position_to_probe': w(8.5, 0, 0)[0], '_measuring_wcs': 2, '_x_wcs_offset': 1.0},
              {(2, 'X'): 8.0}))
    s.append(('y_edge +Y', 'probe_y_edge', World([Wall('Y', 7.0, +1)]), (11, 6.5, -8.5),
              {'_first_position_to_probe': w(0, 7.5, 0)[1], '_measuring_wcs': 2, '_y_wcs_offset': 0.0},
              {(2, 'Y'): 7.0}))
    s.append(('y_edge -Y', 'probe_y_edge', World([Wall('Y', 4.0, -1)]), (11, 4.5, -8.5),
              {'_first_position_to_probe': w(0, 3.5, 0)[1], '_measuring_wcs': 2, '_y_wcs_offset': -2.0},
              {(2, 'Y'): 6.0}))
    s.append(('z', 'probe_z', World([Floor(-9.0)]), (11, 6, -8.6),
              {'_first_position_to_probe': w(0, 0, -9.5)[2], '_measuring_wcs': 2, '_z_wcs_offset': 0.0},
              {(2, 'Z'): -9.0}))
    s.append(('xy_corner outside', 'probe_xy_corner',
              World([Box(12.0, 20.0, 7.0, 20.0, ztop=-8.0)]), (11.5, 8.0, -8.5),
              {'_first_position_to_probe': w(12.5, 0, 0)[0], '_second_position_to_probe': w(0, 7.5, 0)[1],
               '_second_x_position': w(12.5, 0, 0)[0], '_second_y_position': w(0, 6.5, 0)[1],
               '_second_z_position': w(0, 0, -8.5)[2], '_z_clearance_position': w(0, 0, -7.5)[2],
               '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 7.0}))
    s.append(('x_pocket', 'probe_x_pocket', World([Slab('X', 11.0, 13.0, inverted=True)]), (11.5, 6, -8.5),
              {'_first_position_to_probe': w(10.5, 0, 0)[0], '_second_position_to_probe': w(13.5, 0, 0)[0],
               '_second_x_position': w(12.5, 0, 0)[0], '_second_y_position': w(0, 6, 0)[1],
               '_second_z_position': w(0, 0, -8.5)[2], '_z_clearance_position': w(0, 0, -7.5)[2],
               '_measuring_wcs': 2, '_x_wcs_offset': 0.0},
              {(2, 'X'): 12.0}))
    s.append(('y_pocket', 'probe_y_pocket', World([Slab('Y', 5.0, 7.0, inverted=True)]), (11, 5.5, -8.5),
              {'_first_position_to_probe': w(0, 4.5, 0)[1], '_second_position_to_probe': w(0, 7.5, 0)[1],
               '_second_x_position': w(11, 0, 0)[0], '_second_y_position': w(0, 6.5, 0)[1],
               '_second_z_position': w(0, 0, -8.5)[2], '_z_clearance_position': w(0, 0, -7.5)[2],
               '_measuring_wcs': 2, '_y_wcs_offset': 0.0},
              {(2, 'Y'): 6.0}))
    s.append(('x_boss', 'probe_x_boss', World([Slab('X', 11.0, 13.0, ztop=-8.0)]), (10.5, 6, -8.5),
              {'_first_position_to_probe': w(12.0, 0, 0)[0], '_second_position_to_probe': w(12.0, 0, 0)[0],
               '_second_x_position': w(13.5, 0, 0)[0], '_second_y_position': w(0, 6, 0)[1],
               '_second_z_position': w(0, 0, -8.5)[2], '_z_clearance_position': w(0, 0, -7.5)[2],
               '_measuring_wcs': 2, '_x_wcs_offset': 0.0},
              {(2, 'X'): 12.0}))
    s.append(('y_boss', 'probe_y_boss', World([Slab('Y', 5.0, 7.0, ztop=-8.0)]), (11, 4.5, -8.5),
              {'_first_position_to_probe': w(0, 6.0, 0)[1], '_second_position_to_probe': w(0, 6.0, 0)[1],
               '_second_x_position': w(11, 0, 0)[0], '_second_y_position': w(0, 7.5, 0)[1],
               '_second_z_position': w(0, 0, -8.5)[2], '_z_clearance_position': w(0, 0, -7.5)[2],
               '_measuring_wcs': 2, '_y_wcs_offset': 0.0},
              {(2, 'Y'): 6.0}))
    s.append(('circular_bore', 'probe_circular_bore', World([Cylinder(12.0, 6.0, 0.5, True)]),
              (12.03, 5.98, -8.5),
              {'_diameter_to_probe': 1.2, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    s.append(('circular_boss', 'probe_circular_boss', World([Cylinder(12.0, 6.0, 0.5, False, ztop=-8.0)]),
              (12.02, 6.01, -7.5),
              {'_diameter_to_position': 1.5, '_first_position_to_probe': w(0, 0, -8.5)[2],
               '_z_clearance_position': w(0, 0, -7.5)[2],
               '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    for vec in ((0, 120, 240), (30, 150, 270), (90, 200, 330)):
        s.append(('bore_three_point %s' % (vec,), 'probe_bore_three_point',
                  World([Cylinder(12.0, 6.0, 0.5, True)]), (12.03, 5.98, -8.5),
                  {'_first_vector': vec[0], '_second_vector': vec[1], '_third_vector': vec[2],
                   '_diameter_to_probe': 1.2, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
                  {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
        s.append(('boss_three_point %s' % (vec,), 'probe_boss_three_point',
                  World([Cylinder(12.0, 6.0, 0.5, False, ztop=-8.0)]), (12.02, 6.01, -7.5),
                  {'_first_vector': vec[0], '_second_vector': vec[1], '_third_vector': vec[2],
                   '_diameter_to_probe': 0.8, '_diameter_to_position': 1.6,
                   '_first_position_to_probe': w(0, 0, -8.5)[2],
                   '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
                  {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    return s


def run(macro_dir, sc):
    name, macro, world, start, params, expect = sc
    p = dict(FEEDS)
    p.update(params)
    it = Interp(world, {1: list(POS), 2: [3.0, 3.0, 3.0]}, 1, start, p)
    try:
        it.run(os.path.join(macro_dir, macro + '.nc'))
    except GcodeError as e:
        return it, str(e)
    return it, None


def report(it, err, expect):
    if err:
        return 'ERROR  %s' % err
    worst = 0.0
    parts = []
    for (n, ax), val in expect.items():
        got = it.off[n]['XYZ'.index(ax)]
        worst = max(worst, abs(got - val))
        parts.append('%s%d %+.5f' % (ax, n, got - val))
    flags = []
    if it.collisions:
        flags.append('COLLISION %s' % (it.collisions[0],))
    if it.active != 1:
        flags.append('exits in WCS %d' % it.active)
    return '%-7s err[%s]%s' % ('OK' if worst < 1e-6 and not it.collisions else 'off',
                                ', '.join(parts), ('  ' + '; '.join(flags)) if flags else '')


def main(argv):
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    compare = argv[argv.index('--compare') + 1] if '--compare' in argv else None
    base_dir = None
    if compare:
        base_dir = tempfile.mkdtemp()
        for f in os.listdir(root):
            if f.startswith('probe_') and f.endswith('.nc'):
                try:
                    data = subprocess.check_output(['git', '-C', root, 'show', '%s:%s' % (compare, f)])
                except subprocess.CalledProcessError:
                    continue
                open(os.path.join(base_dir, f), 'wb').write(data)
    for sc in scenarios():
        it, err = run(root, sc)
        line = '%-34s %s' % (sc[0], report(it, err, sc[5]))
        if base_dir:
            bit, berr = run(base_dir, sc)
            same = (berr is None and err is None and bit.trace == it.trace and bit.off == it.off) or \
                   (berr is not None and err is not None and berr.split(']')[-1] == err.split(']')[-1])
            line += '\n%-34s %s   trace %s' % ('  ' + compare, report(bit, berr, sc[5]),
                                               'IDENTICAL' if same else 'DIFFERENT')
        print(line)


if __name__ == '__main__':
    main(sys.argv)
