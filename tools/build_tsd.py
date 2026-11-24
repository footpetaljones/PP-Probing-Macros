#!/usr/bin/env python3
"""Build the TSD script that installs the probing macros on a machine.

    python3 tools/build_tsd.py

  tsd/install_probing_macros.tsd   the macros in this repo (probe_*.nc)

Each macro is embedded (base64) with its SHA-256, so one file is all a machine needs. Before it
changes anything, the install copies every file it will replace or remove into
~/gcode/probing_macros_backup_<date>_<time>/ and writes restore_probing_macros.tsd there: that
script puts those copies back and deletes the files the install added, so it undoes exactly that
run on that machine. The install carries its own template (TEMPLATE_B64) to write it.

Rebuild and commit whenever a macro changes; tools/test_tsd.py runs the install and the restore it
writes against stub PathPilot modules.
"""
import base64
import hashlib
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TSD_DIR = os.path.join(ROOT, 'tsd')

# The macro set before this work (Norman's upload): the install removes its files that the new set
# does not have, and the log names its versions "baseline".
ORIGINAL_COMMIT = '9fe40cb'

# Placeholders are @NAME@; code inside the template that needs one builds it from pieces, so that
# filling the template never touches it.
TEMPLATE = r'''#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
TSD script: @SUMMARY@

@ORIGIN@

What it does
  1. Stops if a program is running, or if ~/tmc/subroutines is missing or read-only.
  2. Copies every file it will replace or remove into ~/gcode/probing_macros_backup_<date>_<time>/
@RESTORE_STEP@  4. Writes the @COUNT@ macro files and checks each one byte for byte.
  5. Removes @REMOVE_TEXT@ if present.
  6. Warns if PathPilot's SUBROUTINE_PATH would find another copy of a macro first.
  7. Saves its log in ~/gcode/logfiles/@LOG_PREFIX@_<date>_<time>.txt

It does not use PathPilot's DiagnosticTestBase: that loads a HAL sampler, and on a 1500MX
(PathPilot 2.14.4) rtapi_app crashed (signal 11, drives e-stopped) as the sampler session
closed after an install. This script touches no HAL; it only prints the JSON PathPilot reads.
"""
import base64
import hashlib
import io
import json
import os
import shutil
import sys
import time
import traceback

import linuxcnc

# Provide a name for the test that will be shown to user before starting it
diagnostic_name = "@NAME@"
log_file_prefix = "@LOG_PREFIX@"

# Shown in a dialog when the script first loads, but before it runs
setup_instructions = """
1) Stop any running program (the machine can be on or off)
2) Press OK to @ACTION@
"""

# Shown in a dialog when the TSD script starts running
warning_msg = """
The CAM driven probing macros in ~/tmc/subroutines will be replaced with the @SET_NAME@.
Replaced and removed files are saved to ~/gcode/probing_macros_backup_<date>_<time>.
The machine does not move. Reload any open program afterwards.
"""

MACRO_SET = "@SET_LABEL@"
TARGET_DIR = os.path.expanduser("~/tmc/subroutines")
BACKUP_PARENT = os.path.expanduser("~/gcode")
LOG_DIR = os.path.expanduser("~/gcode/logfiles")
RESTORE_NAME = "restore_probing_macros.tsd"

# Files deleted if present (copied to the backup folder first)
REMOVE = @REMOVE@

# Versions this script recognises, for the log (sha256: label)
KNOWN = {
@KNOWN@}

# (file name, sha256 of the contents, file mode or None to keep the current one, contents in base64)
MACROS = [
@MACROS@]

# The template this script was made from, in base64. The install fills it in to write the restore
# script for each run; empty in a restore script.
TEMPLATE_B64 = (
@TEMPLATE_B64@)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_bytes(path):
    with io.open(path, "rb") as f:
        return f.read()


def write_bytes(path, data):
    with io.open(path, "wb") as f:
        f.write(data)


def to_bytes(text):
    return text if isinstance(text, bytes) else text.encode("utf-8")


def b64_literal(data, indent):
    """Python source for a base64 string, as adjacent literals of 76 characters."""
    text = base64.b64encode(data)
    if not isinstance(text, str):
        text = text.decode("ascii")
    if not text:
        return indent + '""'
    return "\n".join('{}"{}"'.format(indent, text[i:i + 76]) for i in range(0, len(text), 76))


def version_of(path):
    return KNOWN.get(sha256(read_bytes(path)), "other version")


def new_backup_dir(stamp):
    base = os.path.join(BACKUP_PARENT, "probing_macros_backup_" + stamp)
    path = base
    n = 2
    while os.path.exists(path):
        path = "{}_{}".format(base, n)
        n += 1
    return path


def subroutine_path():
    """Directories PathPilot searches for subroutines, in order, from the INI file."""
    import redis
    ini_path = redis.Redis().hget("machine_prefs", "linuxcnc_inifilepath")
    if not isinstance(ini_path, str):
        ini_path = ini_path.decode("utf-8")
    value = linuxcnc.ini(ini_path).find("RS274NGC", "SUBROUTINE_PATH") or ""
    base = os.path.dirname(ini_path)
    dirs = []
    for entry in value.split(":"):
        entry = entry.strip()
        if entry:
            dirs.append(os.path.realpath(os.path.join(base, os.path.expanduser(entry))))
    return dirs


def restore_script(stamp, backup_dir, saved, added):
    """Source of the restore script for this run: writes back `saved` [(name, mode, bytes)] and
    deletes `added` (names this run creates)."""
    template = base64.b64decode(TEMPLATE_B64)
    if not isinstance(template, str):
        template = template.decode("utf-8")
    when = "{}-{}-{} {}:{}".format(stamp[0:4], stamp[4:6], stamp[6:8], stamp[9:11], stamp[11:13])
    known = {}
    for name, digest, mode, data in MACROS:
        known[digest] = KNOWN.get(digest, "new version")
    for name, mode, data in saved:
        known[sha256(data)] = "from before the install of " + when
    entries = "".join(
        '    ("{}", "{}", 0o{:o}, (\n{}\n    )),\n'.format(name, sha256(data), mode, b64_literal(data, "        "))
        for name, mode, data in saved)
    words = {
        "SUMMARY": "put the probing macros back as they were before the install of " + when + ".",
        "ORIGIN": "Written by the install script ({}) on {}, with the files it was about to replace\n"
                  "or remove. Kept in {}.".format(MACRO_SET, when, backup_dir),
        "RESTORE_STEP": "  3. (a restore script does not write a restore script)\n",
        "NAME": "Restore probing macros from before " + when,
        "LOG_PREFIX": "probing_macros_restore",
        "ACTION": "put the probing macros back as they were before " + when,
        "SET_NAME": "copies saved before the install of " + when,
        "SET_LABEL": "macros from before the install of " + when,
        "LOG_TITLE": "Restoring CAM driven probing macros",
        "COUNT": str(len(saved)),
        "REMOVE": repr(sorted(added)),
        "REMOVE_TEXT": ", ".join(sorted(added)) or "nothing",
        "KNOWN": "".join('    "{}": "{}",\n'.format(h, label) for h, label in sorted(known.items())),
    }
    for key, value in words.items():
        template = template.replace("@" + key + "@", value)
    # last, so nothing is ever substituted into file contents
    template = template.replace("@" + "MACROS" + "@", entries)
    template = template.replace("@" + "TEMPLATE_B64" + "@", '    ""')
    return template


class ProbingMacroInstaller(object):

    def __init__(self):
        self.stat = None
        self.lines = []
        self.restore_path = None
        # PathPilot shows "Diagnostic <diagnostic_status> ... Results are saved in <output_file>"
        self.result_dict = {"diagnostic_status": "failed"}

    def log(self, msg):
        line = "{} | {}".format(time.strftime("%Y-%m-%d_%H-%M-%S"), msg)
        self.lines.append(line)
        sys.stderr.write(line + "\n")  # stderr ends up in the PathPilot log; stdout is for the result
        sys.stderr.flush()

    def run(self):
        try:
            self.stat = linuxcnc.stat()
            if self.apply():
                self.log("Complete")
                self.result_dict["diagnostic_status"] = "complete"
        except Exception:
            self.log("Failed: " + traceback.format_exc())
        finally:
            self.save_log()

    def save_log(self):
        folder = LOG_DIR if os.path.isdir(LOG_DIR) else BACKUP_PARENT
        path = os.path.join(folder, "{}_{}.txt".format(log_file_prefix, time.strftime("%Y%m%d_%H%M%S")))
        try:
            write_bytes(path, to_bytes("\n".join(self.lines) + "\n"))
        except Exception as e:
            sys.stderr.write("could not save the log to {}: {}\n".format(path, e))
            path = "the PathPilot log (could not write {})".format(path)
        if self.restore_path:
            path += "\nRestore script: " + self.restore_path
        self.result_dict["output_file"] = path

    def on_exit(self):
        # The only output on stdout: PathPilot parses it as JSON
        sys.stdout.write(json.dumps(self.result_dict) + "\n")
        sys.stdout.flush()

    def apply(self):
        self.log("@LOG_TITLE@: " + MACRO_SET)

        # 1. never replace macros while a program is running
        self.stat.poll()
        if self.stat.interp_state != linuxcnc.INTERP_IDLE:
            self.log("Failed: a program is running - stop it and run this script again")
            return False

        # 2. check the embedded copies and the target folder before touching anything
        files = []
        for name, digest, mode, b64 in MACROS:
            data = base64.b64decode(b64)
            if sha256(data) != digest:
                self.log("Failed: embedded copy of {} is damaged - nothing was changed".format(name))
                return False
            files.append((name, digest, mode, data))
        if not os.path.isdir(TARGET_DIR):
            self.log("Failed: {} not found - nothing was changed".format(TARGET_DIR))
            return False
        if not os.access(TARGET_DIR, os.W_OK):
            self.log("Failed: {} is read-only - nothing was changed".format(TARGET_DIR))
            return False
        target = os.path.realpath(TARGET_DIR)
        if target != os.path.abspath(TARGET_DIR):
            self.log("{} is {}".format(TARGET_DIR, target))

        # 3. what changes
        writes = []      # (name, digest, mode, data, version replaced or None if new)
        unchanged = []
        for name, digest, mode, data in files:
            path = os.path.join(TARGET_DIR, name)
            if not os.path.isfile(path):
                writes.append((name, digest, mode, data, None))
            elif sha256(read_bytes(path)) == digest:
                unchanged.append(name)
            else:
                writes.append((name, digest, mode, data, version_of(path)))
        removes = [(name, version_of(os.path.join(TARGET_DIR, name)))
                   for name in REMOVE if os.path.isfile(os.path.join(TARGET_DIR, name))]

        backup_dir = None
        if writes or removes:
            # 4. copy everything that will be replaced or removed, as it is now
            stamp = time.strftime("%Y%m%d_%H%M%S")
            backup_dir = new_backup_dir(stamp)
            os.makedirs(backup_dir)
            saved = []   # (name, mode, bytes)
            for name in [w[0] for w in writes if w[4]] + [r[0] for r in removes]:
                source = os.path.join(TARGET_DIR, name)
                data = read_bytes(source)
                shutil.copy2(source, os.path.join(backup_dir, name))
                if read_bytes(os.path.join(backup_dir, name)) != data:
                    self.log("Failed: could not back up {} - nothing was changed".format(name))
                    return False
                saved.append((name, os.stat(source).st_mode & 0o777, data))

            # 5. the install writes the script that undoes this run, before it changes anything
            if TEMPLATE_B64:
                path = os.path.join(backup_dir, RESTORE_NAME)
                text = restore_script(stamp, backup_dir, saved, [w[0] for w in writes if not w[4]])
                try:
                    compile(text, path, "exec")
                    write_bytes(path, to_bytes(text))
                    os.chmod(path, 0o755)
                    ok = read_bytes(path) == to_bytes(text)
                except Exception as e:
                    self.log("could not write {}: {}".format(path, e))
                    ok = False
                if not ok:
                    self.log("Failed: could not write the restore script - nothing was changed")
                    return False
                self.restore_path = path

            # 6. write each file through a temporary name, then rename it into place
            for name, digest, mode, data, old in writes:
                path = os.path.join(TARGET_DIR, name)
                if mode is None:
                    mode = (os.stat(path).st_mode & 0o777) if old else 0o644
                temp = path + ".tsd_tmp"
                write_bytes(temp, data)
                os.chmod(temp, mode)
                os.rename(temp, path)
            for name, old in removes:
                os.remove(os.path.join(TARGET_DIR, name))

        # 7. verify the result
        bad = [name for name, digest, mode, data in files
               if not os.path.isfile(os.path.join(TARGET_DIR, name)) or
               sha256(read_bytes(os.path.join(TARGET_DIR, name))) != digest]
        bad += [name for name in REMOVE if os.path.exists(os.path.join(TARGET_DIR, name))]

        # 8. which copy will PathPilot use?
        warnings = []
        try:
            dirs = subroutine_path()
            if target not in dirs:
                warnings.append("{} is not in SUBROUTINE_PATH ({}) - PathPilot will not find these macros".format(
                    TARGET_DIR, ":".join(dirs)))
            else:
                earlier = dirs[:dirs.index(target)]
                for name, digest, mode, data in files:
                    for d in earlier:
                        if os.path.isfile(os.path.join(d, name)):
                            warnings.append("PathPilot will use {} instead of {} in {}".format(
                                os.path.join(d, name), name, TARGET_DIR))
                            break
        except Exception as e:
            warnings.append("could not read SUBROUTINE_PATH ({}) - check that {} is searched".format(e, TARGET_DIR))

        # 9. report
        self.log("{}: {} written, {} already up to date, {} removed".format(
            TARGET_DIR, len(writes), len(unchanged), len(removes)))
        for name, digest, mode, data, old in writes:
            if old:
                self.log("  replaced {} ({})".format(name, old))
            else:
                self.log("  added {}".format(name))
        for name, old in removes:
            self.log("  removed {} ({})".format(name, old))
        if backup_dir:
            self.log("Previous copies saved in {}".format(backup_dir))
        if self.restore_path:
            self.log("To undo this run, load {} from the File tab".format(self.restore_path))
        elif TEMPLATE_B64 and not backup_dir:
            self.log("Nothing changed, so no restore script was written")
        for w in warnings:
            self.log("WARNING: " + w)
        if bad:
            self.log("Failed: these files did not verify: {}".format(", ".join(bad)))
            return False
        return True


if __name__ == '__main__':
    tester = ProbingMacroInstaller()
    try:
        tester.run()
    finally:
        tester.on_exit()
'''


def git(*args):
    return subprocess.check_output(['git', '-C', ROOT] + list(args))


def repo_set():
    names = sorted(f for f in os.listdir(ROOT) if f.startswith('probe_') and f.endswith('.nc'))
    out = {}
    for n in names:
        with open(os.path.join(ROOT, n), 'rb') as f:
            out[n] = f.read()
    return out


def commit_set(commit):
    names = git('ls-tree', '--name-only', commit).decode().splitlines()
    names = sorted(n for n in names if n.startswith('probe_') and n.endswith('.nc'))
    return {n: git('show', '%s:%s' % (commit, n)) for n in names}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def b64_literal(data, indent):
    text = base64.b64encode(data).decode('ascii')
    if not text:
        return indent + '""'
    return '\n'.join('%s"%s"' % (indent, text[i:i + 76]) for i in range(0, len(text), 76))


def repo_label():
    """Last commit that changed a macro, marked if the working copy differs from it."""
    try:
        commit = git('log', '-1', '--format=%h', '--', 'probe_*.nc').decode().strip()
        dirty = git('status', '--porcelain', '--', 'probe_*.nc').decode().strip()
        return commit + ('+uncommitted' if dirty else '')
    except Exception:
        return 'unknown'


def main():
    TEMPLATE.encode('ascii')  # the install compiles the restore from it under Python 2 as well
    new = repo_set()
    original = commit_set(ORIGINAL_COMMIT)
    label = repo_label()
    # labels for the log; a file that is the same in both sets counts as baseline
    known = {digest(d): 'new version %s' % label for d in new.values()}
    known.update({digest(d): 'baseline %s' % ORIGINAL_COMMIT for d in original.values()})
    remove = sorted(set(original) - set(new))

    entries = ''.join('    ("%s", "%s", None, (\n%s\n    )),\n' % (n, digest(new[n]), b64_literal(new[n], '        '))
                      for n in sorted(new))
    words = dict(
        SUMMARY='install the new CAM driven probing macros into ~/tmc/subroutines.',
        ORIGIN='Generated by tools/build_tsd.py from footpetaljones/PP-Probing-Macros (new macros, commit %s).\n'
               'Do not edit by hand: change the macros in the repo and rebuild.' % label,
        RESTORE_STEP='  3. Writes restore_probing_macros.tsd into that folder: it puts back the files this run\n'
                     '     replaces or removes and deletes the ones it adds.\n',
        NAME='Install new CAM driven probing macros (%s)' % label,
        LOG_PREFIX='probing_macros_install',
        ACTION='install the new CAM driven probing macros',
        SET_NAME='new version',
        SET_LABEL='new macros, commit %s' % label,
        LOG_TITLE='Installing CAM driven probing macros',
        COUNT=str(len(new)),
        REMOVE=repr(remove),
        REMOVE_TEXT=', '.join(remove) or 'nothing',
        KNOWN=''.join('    "%s": "%s",\n' % (h, lab) for h, lab in sorted(known.items())),
    )
    script = TEMPLATE
    for key, value in words.items():
        script = script.replace('@%s@' % key, value)
    script = script.replace('@MACROS@', entries)
    script = script.replace('@TEMPLATE_B64@', b64_literal(TEMPLATE.encode('utf-8'), '    '))
    unfilled = sorted(set(re.findall(r'@[A-Z_0-9]+@', script)))
    if unfilled:
        raise SystemExit('unfilled placeholder: %s' % ', '.join(unfilled))

    os.makedirs(TSD_DIR, exist_ok=True)
    path = os.path.join(TSD_DIR, 'install_probing_macros.tsd')
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(script)
    os.chmod(path, 0o755)  # PathPilot also chmods +x before running a .tsd
    old = os.path.join(TSD_DIR, 'restore_original_probing_macros.tsd')
    if os.path.exists(old):
        os.remove(old)  # replaced by the restore script each install writes
    print('wrote tsd/install_probing_macros.tsd: %d macros, removes %s' % (len(new), ', '.join(remove) or 'nothing'))


if __name__ == '__main__':
    main()
