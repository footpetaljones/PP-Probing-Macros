#!/usr/bin/env python3
"""Static checks for the PathPilot probing macros.

Not an interpreter. Catches structural mistakes before a file reaches a machine:
  - o<name> sub / endsub pairing and name match
  - oNNN if / else / endif pairing, else outside an if
  - square bracket balance outside comments
  - comment parentheses balance (no nested parentheses)
  - named locals (#<name> without leading underscore) read before assignment
  - doubled G/M letters (e.g. GG38.6), polar words (@ ^)
  - line length, trailing whitespace, final newline

Usage: python3 tools/check_macros.py [files...]   (default: probe_*.nc)
"""
import glob
import re
import sys

MAX_LINE = 255
ASSIGN_RE = re.compile(r'^\s*#<([A-Za-z0-9_]+)>\s*=')
NAMED_RE = re.compile(r'#<([A-Za-z0-9_]+)>')


def strip_comments(line):
    """Return (code, comments, error) with (...) comments removed."""
    code, comments, depth, buf = [], [], 0, []
    for ch in line:
        if ch == '(':
            if depth:
                return None, None, 'nested parenthesis in comment'
            depth = 1
            buf = []
        elif ch == ')' and depth:
            depth = 0
            comments.append(''.join(buf))
        elif depth:
            buf.append(ch)
        else:
            code.append(ch)
    if depth:
        return None, None, 'unterminated comment'
    code = ''.join(code)
    if ';' in code:
        code = code.split(';', 1)[0]
    return code, comments, None


def check_file(path):
    errors = []
    text = open(path, encoding='utf-8').read()
    if not text.endswith('\n'):
        errors.append((0, 'missing final newline'))
    lines = text.split('\n')
    sub_stack, if_stack = [], []
    assigned = set()
    for n, raw in enumerate(lines, 1):
        if len(raw) > MAX_LINE:
            errors.append((n, 'line longer than %d' % MAX_LINE))
        if raw != raw.rstrip():
            errors.append((n, 'trailing whitespace'))
        code, comments, err = strip_comments(raw)
        if err:
            errors.append((n, err))
            continue
        if code.count('[') != code.count(']'):
            errors.append((n, 'unbalanced [ ]'))
        if re.search(r'\b(GG|MM)\d', code, re.I):
            errors.append((n, 'doubled G/M letter'))
        if re.search(r'[@^]', code):
            errors.append((n, 'polar word (@ or ^)'))
        # parameter substitution inside PRINT/DEBUG/LOG comments
        for c in comments:
            if re.match(r'\s*(PRINT|DEBUG|LOG|ABORT|MSG)\s*,', c, re.I):
                if c.count('#<') != len(NAMED_RE.findall(c)):
                    errors.append((n, 'malformed #<name> in %s comment' % c.split(',')[0].strip()))
                for name in NAMED_RE.findall(c):
                    if not name.startswith('_') and name not in assigned:
                        errors.append((n, 'local #<%s> printed before assignment' % name))
        # o-word structure
        m = re.match(r'^\s*o(<[^>]+>|\d+)\s+(sub|endsub|if|else|elseif|endif|while|endwhile|call|return)\b',
                     code, re.I)
        if m:
            label, kw = m.group(1).lower(), m.group(2).lower()
            if kw == 'sub':
                sub_stack.append(label)
            elif kw == 'endsub':
                if not sub_stack or sub_stack[-1] != label:
                    errors.append((n, 'endsub %s without matching sub' % label))
                else:
                    sub_stack.pop()
            elif kw in ('if', 'while'):
                if_stack.append((label, kw))
            elif kw in ('else', 'elseif'):
                if not if_stack or if_stack[-1] != (label, 'if'):
                    errors.append((n, '%s %s outside its if' % (kw, label)))
            elif kw in ('endif', 'endwhile'):
                want = 'if' if kw == 'endif' else 'while'
                if not if_stack or if_stack[-1] != (label, want):
                    errors.append((n, '%s %s without matching %s' % (kw, label, want)))
                else:
                    if_stack.pop()
        # assignment right-hand side must be one value: number, parameter,
        # function call or bracketed expression (LinuxCNC needs [ ] around math)
        am = ASSIGN_RE.match(code) or re.match(r'^\s*#\d+\s*=', code)
        if am:
            rhs_text = code[am.end():].strip()
            if not re.fullmatch(r'-?[\d.]+|#<\w+>|#\d+|\[.*\]|[A-Za-z_]+\[.*\]', rhs_text):
                errors.append((n, 'assignment needs [ ] around the expression: %s' % rhs_text))
        # named locals: reads before assignment (sequential approximation)
        am = ASSIGN_RE.match(code)
        rhs = code[am.end():] if am else code
        for name in NAMED_RE.findall(rhs):
            if not name.startswith('_') and name not in assigned:
                errors.append((n, 'local #<%s> read before assignment' % name))
        if am:
            assigned.add(am.group(1))
    if sub_stack:
        errors.append((len(lines), 'unclosed sub %s' % sub_stack))
    if if_stack:
        errors.append((len(lines), 'unclosed if/while %s' % if_stack))
    return errors


def main(argv):
    files = argv[1:] or sorted(glob.glob('probe_*.nc'))
    total = 0
    for path in files:
        errs = check_file(path)
        total += len(errs)
        for line, msg in errs:
            print('%s:%d: %s' % (path, line, msg))
    print('%d file(s) checked, %d problem(s)' % (len(files), total))
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
