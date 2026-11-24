#!/usr/bin/env python3
"""Run the two TSD scripts against stub PathPilot modules in a throw-away home folder.

    python3 tools/test_tsd.py [--python /usr/bin/python2.7]

--python runs the TSD scripts under another interpreter (PathPilot's TSD scripts use Python 2).
Stubs: linuxcnc (stat, ini), redis (INI path), diagnostic_script_util / halsampler_manager
(the TSD base class: log, start_new_session, save_logs, result_dict, stat).
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import build_tsd  # noqa: E402

INSTALL = os.path.join(ROOT, 'tsd', 'install_probing_macros.tsd')
RESTORE = os.path.join(ROOT, 'tsd', 'restore_original_probing_macros.tsd')

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
    # like PathPilot 2.14.4's: no self.stat (the first machine run failed on that)
    def __init__(self, tool, prefix, pins):
        self.result_dict = {}
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


def write(path, data):
    with open(path, 'wb') as f:
        f.write(data if isinstance(data, bytes) else data.encode('utf-8'))


def read(path):
    with open(path, 'rb') as f:
        return f.read()


def make_home():
    """A PathPilot-like home: ~/tmc -> ~/v2.10.0, original macros in ~/tmc/subroutines."""
    home = tempfile.mkdtemp()
    os.makedirs(os.path.join(home, 'stubs'))
    for name, text in STUBS.items():
        write(os.path.join(home, 'stubs', name), text)
    os.makedirs(os.path.join(home, 'configs'))
    os.makedirs(os.path.join(home, 'v2.10.0', 'subroutines'))
    os.symlink(os.path.join(home, 'v2.10.0'), os.path.join(home, 'tmc'))
    os.makedirs(os.path.join(home, 'gcode', 'subroutines'))
    return home


def run(python, script, home, env_extra=None):
    tmc_sub = os.path.join(home, 'tmc', 'subroutines')
    user_sub = os.path.join(home, 'gcode', 'subroutines')
    env = dict(os.environ, HOME=home, PYTHONPATH=os.path.join(home, 'stubs'),
               STUB_INI_PATH=os.path.join(home, 'configs', 'mill.ini'),
               STUB_SUBROUTINE_PATH=user_sub + ':' + tmc_sub)
    env.update(env_extra or {})
    p = subprocess.Popen([python, script], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out = p.communicate()[0].decode('utf-8', 'replace')
    return p.returncode, out


def backups(home):
    gcode = os.path.join(home, 'gcode')
    return sorted(os.path.join(gcode, d) for d in os.listdir(gcode) if d.startswith('probing_macros_backup_'))


def snapshot(folder):
    return {f: read(os.path.join(folder, f)) for f in sorted(os.listdir(folder))
            if os.path.isfile(os.path.join(folder, f))}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--python', default=sys.executable, help='interpreter for the TSD scripts')
    python = ap.parse_args().python

    new = {n: t.encode('utf-8') for n, t in build_tsd.repo_set().items()}
    original = {n: t.encode('utf-8') for n, t in build_tsd.commit_set(build_tsd.ORIGINAL_COMMIT).items()}
    added = sorted(set(new) - set(original))      # new support files the restore removes
    dropped = sorted(set(original) - set(new))    # originals the install removes
    results = []

    def check(name, cond, detail=''):
        results.append((name, bool(cond), detail))

    # ---- what PathPilot's File tab needs to run a file as a tech support diagnostic (ui_common.py):
    # a .tsd extension, a shebang on line 1, and module-level diagnostic_name / setup_instructions /
    # warning_msg strings for its dialogs (parse_tsd_contents)
    import ast
    for script in (INSTALL, RESTORE):
        name = os.path.basename(script)
        text = read(script).decode('utf-8')
        check(name + ': .tsd extension', os.path.splitext(script)[1].upper() == '.TSD')
        check(name + ': shebang on line 1', text.startswith('#!/'))
        assigned = {}
        for node in ast.parse(text).body:
            if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
                if isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
                    assigned[node.targets[0].id] = node.value.value
        check(name + ': dialog strings', all(k in assigned for k in ('diagnostic_name', 'setup_instructions', 'warning_msg')),
              sorted(assigned))
        check(name + ': executable', os.access(script, os.X_OK))

    homes = []
    try:
        # ---- a machine with the original macros (one locally edited) and an unrelated stock file
        home = make_home()
        homes.append(home)
        tmc = os.path.join(home, 'tmc', 'subroutines')
        user = os.path.join(home, 'gcode', 'subroutines')
        for name, data in original.items():
            write(os.path.join(tmc, name), data)
        write(os.path.join(tmc, 'probe_x_edge.nc'), 'o<probe_x_edge> sub\n(edited)\no<probe_x_edge> endsub\n')
        write(os.path.join(tmc, 'other_stock.ngc'), '(stock file)\n')
        write(os.path.join(user, 'set_tool_length.nc'), '(user file)\n')
        os.chmod(os.path.join(tmc, 'probe_y_edge.nc'), 0o664)
        before = snapshot(tmc)

        code, out = run(python, INSTALL, home, {'STUB_INTERP_STATE': '2'})
        check('install, program running: refused', 'a program is running' in out and 'STATUS failed' in out, out)
        check('install, program running: nothing changed', snapshot(tmc) == before and not backups(home))

        damaged = os.path.join(home, 'damaged.py')
        text = read(INSTALL).decode('utf-8')
        write(damaged, text.replace('o<probe_result> sub', 'o<probe_result> sub ', 1))
        code, out = run(python, damaged, home)
        check('install, damaged script: refused', 'embedded copy of probe_result.nc is damaged' in out, out)
        check('install, damaged script: nothing changed', snapshot(tmc) == before and not backups(home))

        code, out = run(python, INSTALL, home)
        check('install: completes', code == 0 and 'STATUS complete' in out, out)
        check('install: every macro matches the repo', all(read(os.path.join(tmc, n)) == d for n, d in new.items()))
        check('install: all written, obsolete removed', '%d written, 0 already up to date, %d removed' % (len(new), len(dropped)) in out, out)
        check('install: log names the edited file', 'replaced probe_x_edge.nc (other version)' in out, out)
        check('install: log names original files', 'replaced probe_z.nc (original)' in out, out)
        check('install: log names added files', 'added probe_result.nc' in out, out)
        check('install: probe_z_for_position removed',
              'removed probe_z_for_position.nc (original)' in out and
              not os.path.exists(os.path.join(tmc, 'probe_z_for_position.nc')), out)
        check('install: logs where ~/tmc points', 'is %s' % os.path.join(home, 'v2.10.0', 'subroutines') in out, out)
        b = backups(home)
        check('install: one backup folder in ~/gcode', len(b) == 1, b)
        saved = snapshot(b[0]) if b else {}
        check('install: backup holds every replaced or removed file as it was',
              saved == {n: d for n, d in before.items() if n in original}, sorted(saved))
        check('install: unrelated stock file untouched', read(os.path.join(tmc, 'other_stock.ngc')) == b'(stock file)\n')
        check('install: user subroutine untouched', read(os.path.join(user, 'set_tool_length.nc')) == b'(user file)\n')
        check('install: file mode kept', os.stat(os.path.join(tmc, 'probe_y_edge.nc')).st_mode & 0o777 == 0o664)
        check('install: no temporary files left', not [f for f in os.listdir(tmc) if f.endswith('.tsd_tmp')])
        check('install: no warnings', 'WARNING' not in out, out)

        code, out = run(python, INSTALL, home)
        check('install again: nothing to do', '0 written, %d already up to date, 0 removed' % len(new) in out and
              'STATUS complete' in out, out)
        check('install again: no new backup folder', len(backups(home)) == 1)

        installed = snapshot(tmc)
        code, out = run(python, RESTORE, home)
        check('restore: completes', code == 0 and 'STATUS complete' in out, out)
        check('restore: every macro matches the original',
              all(read(os.path.join(tmc, n)) == d for n, d in original.items()))
        check('restore: all written, new files removed', '%d written, 0 already up to date, %d removed' % (len(original), len(added)) in out, out)
        check('restore: new support files removed',
              added and not [n for n in added if os.path.exists(os.path.join(tmc, n))], added)
        check('restore: log names the new version', 'replaced probe_x_edge.nc (new version' in out and
              'removed probe_result.nc (new version' in out, out)
        check('restore: probe_z_for_position added back', 'added probe_z_for_position.nc' in out, out)
        b = backups(home)
        check('restore: second backup folder, even in the same second', len(b) == 2, b)
        saved = snapshot(b[1]) if len(b) == 2 else {}
        check('restore: backup holds the new versions', saved == {n: d for n, d in installed.items() if n in new},
              sorted(saved))
        check('restore: unrelated stock file untouched', read(os.path.join(tmc, 'other_stock.ngc')) == b'(stock file)\n')
        check('restore: no warnings', 'WARNING' not in out, out)

        code, out = run(python, RESTORE, home)
        check('restore again: nothing to do', '0 written, %d already up to date, 0 removed' % len(original) in out, out)
        check('restore again: no new backup folder', len(backups(home)) == 2)

        code, out = run(python, INSTALL, home)
        check('install after restore: matches the repo', 'STATUS complete' in out and
              all(read(os.path.join(tmc, n)) == d for n, d in new.items()), out)

        # ---- which copy PathPilot will use
        write(os.path.join(user, 'probe_x_edge.nc'), '(user copy)\n')
        code, out = run(python, INSTALL, home)
        check('shadow: warns which copy PathPilot uses',
              'WARNING: PathPilot will use %s' % os.path.join(user, 'probe_x_edge.nc') in out, out)
        code, out = run(python, RESTORE, home)
        check('shadow: restore warns too', 'WARNING: PathPilot will use' in out, out)
        code, out = run(python, INSTALL, home, {'STUB_SUBROUTINE_PATH': tmc + ':' + user})
        check('shadow later in path: no warning', 'WARNING' not in out, out)
        code, out = run(python, INSTALL, home, {'STUB_SUBROUTINE_PATH': user})
        check('not in SUBROUTINE_PATH: warns', 'is not in SUBROUTINE_PATH' in out, out)
        code, out = run(python, INSTALL, home, {'STUB_SUBROUTINE_PATH': '../tmc/subroutines'})
        check('relative SUBROUTINE_PATH: resolves from the INI folder', 'WARNING' not in out, out)

        # ---- no ~/tmc/subroutines
        bare = tempfile.mkdtemp()
        homes.append(bare)
        os.makedirs(os.path.join(bare, 'stubs'))
        for name, text in STUBS.items():
            write(os.path.join(bare, 'stubs', name), text)
        os.makedirs(os.path.join(bare, 'gcode'))
        code, out = run(python, INSTALL, bare)
        check('missing ~/tmc/subroutines: refused', 'not found - nothing was changed' in out and
              'STATUS failed' in out and not os.path.exists(os.path.join(bare, 'tmc')), out)
    finally:
        for h in homes:
            shutil.rmtree(h)

    print('TSD scripts run with %s' % python)
    width = max(len(n) for n, _, _ in results)
    fails = 0
    for name, ok, detail in results:
        fails += not ok
        print('%-*s  %s%s' % (width, name, 'PASS' if ok else 'FAIL', '' if ok else '\n' + str(detail)[:2000]))
    print('%d checks, %d failed' % (len(results), fails))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
