#!/usr/bin/env python3
"""Scenario tests for the probing macros using tools/sim_macros.py.

  python3 tools/test_macros.py                 run scenarios on the working tree
  python3 tools/test_macros.py --compare REV   also run REV's macros and diff traces

Machine model: probe tip 0.100, positioning WCS 1 (G54) offset X10 Y5 Z-8,
measuring WCS 2 (G55) starts at X3 Y3 Z3 so a wrong update is obvious.
"""
import os
import re
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
    # positioning-WCS zero at the feature center: the only case the polar version handled
    s.append(('bore_three_point zero at center', 'probe_bore_three_point',
              World([Cylinder(10.0, 5.0, 0.5, True)]), (10.03, 4.98, -8.5),
              {'_first_vector': 0, '_second_vector': 120, '_third_vector': 240,
               '_diameter_to_probe': 1.2, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 10.0, (2, 'Y'): 5.0}))
    s.append(('boss_three_point zero at center', 'probe_boss_three_point',
              World([Cylinder(10.0, 5.0, 0.5, False, ztop=-8.0)]), (10.02, 5.01, -7.5),
              {'_first_vector': 0, '_second_vector': 120, '_third_vector': 240,
               '_diameter_to_probe': 0.8, '_diameter_to_position': 1.6,
               '_first_position_to_probe': w(0, 0, -8.5)[2],
               '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 10.0, (2, 'Y'): 5.0}))
    # start well off center, measuring WCS = positioning WCS, non-zero target
    s.append(('bore_three_point off-center start', 'probe_bore_three_point',
              World([Cylinder(12.0, 6.0, 0.5, True)]), (12.15, 5.9, -8.5),
              {'_first_vector': 45, '_second_vector': 170, '_third_vector': 290,
               '_diameter_to_probe': 1.4, '_measuring_wcs': 1, '_x_wcs_offset': 2.5, '_y_wcs_offset': -1.0},
              {(1, 'X'): 9.5, (1, 'Y'): 7.0}))
    # close vectors: allowed, warning under 15 deg below 3 in, under 5 deg at 3 in and up
    s.append(('bore_three_point 10 deg apart', 'probe_bore_three_point',
              World([Cylinder(12.0, 6.0, 0.5, True)]), (12.03, 5.98, -8.5),
              {'_first_vector': 0, '_second_vector': 10, '_third_vector': 200,
               '_diameter_to_probe': 1.2, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    s.append(('bore_three_point 350/5/180', 'probe_bore_three_point',
              World([Cylinder(12.0, 6.0, 0.5, True)]), (12.03, 5.98, -8.5),
              {'_first_vector': 350, '_second_vector': 5, '_third_vector': 180,
               '_diameter_to_probe': 1.2, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    s.append(('bore_three_point 4in bore 10 deg', 'probe_bore_three_point',
              World([Cylinder(12.0, 6.0, 2.0, True)]), (12.03, 5.98, -8.5),
              {'_first_vector': 0, '_second_vector': 10, '_third_vector': 200,
               '_diameter_to_probe': 4.4, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    s.append(('bore_three_point 4in bore 3 deg', 'probe_bore_three_point',
              World([Cylinder(12.0, 6.0, 2.0, True)]), (12.03, 5.98, -8.5),
              {'_first_vector': 0, '_second_vector': 3, '_third_vector': 200,
               '_diameter_to_probe': 4.4, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    s.append(('boss_three_point 10 deg apart', 'probe_boss_three_point',
              World([Cylinder(12.0, 6.0, 0.5, False, ztop=-8.0)]), (12.02, 6.01, -7.5),
              {'_first_vector': 0, '_second_vector': 10, '_third_vector': 200,
               '_diameter_to_probe': 0.8, '_diameter_to_position': 1.6,
               '_first_position_to_probe': w(0, 0, -8.5)[2],
               '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
              {(2, 'X'): 12.0, (2, 'Y'): 6.0}))
    s.append(('bore_three_point same vector twice', 'probe_bore_three_point',
              World([Cylinder(12.0, 6.0, 0.5, True)]), (12.03, 5.98, -8.5),
              {'_first_vector': 0, '_second_vector': 0, '_third_vector': 200,
               '_diameter_to_probe': 1.2, '_measuring_wcs': 2, '_x_wcs_offset': 0.0, '_y_wcs_offset': 0.0},
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
    flags = ['DEBUG: ' + m for k, m in it.messages
             if k == 'DEBUG' and re.search(r'warning|OUT OF|OVER|not updated', m)]
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


# ---------------------------------------------------------------- result-step feature tests
G55 = [3.0, 3.0, 3.0]


def run_feature(macro, world, start, params, pause='resume'):
    p = dict(FEEDS)
    p.update(params)
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    it = Interp(world, {1: list(POS), 2: list(G55)}, 1, start, p, pause_answer=pause)
    err = None
    try:
        it.run(os.path.join(root, macro + '.nc'))
    except GcodeError as e:
        err = str(e)
    return it, err


def bore(params, pause='resume', nominal_xy=(9.0, 3.0)):
    base = {'_diameter_to_probe': 1.2, '_measuring_wcs': 2,
            '_x_wcs_offset': nominal_xy[0], '_y_wcs_offset': nominal_xy[1]}
    base.update(params)
    return run_feature('probe_circular_bore', World([Cylinder(12.0, 6.0, 0.5, True)]), (12.03, 5.98, -8.5),
                       base, pause)


def feature_tests():
    results = []

    def check(name, cond, detail=''):
        results.append((name, bool(cond), detail))

    def kinds(it):
        return [t[0] for t in it.trace]

    # inspect only: nominal 9.001 / 2.998 in G55, bore actually at 9 / 3
    it, err = bore({'_set_wcs': 0}, nominal_xy=(9.001, 2.998))
    check('inspect only: no error', err is None, err)
    check('inspect only: G55 unchanged', it.off[2][:2] == G55[:2], it.off[2])
    check('inspect only: deviations', abs(it.named['_result_x_dev'] + 0.001) < 1e-9 and
          abs(it.named['_result_y_dev'] - 0.002) < 1e-9, (it.named['_result_x_dev'], it.named['_result_y_dev']))
    check('inspect only: diameter 1.000', abs(it.named['_result_size'] - 1.0) < 1e-9, it.named['_result_size'])
    check('inspect only: _set_wcs reset to 1', it.named['_set_wcs'] == 1)
    check('inspect only: ends in positioning wcs', it.active == 1)

    tol = {'_nominal_size': 1.002, '_size_tolerance_plus': 0.001, '_size_tolerance_minus': 0.001}
    # undersize bore = material left -> status 1, default action pause, resume -> wcs set
    it, err = bore(dict(tol))
    k = kinds(it)
    check('rework: status 1', it.named.get('_result_status') == 1, it.named.get('_result_status'))
    check('rework: G30 Z then G30 then M0, then G10',
          'M0' in k and k.index('G30') < k.index('M0') < k.index('G10'), k[-8:])
    check('rework: Z retract first', [t for t in it.trace if t[0] == 'G30'][0][1] == ('Z',))
    check('rework: wcs set after resume', abs(it.off[2][0] - 3.0) < 1e-9 and abs(it.off[2][1] - 3.0) < 1e-9,
          it.off[2])
    check('rework: per-feature inputs cleared', it.named['_nominal_size'] == 0 and
          it.named['_size_tolerance_plus'] == 0)

    # operator stops at the M0 -> nothing updated (G55 target moved so an update would show)
    it, err = bore(dict(tol), pause='abort', nominal_xy=(0.0, 0.0))
    check('stop at M0: aborted', err is not None and 'M0' in err, err)
    check('stop at M0: G55 unchanged', it.off[2] == G55, it.off[2])

    # tolerance action 2 -> retract, log, abort; no update
    it, err = bore(dict(tol, _tolerance_action=2, _log_results=1), nominal_xy=(0.0, 0.0))
    check('abort action: aborted', err is not None and 'ABORT' in err, err)
    check('abort action: G55 unchanged', it.off[2] == G55, it.off[2])
    check('abort action: logged with wcs_updated 0', it.logfile and it.logfile[-1].split(',')[5] == '0.000000',
          it.logfile[-1:] if it.logfile else None)
    check('abort action: no M0', 'M0' not in kinds(it))

    # flag only -> no stop, wcs set, status kept for the caller
    it, err = bore(dict(tol, _tolerance_action=0), nominal_xy=(0.0, 0.0))
    check('flag only: no error, no M0', err is None and 'M0' not in kinds(it), err)
    check('flag only: status 1 and wcs set', it.named['_result_status'] == 1 and
          abs(it.off[2][0] - 12.0) < 1e-9, (it.named['_result_status'], it.off[2]))

    # oversize bore = material missing -> scrap
    it, err = bore({'_nominal_size': 0.998, '_size_tolerance_plus': 0.001, '_size_tolerance_minus': 0.001,
                    '_tolerance_action': 0})
    check('scrap: status 2', it.named['_result_status'] == 2, it.named['_result_status'])

    # boss oversize = material left -> rework
    it, err = run_feature('probe_circular_boss', World([Cylinder(12.0, 6.0, 0.5, False, ztop=-8.0)]),
                          (12.02, 6.01, -7.5),
                          {'_diameter_to_position': 1.5, '_first_position_to_probe': w(0, 0, -8.5)[2],
                           '_z_clearance_position': w(0, 0, -7.5)[2], '_measuring_wcs': 2,
                           '_x_wcs_offset': 9.0, '_y_wcs_offset': 3.0, '_nominal_size': 0.998,
                           '_size_tolerance_plus': 0.001, '_size_tolerance_minus': 0.001,
                           '_tolerance_action': 0})
    check('boss oversize: rework status 1', it.named.get('_result_status') == 1,
          (err, it.named.get('_result_status')))
    check('boss: diameter 1.000', abs(it.named['_result_size'] - 1.0) < 1e-9, it.named['_result_size'])

    # update minimum: edge 0.0004 from nominal -> not updated; 0.002 -> updated
    edge = World([Wall('X', 12.0, +1)])
    for nominal, expect_update in ((9.0004, False), (9.002, True)):
        it, err = run_feature('probe_x_edge', edge, (11.5, 6, -8.5),
                              {'_first_position_to_probe': w(12.5, 0, 0)[0], '_measuring_wcs': 2,
                               '_x_wcs_offset': nominal, '_update_minimum': 0.001})
        updated = abs(it.off[2][0] - 3.0) > 1e-9
        check('update minimum %.4f: updated=%s' % (nominal - 9.0, expect_update), updated == expect_update,
              (err, it.off[2][0]))
        check('update minimum: _update_minimum cleared', it.named['_update_minimum'] == 0)

    # update maximum: 0.5 away with max 0.1 -> status 4, pause, never updated
    it, err = run_feature('probe_x_edge', edge, (11.5, 6, -8.5),
                          {'_first_position_to_probe': w(12.5, 0, 0)[0], '_measuring_wcs': 2,
                           '_x_wcs_offset': 9.5, '_update_maximum': 0.1})
    check('update maximum: status 4', it.named['_result_status'] == 4, it.named['_result_status'])
    check('update maximum: paused', 'M0' in kinds(it))
    check('update maximum: not updated after resume', it.off[2] == G55, it.off[2])

    # position tolerance on a three-point bore, flag only
    it, err = run_feature('probe_bore_three_point', World([Cylinder(12.0, 6.0, 0.5, True)]), (12.03, 5.98, -8.5),
                          {'_first_vector': 0, '_second_vector': 120, '_third_vector': 240,
                           '_diameter_to_probe': 1.2, '_measuring_wcs': 2, '_x_wcs_offset': 9.002,
                           '_y_wcs_offset': 3.0, '_position_tolerance': 0.0005, '_tolerance_action': 0})
    check('position tolerance: status 3', it.named.get('_result_status') == 3, (err, it.named.get('_result_status')))
    check('position tolerance: true position 0.004', abs(it.named['_result_tp_dev'] - 0.004) < 1e-9,
          it.named['_result_tp_dev'])

    # logging: new file with header, then append
    it, err = bore({'_log_results': 2, '_feature_number': 7})
    check('log 2: header + 1 row', len(it.logfile) == 2 and it.logfile[0].startswith('epoch,'), it.logfile)
    check('log 2: 21 columns', len(it.logfile[1].split(',')) == 21 == len(it.logfile[0].split(',')),
          it.logfile[1] if len(it.logfile) > 1 else None)
    check('log 2: switches to append', it.named['_log_results'] == 1)
    check('log row: macro name and feature', ',probe_circular_bore,' in it.logfile[1] and
          it.logfile[1].split(',')[1] == '7.000000', it.logfile[1])

    # z with tolerance-free inspect: z dev reported
    it, err = run_feature('probe_z', World([Floor(-9.0)]), (11, 6, -8.6),
                          {'_first_position_to_probe': w(0, 0, -9.5)[2], '_measuring_wcs': 2,
                           '_z_wcs_offset': -12.0, '_set_wcs': 0})
    check('z inspect: dev 0', abs(it.named['_result_z_dev']) < 1e-9, (err, it.named.get('_result_z_dev')))

    # ---- wear corrections (cut-measure-cut)
    tol0 = {'_nominal_size': 1.002, '_set_wcs': 0, '_tolerance_action': 0}
    it, err = bore(dict(tol0, _update_tool=5))
    check('wear bore undersize: pending -0.002 on T5', it.named.get('_wear_pending_tool') == 5 and
          abs(it.named['_wear_pending_diameter'] + 0.002) < 1e-9, (err, it.named.get('_wear_pending_diameter')))
    check('wear: _update_tool cleared', it.named['_update_tool'] == 0)
    # apply with T5 loaded and existing wear .0003 / .0010
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    it.tools[5] = {'I': 0.0003, 'W': 0.0010}
    it.loaded = 5
    it.run(os.path.join(root, 'probe_apply_wear.nc'))
    check('apply: T5 diameter wear .0003 - .002 = -.0017', abs(it.tools[5]['I'] + 0.0017) < 1e-9, it.tools[5])
    check('apply: length wear unchanged', abs(it.tools[5]['W'] - 0.0010) < 1e-9, it.tools[5])
    check('apply: G43 re-issued, pending cleared', it.trace[-1] == ('G43', 5) and it.named['_wear_pending_tool'] == 0)

    it, err = bore(dict(tol0, _update_tool=5, _update_feedback=0.5))
    check('wear feedback 0.5: -0.001', abs(it.named['_wear_pending_diameter'] + 0.001) < 1e-9,
          it.named['_wear_pending_diameter'])
    # second measurement on the same tool accumulates; a different tool replaces with a warning
    it.named.update({'_nominal_size': 1.002, '_set_wcs': 0, '_update_tool': 5})
    it.M = [12.03, 5.98, -8.5]
    it.run(os.path.join(root, 'probe_circular_bore.nc'))
    check('wear: same tool accumulates -0.001 + -0.002', abs(it.named['_wear_pending_diameter'] + 0.003) < 1e-9,
          it.named['_wear_pending_diameter'])
    it.named.update({'_nominal_size': 1.002, '_set_wcs': 0, '_update_tool': 7})
    it.M = [12.03, 5.98, -8.5]
    it.run(os.path.join(root, 'probe_circular_bore.nc'))
    check('wear: other tool replaces pending with a warning', it.named['_wear_pending_tool'] == 7 and
          abs(it.named['_wear_pending_diameter'] + 0.002) < 1e-9 and
          any('never applied' in m for k, m in it.messages if k == 'DEBUG'), it.named['_wear_pending_diameter'])
    # wrong tool loaded -> not applied, kept
    it.loaded = 5
    it.tools[5] = {'I': 0.0, 'W': 0.0}
    it.run(os.path.join(root, 'probe_apply_wear.nc'))
    check('apply with wrong tool: kept, not written', it.named['_wear_pending_tool'] == 7 and it.tools[5]['I'] == 0)

    # boss oversize .002 -> diameter wear -.002 (external)
    it, err = run_feature('probe_circular_boss', World([Cylinder(12.0, 6.0, 0.5, False, ztop=-8.0)]),
                          (12.02, 6.01, -7.5),
                          {'_diameter_to_position': 1.5, '_first_position_to_probe': w(0, 0, -8.5)[2],
                           '_z_clearance_position': w(0, 0, -7.5)[2], '_measuring_wcs': 2,
                           '_x_wcs_offset': 9.0, '_y_wcs_offset': 3.0, '_nominal_size': 0.998,
                           '_set_wcs': 0, '_update_tool': 4})
    check('wear boss oversize: pending -0.002', abs(it.named.get('_wear_pending_diameter', 1) + 0.002) < 1e-9,
          (err, it.named.get('_wear_pending_diameter')))

    # Z face .003 high -> length wear -.003, Z wcs not moved even though _set_wcs defaults to 1
    it, err = run_feature('probe_z', World([Floor(-9.0)]), (11, 6, -8.6),
                          {'_first_position_to_probe': w(0, 0, -9.5)[2], '_measuring_wcs': 2,
                           '_z_wcs_offset': -12.003, '_update_tool': 3})
    check('wear Z face high: length -0.003', abs(it.named.get('_wear_pending_length', 1) + 0.003) < 1e-9,
          (err, it.named.get('_wear_pending_length')))
    check('wear Z: wcs not moved', it.off[2] == G55, it.off[2])

    # limits and edges
    it, err = bore(dict(tol0, _update_tool=5, _update_minimum=0.003))
    check('wear under minimum: nothing pending', not it.named.get('_wear_pending_diameter'),
          it.named.get('_wear_pending_diameter'))
    it, err = bore(dict(tol0, _update_tool=5, _update_maximum=0.001))
    check('wear over maximum: nothing pending, status 4', not it.named.get('_wear_pending_diameter') and
          it.named['_result_status'] == 4)
    it, err = bore(dict(tol0, _update_tool=5, _size_tolerance_plus=0.001, _size_tolerance_minus=0.001,
                        _tolerance_action=1), pause='abort')
    check('wear: stop at M0 leaves nothing pending', not it.named.get('_wear_pending_diameter'),
          (err, it.named.get('_wear_pending_diameter')))
    it, err = run_feature('probe_x_edge', World([Wall('X', 12.0, +1)]), (11.5, 6, -8.5),
                          {'_first_position_to_probe': w(12.5, 0, 0)[0], '_measuring_wcs': 2,
                           '_x_wcs_offset': 9.0, '_update_tool': 5})
    check('wear on an edge: skipped with a message', not it.named.get('_wear_pending_diameter') and
          any('needs _nominal_size' in m for k, m in it.messages if k == 'DEBUG'))
    it, err = bore({'_log_results': 2, '_nominal_size': 1.002, '_set_wcs': 0, '_update_tool': 5,
                    '_tolerance_action': 0})
    check('log: 21 columns with tool and correction', len(it.logfile[1].split(',')) == 21 and
          it.logfile[1].split(',')[-2:] == ['5.000000', '-0.002000'], it.logfile)

    width = max(len(n) for n, _, _ in results)
    fails = 0
    for name, ok, detail in results:
        fails += not ok
        print('%-*s  %s%s' % (width, name, 'PASS' if ok else 'FAIL', '' if ok else '  ' + str(detail)))
    print('%d checks, %d failed' % (len(results), fails))
    return fails


if __name__ == '__main__' and '--features' in sys.argv:
    sys.exit(1 if feature_tests() else 0)
