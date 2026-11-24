#!/usr/bin/env python3
"""Run the install TSD script, and the restore script it writes, against stub PathPilot modules in a
throw-away home folder.

    python3 tools/test_tsd.py [--python /usr/bin/python2.7]

--python runs the TSD scripts under another interpreter (PathPilot's TSD scripts use Python 2).
Stubs: linuxcnc (stat, ini) and redis (INI path) only - the scripts must not need PathPilot's
diagnostic framework (diagnostic_script_util, halsampler_manager), so those are absent.
"""
import argparse
import ast
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import build_tsd  # noqa: E402

INSTALL = os.path.join(ROOT, 'tsd', 'install_probing_macros.tsd')
RESTORE_NAME = 'restore_probing_macros.tsd'

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
}


def write(path, data):
    with open(path, 'wb') as f:
        f.write(data if isinstance(data, bytes) else data.encode('utf-8'))


def read(path):
    with open(path, 'rb') as f:
        return f.read()


def make_home():
    """A PathPilot-like home: ~/tmc -> ~/v2.10.0, an empty ~/tmc/subroutines, ~/gcode/logfiles."""
    home = tempfile.mkdtemp()
    os.makedirs(os.path.join(home, 'stubs'))
    for name, text in STUBS.items():
        write(os.path.join(home, 'stubs', name), text)
    os.makedirs(os.path.join(home, 'configs'))
    os.makedirs(os.path.join(home, 'v2.10.0', 'subroutines'))
    os.symlink(os.path.join(home, 'v2.10.0'), os.path.join(home, 'tmc'))
    os.makedirs(os.path.join(home, 'gcode', 'subroutines'))
    os.makedirs(os.path.join(home, 'gcode', 'logfiles'))
    return home


class Run(object):
    """One run of a script the way PathPilot runs it: stdout is the result JSON, stderr the log."""

    def __init__(self, python, script, home, env_extra=None):
        tmc_sub = os.path.join(home, 'tmc', 'subroutines')
        user_sub = os.path.join(home, 'gcode', 'subroutines')
        env = dict(os.environ, HOME=home, PYTHONPATH=os.path.join(home, 'stubs'),
                   STUB_INI_PATH=os.path.join(home, 'configs', 'mill.ini'),
                   STUB_SUBROUTINE_PATH=user_sub + ':' + tmc_sub)
        env.update(env_extra or {})
        p = subprocess.Popen([python, script], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.stdout, self.log = [s.decode('utf-8', 'replace') for s in p.communicate()]
        self.code = p.returncode
        try:
            self.result = json.loads(self.stdout)
        except ValueError:
            self.result = None

    @property
    def status(self):
        return (self.result or {}).get('diagnostic_status')

    @property
    def log_file(self):
        return (self.result or {}).get('output_file', '').split('\n')[0]

    def text(self):
        return self.log + self.stdout


def backups(home):
    gcode = os.path.join(home, 'gcode')
    return sorted(os.path.join(gcode, d) for d in os.listdir(gcode) if d.startswith('probing_macros_backup_'))


def snapshot(folder, skip=()):
    return {f: (read(os.path.join(folder, f)), os.stat(os.path.join(folder, f)).st_mode & 0o777)
            for f in sorted(os.listdir(folder)) if os.path.isfile(os.path.join(folder, f)) and f not in skip}


def contents(snap):
    return {n: d for n, (d, m) in snap.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--python', default=sys.executable, help='interpreter for the TSD scripts')
    python = ap.parse_args().python

    new = build_tsd.repo_set()
    original = build_tsd.commit_set(build_tsd.ORIGINAL_COMMIT)
    added = sorted(set(new) - set(original))      # new files: a restore removes them
    dropped = sorted(set(original) - set(new))    # baseline files the install removes
    results = []

    def check(name, cond, detail=''):
        results.append((name, bool(cond), detail))

    def file_tab_checks(label, script):
        """What PathPilot's File tab needs to run a file as a tech support diagnostic (ui_common.py): a
        .tsd extension, a shebang on line 1, module-level diagnostic_name / setup_instructions /
        warning_msg strings for its dialogs (parse_tsd_contents); it chmods +x itself. Plus: no HAL."""
        text = read(script).decode('utf-8')
        check(label + ': .tsd extension', os.path.splitext(script)[1].upper() == '.TSD', script)
        check(label + ': shebang on line 1', text.startswith('#!/'))
        tree = ast.parse(text)
        assigned = {}
        for node in tree.body:
            if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name):
                if isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
                    assigned[node.targets[0].id] = node.value.value
        check(label + ': dialog strings', all(k in assigned for k in ('diagnostic_name', 'setup_instructions', 'warning_msg')),
              sorted(assigned))
        check(label + ': executable', os.access(script, os.X_OK))
        imported = set()
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                imported.update(a.name for a in node.names)
            elif isinstance(node, ast.ImportFrom):
                imported.add(node.module)
        check(label + ': no HAL / DiagnosticTestBase',
              not imported & {'diagnostic_script_util', 'halsampler_manager', 'hal'}, sorted(imported))
        check(label + ': no unfilled placeholder', not re.search(r'@[A-Z_0-9]+@', text),
              re.findall(r'@[A-Z_0-9]+@', text)[:5])
        return assigned

    file_tab_checks('install', INSTALL)
    check('repo: no static restore script', not os.path.exists(os.path.join(ROOT, 'tsd', 'restore_original_probing_macros.tsd')))

    homes = []
    try:
        # ---- a machine with the baseline macros (one locally edited, one with another mode),
        # an unrelated stock file and a user subroutine
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
        os.chmod(os.path.join(tmc, 'probe_z_for_position.nc'), 0o600)
        before = snapshot(tmc)

        r = Run(python, INSTALL, home, {'STUB_INTERP_STATE': '2'})
        check('install, program running: refused', 'a program is running' in r.log and r.status == 'failed', r.text())
        check('install, program running: nothing changed', snapshot(tmc) == before and not backups(home))

        damaged = os.path.join(home, 'damaged.tsd')
        text = read(INSTALL).decode('utf-8')
        text = re.sub(r'\("probe_result\.nc", "[0-9a-f]{64}"', '("probe_result.nc", "%s"' % ('0' * 64), text)
        write(damaged, text)
        r = Run(python, damaged, home)
        check('install, damaged script: refused', 'embedded copy of probe_result.nc is damaged' in r.log, r.text())
        check('install, damaged script: nothing changed', snapshot(tmc) == before and not backups(home))

        r = Run(python, INSTALL, home)
        check('install: completes', r.code == 0 and r.status == 'complete', r.text())
        check('install: stdout is only the JSON PathPilot reads',
              isinstance(r.result, dict) and set(r.result) == {'diagnostic_status', 'output_file'}, r.stdout)
        check('install: log saved in ~/gcode/logfiles', os.path.isfile(r.log_file) and
              'Complete' in read(r.log_file).decode('utf-8') and
              r.log_file.startswith(os.path.join(home, 'gcode', 'logfiles')), r.log_file)
        check('install: every macro matches the repo', all(read(os.path.join(tmc, n)) == d for n, d in new.items()))
        check('install: all written, obsolete removed',
              '%d written, 0 already up to date, %d removed' % (len(new), len(dropped)) in r.log, r.log)
        check('install: log names the edited file', 'replaced probe_x_edge.nc (other version)' in r.log, r.log)
        check('install: log names baseline files', 'replaced probe_z.nc (baseline' in r.log, r.log)
        check('install: log names added files', 'added probe_result.nc' in r.log, r.log)
        check('install: probe_z_for_position removed', 'removed probe_z_for_position.nc (baseline' in r.log and
              not os.path.exists(os.path.join(tmc, 'probe_z_for_position.nc')), r.log)
        check('install: logs where ~/tmc points', 'is %s' % os.path.join(home, 'v2.10.0', 'subroutines') in r.log, r.log)
        b = backups(home)
        check('install: one backup folder in ~/gcode', len(b) == 1, b)
        b1 = b[0] if b else home
        restore1 = os.path.join(b1, RESTORE_NAME)
        check('install: backup holds every replaced or removed file as it was',
              contents(snapshot(b1, skip=(RESTORE_NAME,))) == {n: d for n, (d, m) in before.items() if n in original},
              sorted(snapshot(b1)))
        check('install: restore script written in the backup folder', os.path.isfile(restore1), sorted(os.listdir(b1)))
        check('install: log and result name the restore script',
              restore1 in r.log and r.result and r.result['output_file'].endswith('Restore script: ' + restore1),
              r.result)
        check('install: unrelated stock file untouched', read(os.path.join(tmc, 'other_stock.ngc')) == b'(stock file)\n')
        check('install: user subroutine untouched', read(os.path.join(user, 'set_tool_length.nc')) == b'(user file)\n')
        check('install: file mode kept', os.stat(os.path.join(tmc, 'probe_y_edge.nc')).st_mode & 0o777 == 0o664)
        check('install: no temporary files left', not [f for f in os.listdir(tmc) if f.endswith('.tsd_tmp')])
        check('install: no warnings', 'WARNING' not in r.log, r.log)

        if os.path.isfile(restore1):
            names = file_tab_checks('restore', restore1)
            check('restore: dialogs name the install time', 'before' in names.get('diagnostic_name', ''),
                  names.get('diagnostic_name'))

        installed = snapshot(tmc)
        r = Run(python, INSTALL, home)
        check('install again: nothing to do', '0 written, %d already up to date, 0 removed' % len(new) in r.log and
              r.status == 'complete', r.text())
        check('install again: no backup folder, no restore script', len(backups(home)) == 1 and
              'Nothing changed, so no restore script was written' in r.log and 'Restore script' not in r.stdout, r.text())

        r = Run(python, restore1, home, {'STUB_INTERP_STATE': '2'})
        check('restore, program running: refused', 'a program is running' in r.log and r.status == 'failed', r.text())
        check('restore, program running: nothing changed', snapshot(tmc) == installed and len(backups(home)) == 1)

        r = Run(python, restore1, home)
        check('restore: completes', r.code == 0 and r.status == 'complete', r.text())
        check('restore: machine exactly as before the install (contents and modes)', snapshot(tmc) == before,
              sorted(set(snapshot(tmc).items()) ^ set(before.items()))[:3])
        check('restore: wrote the saved files, removed the added ones',
              '%d written, 0 already up to date, %d removed' % (len(original), len(added)) in r.log, r.log)
        check('restore: log names the new versions', 'replaced probe_x_edge.nc (new version' in r.log and
              'removed probe_result.nc (new version' in r.log, r.log)
        check('restore: probe_z_for_position put back', 'added probe_z_for_position.nc' in r.log, r.log)
        b = backups(home)
        check('restore: its own backup folder, even in the same second', len(b) == 2, b)
        b2 = b[1] if len(b) == 2 else home
        check('restore: backup holds the new versions, no restore script of its own',
              contents(snapshot(b2)) == {n: d for n, (d, m) in installed.items() if n in new}, sorted(os.listdir(b2)))
        check('restore: log saved', 'probing_macros_restore_' in r.log_file and os.path.isfile(r.log_file), r.log_file)
        check('restore: no warnings', 'WARNING' not in r.log, r.log)

        r = Run(python, restore1, home)
        check('restore again: nothing to do', '0 written, %d already up to date, 0 removed' % len(original) in r.log, r.log)
        check('restore again: no new backup folder', len(backups(home)) == 2)

        r = Run(python, INSTALL, home)
        b = backups(home)
        check('install after restore: matches the repo, writes a new restore script',
              r.status == 'complete' and all(read(os.path.join(tmc, n)) == d for n, d in new.items()) and
              len(b) == 3 and os.path.isfile(os.path.join(b[2], RESTORE_NAME)), r.text())

        # ---- which copy PathPilot will use
        write(os.path.join(user, 'probe_x_edge.nc'), '(user copy)\n')
        r = Run(python, INSTALL, home)
        check('shadow: warns which copy PathPilot uses',
              'WARNING: PathPilot will use %s' % os.path.join(user, 'probe_x_edge.nc') in r.log, r.log)
        r = Run(python, os.path.join(b[2], RESTORE_NAME), home)
        check('shadow: restore warns too', 'WARNING: PathPilot will use' in r.log and r.status == 'complete', r.text())
        r = Run(python, INSTALL, home, {'STUB_SUBROUTINE_PATH': tmc + ':' + user})
        check('shadow later in path: no warning', 'WARNING' not in r.log, r.log)
        r = Run(python, INSTALL, home, {'STUB_SUBROUTINE_PATH': user})
        check('not in SUBROUTINE_PATH: warns', 'is not in SUBROUTINE_PATH' in r.log, r.log)
        r = Run(python, INSTALL, home, {'STUB_SUBROUTINE_PATH': '../tmc/subroutines'})
        check('relative SUBROUTINE_PATH: resolves from the INI folder', 'WARNING' not in r.log, r.log)

        # ---- a machine with no probing macros at all: the restore only deletes
        fresh = make_home()
        homes.append(fresh)
        ftmc = os.path.join(fresh, 'tmc', 'subroutines')
        write(os.path.join(ftmc, 'other_stock.ngc'), '(stock file)\n')
        fbefore = snapshot(ftmc)
        r = Run(python, INSTALL, fresh)
        fb = backups(fresh)
        check('fresh machine: install adds every macro', r.status == 'complete' and
              '%d written, 0 already up to date, 0 removed' % len(new) in r.log, r.text())
        check('fresh machine: backup folder holds only the restore script',
              len(fb) == 1 and sorted(os.listdir(fb[0])) == [RESTORE_NAME], fb and os.listdir(fb[0]))
        if fb:
            r = Run(python, os.path.join(fb[0], RESTORE_NAME), fresh)
            check('fresh machine: restore deletes every added macro', r.status == 'complete' and
                  snapshot(ftmc) == fbefore and '0 written, 0 already up to date, %d removed' % len(new) in r.log,
                  r.text())

        # ---- no ~/tmc/subroutines
        bare = tempfile.mkdtemp()
        homes.append(bare)
        os.makedirs(os.path.join(bare, 'stubs'))
        for name, text in STUBS.items():
            write(os.path.join(bare, 'stubs', name), text)
        os.makedirs(os.path.join(bare, 'gcode'))
        r = Run(python, INSTALL, bare)
        check('missing ~/tmc/subroutines: refused', 'not found - nothing was changed' in r.log and
              r.status == 'failed' and not os.path.exists(os.path.join(bare, 'tmc')), r.text())
        check('missing ~/gcode/logfiles: log saved in ~/gcode', os.path.dirname(r.log_file) == os.path.join(bare, 'gcode'),
              r.log_file)
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
