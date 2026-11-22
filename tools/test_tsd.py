#!/usr/bin/env python3
"""Run tsd/install_probing_macros.py against stub PathPilot modules in a throw-away home folder.

    python3 tools/test_tsd.py

Stubs: linuxcnc (stat, ini), redis (INI path), diagnostic_script_util / halsampler_manager
(the TSD base class: log, start_new_session, save_logs, result_dict, stat).
"""
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, 'tsd', 'install_probing_macros.py')

STUBS = {
    'linuxcnc.py': '''
import os
INTERP_IDLE = 1
class stat(object):
    def __init__(self):
        self.interp_state = int(os.environ.get('STUB_INTERP_STATE', '1'))
    def poll(self):
        pass
class ini(object):
    def __init__(self, path):
        self.path = path
    def find(self, section, key):
        if (section, key) == ('RS274NGC', 'SUBROUTINE_PATH'):
            return os.environ.get('STUB_SUBROUTINE_PATH')
        return None
''',
    'redis.py': '''
import os
class Redis(object):
    def hget(self, h, k):
        return os.environ['STUB_INI_PATH'].encode('utf-8')
''',
    'halsampler_manager.py': '''
class HalSamplerCaptureTool(object):
    pass
''',
    'ui_common.py': '''
class TempFileManager(object):
    pass
''',
    'diagnostic_script_util.py': '''
import linuxcnc
class DiagnosticError(Exception):
    pass
def make_sampler_csv_header(pins):
    return ','.join(pins)
class DiagnosticTestBase(object):
    def __init__(self, tool, prefix, pins):
        self.result_dict = {}
        self.stat = linuxcnc.stat()
    def start_new_session(self):
        print('SESSION')
    def log(self, msg):
        print('LOG ' + msg)
    def save_logs(self):
        print('SAVED')
    def on_exit(self):
        print('STATUS ' + str(self.result_dict.get('diagnostic_status')))
''',
}


def macros_in_repo():
    names = sorted(f for f in os.listdir(ROOT) if f.startswith('probe_') and f.endswith('.nc'))
    return {n: open(os.path.join(ROOT, n), 'rb').read() for n in names}


def run(home, env_extra):
    stubs = os.path.join(home, 'stubs')
    env = dict(os.environ, HOME=home, PYTHONPATH=stubs, STUB_INI_PATH=os.path.join(home, 'tmc', 'mill.ini'))
    env.setdefault('STUB_SUBROUTINE_PATH', os.path.join(home, 'gcode', 'subroutines'))
    env.update(env_extra)
    out = subprocess.run([sys.executable, SCRIPT], env=env, capture_output=True, text=True)
    return out.returncode, out.stdout + out.stderr


def main():
    results = []

    def check(name, cond, detail=''):
        results.append((name, bool(cond), detail))

    repo = macros_in_repo()
    home = tempfile.mkdtemp()
    try:
        os.makedirs(os.path.join(home, 'stubs'))
        for name, text in STUBS.items():
            open(os.path.join(home, 'stubs', name), 'w').write(text)
        sub = os.path.join(home, 'gcode', 'subroutines')
        os.makedirs(sub)
        os.makedirs(os.path.join(home, 'tmc'))
        # machine state before: an old probe_x_edge, an obsolete macro, a user file, an up-to-date probe_z
        open(os.path.join(sub, 'probe_x_edge.nc'), 'w').write('o<probe_x_edge> sub\n(old)\no<probe_x_edge> endsub\n')
        open(os.path.join(sub, 'probe_z_for_position.nc'), 'w').write('(obsolete)\n')
        open(os.path.join(sub, 'set_tool_length.nc'), 'w').write('(user file)\n')
        open(os.path.join(sub, 'probe_z.nc'), 'wb').write(repo['probe_z.nc'])

        # program running: nothing changes
        code, out = run(home, {'STUB_INTERP_STATE': '2'})
        check('running program: refused', 'a program is running' in out and 'STATUS None' in out, out)
        check('running program: old file kept', b'(old)' in open(os.path.join(sub, 'probe_x_edge.nc'), 'rb').read())

        # first install
        code, out = run(home, {})
        check('install: completes', code == 0 and 'STATUS complete' in out, out)
        same = all(open(os.path.join(sub, n), 'rb').read() == t for n, t in repo.items())
        check('install: every macro matches the repo', same)
        check('install: 15 written, 1 up to date', '15 written, 1 already up to date' in out, out)
        backups = [d for d in os.listdir(sub) if d.startswith('probing_macros_backup_')]
        check('install: one backup folder', len(backups) == 1, backups)
        bdir = os.path.join(sub, backups[0]) if backups else ''
        check('backup: old probe_x_edge saved',
              backups and b'(old)' in open(os.path.join(bdir, 'probe_x_edge.nc'), 'rb').read())
        check('backup: obsolete probe_z_for_position moved',
              backups and os.path.isfile(os.path.join(bdir, 'probe_z_for_position.nc')) and
              not os.path.exists(os.path.join(sub, 'probe_z_for_position.nc')))
        check('backup: unchanged probe_z not copied', backups and not os.path.exists(os.path.join(bdir, 'probe_z.nc')))
        check('user file untouched', open(os.path.join(sub, 'set_tool_length.nc')).read() == '(user file)\n')
        check('no temporary files left', not [f for f in os.listdir(sub) if f.endswith('.tsd_tmp')])
        check('no warnings', 'WARNING' not in out, out)

        # second install: nothing to do, no new backup folder
        code, out = run(home, {})
        check('reinstall: all up to date', '0 written, 16 already up to date' in out and 'STATUS complete' in out, out)
        check('reinstall: no new backup folder',
              len([d for d in os.listdir(sub) if d.startswith('probing_macros_backup_')]) == 1)

        # another folder earlier in SUBROUTINE_PATH holds a copy
        shadow = os.path.join(home, 'tmc', 'subroutines')
        os.makedirs(shadow)
        open(os.path.join(shadow, 'probe_x_edge.nc'), 'w').write('(shipped copy)\n')
        code, out = run(home, {'STUB_SUBROUTINE_PATH': shadow + ':' + sub})
        check('shadow: warns which copy PathPilot uses',
              'WARNING: PathPilot will use %s' % os.path.join(shadow, 'probe_x_edge.nc') in out, out)
        code, out = run(home, {'STUB_SUBROUTINE_PATH': sub + ':' + shadow})
        check('shadow later in path: no warning', 'WARNING' not in out, out)

        # target not searched at all
        code, out = run(home, {'STUB_SUBROUTINE_PATH': shadow})
        check('not in SUBROUTINE_PATH: warns', 'is not in SUBROUTINE_PATH' in out, out)

        # relative SUBROUTINE_PATH entries resolve from the INI folder
        code, out = run(home, {'STUB_SUBROUTINE_PATH': '../gcode/subroutines'})
        check('relative SUBROUTINE_PATH: resolves', 'WARNING' not in out, out)

        # a third run against the final state still verifies cleanly
        code, out = run(home, {})
        check('final state verifies', 'Failed' not in out, out)
    finally:
        shutil.rmtree(home)

    width = max(len(n) for n, _, _ in results)
    fails = 0
    for name, ok, detail in results:
        fails += not ok
        print('%-*s  %s%s' % (width, name, 'PASS' if ok else 'FAIL', '' if ok else '\n' + str(detail)[:2000]))
    print('%d checks, %d failed' % (len(results), fails))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
