#!/usr/bin/env python3
"""Minimal simulator for the PathPilot probing macros.

Interprets the G-code subset the macros use (parameters, [ ] expressions,
o-word if/else, G90/G91, G1, G38.2/G38.6, polar @ ^, G54.1 P, G10 L20, M19, M0)
against a modeled workpiece, and records every move and offset write.
Used to compare macro revisions and to check the geometry of the results.

It is a test aid, not LinuxCNC: PathPilot behavior is modeled as follows.
  - G38.2 stops `OVERTRAVEL` past the trip point; #5061-#5063 hold the trip point
    and #5420-#5422 the stopped position (both in the active WCS).
  - G38.6 moves without watching the probe (the model still reports collisions).
  - U_INCH[x] returns x (inch program).
  - G10 L20 Pn sets WCS n so the current position reads the given value.
"""
import math
import re

OVERTRAVEL = 0.0004  # stop distance past trip (in), deliberately non-zero
TIP_DIA = 0.1000


class GcodeError(Exception):
    pass


# ---------------------------------------------------------------- expressions
FUNCS1 = {
    'ABS': abs, 'SQRT': math.sqrt, 'FIX': math.floor, 'FUP': math.ceil,
    'ROUND': lambda v: float(round(v)), 'LN': math.log, 'EXP': math.exp,
    'SIN': lambda v: math.sin(math.radians(v)), 'COS': lambda v: math.cos(math.radians(v)),
    'TAN': lambda v: math.tan(math.radians(v)), 'ASIN': lambda v: math.degrees(math.asin(v)),
    'ACOS': lambda v: math.degrees(math.acos(v)), 'U_INCH': lambda v: v,
}
BINOPS = [
    {'OR': lambda a, b: float(bool(a) or bool(b)), 'XOR': lambda a, b: float(bool(a) != bool(b)),
     'AND': lambda a, b: float(bool(a) and bool(b))},
    {'EQ': lambda a, b: float(a == b), 'NE': lambda a, b: float(a != b), 'GT': lambda a, b: float(a > b),
     'GE': lambda a, b: float(a >= b), 'LT': lambda a, b: float(a < b), 'LE': lambda a, b: float(a <= b)},
    {'+': lambda a, b: a + b, '-': lambda a, b: a - b},
    {'*': lambda a, b: a * b, '/': lambda a, b: a / b, 'MOD': lambda a, b: math.fmod(a, b) % abs(b)},
    {'**': lambda a, b: a ** b},
]


class Reader:
    def __init__(self, text, interp):
        self.s, self.i, self.it = text, 0, interp

    def ws(self):
        while self.i < len(self.s) and self.s[self.i] in ' \t':
            self.i += 1

    def peek(self):
        self.ws()
        return self.s[self.i] if self.i < len(self.s) else ''

    def value(self):
        """A real value: number, parameter, function or [expression]."""
        c = self.peek()
        if c == '[':
            self.i += 1
            v = self.expr(0)
            if self.peek() != ']':
                raise GcodeError('missing ] in %r' % self.s)
            self.i += 1
            return v
        if c == '#':
            return self.it.get_param(self.param_ref())
        if c in '+-':
            self.i += 1
            v = self.value()
            return -v if c == '-' else v
        m = re.match(r'[A-Za-z_]+', self.s[self.i:])
        if m and m.group(0).upper() in FUNCS1 | {'ATAN': 0, 'EXISTS': 0}:
            name = m.group(0).upper()
            self.i += len(m.group(0))
            if name == 'EXISTS':
                self.ws()
                if self.s[self.i] != '[':
                    raise GcodeError('EXISTS needs [')
                self.i += 1
                ref = self.param_ref()
                self.ws()
                self.i += 1  # ]
                return float(self.it.exists(ref))
            arg = self.value()
            if name == 'ATAN':
                if self.peek() != '/':
                    raise GcodeError('ATAN needs [y]/[x]')
                self.i += 1
                return math.degrees(math.atan2(arg, self.value()))
            return FUNCS1[name](arg)
        m = re.match(r'\d*\.?\d+|\d+\.', self.s[self.i:])
        if not m:
            raise GcodeError('bad value at %r' % self.s[self.i:])
        self.i += len(m.group(0))
        return float(m.group(0))

    def param_ref(self):
        assert self.s[self.i] == '#'
        self.i += 1
        if self.s[self.i] == '<':
            j = self.s.index('>', self.i)
            name = self.s[self.i + 1:j].lower()
            self.i = j + 1
            return name
        if self.s[self.i] == '[':
            return int(round(self.value()))
        m = re.match(r'\d+', self.s[self.i:])
        if not m:
            raise GcodeError('bad parameter at %r' % self.s)
        self.i += len(m.group(0))
        return int(m.group(0))

    def op(self, level):
        self.ws()
        rest = self.s[self.i:]
        for name in sorted(BINOPS[level], key=len, reverse=True):
            if rest.upper().startswith(name):
                if name == '*' and rest.startswith('**'):
                    continue
                return name
        return None

    def expr(self, level):
        if level == len(BINOPS):
            return self.value()
        left = self.expr(level + 1)
        while True:
            name = self.op(level)
            if not name:
                return left
            self.i += len(name)
            left = BINOPS[level][name](left, self.expr(level + 1))


# ---------------------------------------------------------------- workpiece models
class Feature:
    """A feature only defines penetration(p, r): how far the probe ball of radius r
    centered at p is inside material (> 0 means inside). Contact is found numerically."""
    ztop = 1e9

    def depth(self, p, r):
        raise NotImplementedError

    def penetration(self, p, r):
        return self.depth(p, r) if p[2] <= self.ztop else -1.0

    def contact(self, p0, p1, r, steps=4000):
        if self.penetration(p0, r) > 1e-12:
            return None
        prev = 0.0
        for k in range(1, steps + 1):
            t = k / steps
            p = [p0[j] + t * (p1[j] - p0[j]) for j in range(3)]
            if self.penetration(p, r) > 0:
                lo, hi = prev, t
                for _ in range(80):
                    mid = (lo + hi) / 2
                    pm = [p0[j] + mid * (p1[j] - p0[j]) for j in range(3)]
                    if self.penetration(pm, r) > 0:
                        hi = mid
                    else:
                        lo = mid
                return hi
            prev = t
        return None


class World:
    def __init__(self, features):
        self.features = features

    def first_contact(self, p0, p1, r):
        hits = [t for t in (f.contact(p0, p1, r) for f in self.features) if t is not None]
        return min(hits) if hits else None

    def penetration(self, p, r):
        return max([f.penetration(p, r) for f in self.features] + [0.0])


class Slab(Feature):
    """Material between lo and hi on one axis (a boss/web); inverted=True gives a
    pocket/slot (material outside lo..hi)."""

    def __init__(self, axis, lo, hi, inverted=False, ztop=1e9):
        self.k, self.lo, self.hi, self.inv, self.ztop = 'XYZ'.index(axis), lo, hi, inverted, ztop

    def depth(self, p, r):
        x = p[self.k]
        if self.inv:
            return max(self.lo - (x - r), (x + r) - self.hi)
        return min((x + r) - self.lo, self.hi - (x - r))


class Wall(Slab):
    """Half-space: material on the + side of `at` (side=+1) or the - side (side=-1)."""

    def __init__(self, axis, at, side, ztop=1e9):
        big = 1e6
        lo, hi = (at, at + big) if side > 0 else (at - big, at)
        Slab.__init__(self, axis, lo, hi, False, ztop)


class Box(Feature):
    """Rectangular block in XY (material inside), top at ztop. Depth uses the
    smallest face overlap, which is exact for face-normal touches."""

    def __init__(self, xlo, xhi, ylo, yhi, ztop=1e9):
        self.b, self.ztop = (xlo, xhi, ylo, yhi), ztop

    def depth(self, p, r):
        xlo, xhi, ylo, yhi = self.b
        return min(p[0] + r - xlo, xhi - (p[0] - r), p[1] + r - ylo, yhi - (p[1] - r))


class Cylinder(Feature):
    """inside=True: a bore (material outside the radius); False: a boss."""

    def __init__(self, cx, cy, radius, inside, ztop=1e9):
        self.c, self.R, self.inside, self.ztop = (cx, cy), radius, inside, ztop

    def depth(self, p, r):
        d = math.hypot(p[0] - self.c[0], p[1] - self.c[1])
        return (d + r - self.R) if self.inside else (self.R + r - d)


class Floor(Feature):
    """Top face at z. For Z probing the tool length offset puts the controlled
    point at the bottom of the ball, so the tip radius is not applied here."""

    def __init__(self, z):
        self.z = z

    def penetration(self, p, r):
        return self.z - p[2]


# ---------------------------------------------------------------- interpreter
class Interp:
    def __init__(self, world, offsets, active, start, params=None, tip_dia=TIP_DIA,
                 overtravel=OVERTRAVEL, wireless=0, pause_answer='resume'):
        self.world = world
        self.off = {k: list(v) for k, v in offsets.items()}
        self.active = active
        self.M = list(start)  # machine position of the probe center
        self.params = {}
        self.named = {k.lower(): v for k, v in (params or {}).items()}
        self.tip = tip_dia
        self.overtravel = overtravel
        self.absolute = True
        self.feed = 0.0
        self.trace = []
        self.messages = []
        self.collisions = []
        self.trip = [0.0, 0.0, 0.0]
        self.spindle = None
        self.named.setdefault('_probe_wireless', float(wireless))
        self.pause_answer = pause_answer
        self.paused = False

    # parameters
    def wpos(self):
        o = self.off.get(self.active, [0.0, 0.0, 0.0])
        return [self.M[k] - o[k] for k in range(3)]

    def get_param(self, ref):
        if isinstance(ref, str):
            if ref not in self.named:
                raise GcodeError('named parameter #<%s> not defined' % ref)
            return self.named[ref]
        if ref in (5420, 5421, 5422):
            return self.wpos()[ref - 5420]
        if ref in (5061, 5062, 5063):
            return self.trip[ref - 5061]
        if ref == 5220:
            return float(self.active)
        if ref == 5410:
            return self.tip
        if ref == 5400:
            return 99.0
        return self.params.get(ref, 0.0)

    def set_param(self, ref, v):
        if isinstance(ref, str):
            self.named[ref] = v
        else:
            self.params[ref] = v

    def exists(self, ref):
        return ref in self.named if isinstance(ref, str) else True

    # motion
    def _check_path(self, p0, p1, kind):
        r = self.tip / 2
        for k in range(1, 201):
            t = k / 200
            p = [p0[j] + t * (p1[j] - p0[j]) for j in range(3)]
            depth = self.world.penetration(p, r)
            if depth > self.overtravel + 1e-6:
                self.collisions.append((kind, [round(c, 4) for c in p], round(depth, 4)))
                return

    def move(self, target_w, kind):
        o = self.off.get(self.active, [0.0, 0.0, 0.0])
        tgt = [target_w[k] + o[k] for k in range(3)]
        p0 = list(self.M)
        if kind == 'G38.2':
            r = self.tip / 2
            if self.world.penetration(p0, r) > 1e-9:
                raise GcodeError('G38.2 started with the probe already tripped')
            t = self.world.first_contact(p0, tgt, r)
            if t is None:
                raise GcodeError('G38.2 move finished without making contact')
            d = [tgt[k] - p0[k] for k in range(3)]
            L = math.sqrt(sum(c * c for c in d))
            hit = [p0[k] + t * d[k] for k in range(3)]
            self.trip = [hit[k] - o[k] for k in range(3)]
            stop = [hit[k] + self.overtravel * d[k] / L for k in range(3)]
            self.M = stop
            self.trace.append(('G38.2', tuple(round(c, 9) for c in self.M)))
            return
        self._check_path(p0, tgt, kind)
        self.M = tgt
        self.trace.append((kind, tuple(round(c, 9) for c in self.M)))

    # execution
    def run(self, path):
        lines = open(path, encoding='utf-8').read().split('\n')
        # skip-state stack for o-if
        stack = []
        active = True
        for n, raw in enumerate(lines, 1):
            try:
                active = self._line(raw, stack, active)
            except GcodeError as e:
                raise GcodeError('%s:%d: %s  [%s]' % (path, n, e, raw.strip()))
            if active == 'END':
                break
        return self

    def _comments(self, raw):
        code, comments, depth, buf = [], [], 0, []
        for ch in raw:
            if ch == '(' and not depth:
                depth, buf = 1, []
            elif ch == ')' and depth:
                depth = 0
                comments.append(''.join(buf))
            elif depth:
                buf.append(ch)
            else:
                code.append(ch)
        return ''.join(code).split(';')[0], comments

    def _subst(self, text):
        def rep(m):
            v = self.get_param(m.group(1).lower())
            return '%.6f' % v
        text = re.sub(r'#<([A-Za-z0-9_]+)>', rep, text)
        return re.sub(r'#(\d+)', lambda m: '%.6f' % self.get_param(int(m.group(1))), text)

    def _line(self, raw, stack, active):
        code, comments = self._comments(raw)
        code = code.strip()
        m = re.match(r'o(<[^>]+>|\d+)\s+(\w+)\s*(.*)$', code, re.I)
        if m:
            kw = m.group(2).lower()
            if kw in ('sub', 'endsub', 'call', 'return'):
                if kw == 'endsub' and active:
                    return 'END'
                if kw == 'return' and active:
                    return 'END'
                return active
            if kw == 'if':
                cond = active and bool(Reader(m.group(3), self).value())
                stack.append((active, cond, cond))
                return cond
            if kw == 'elseif':
                parent, taken, _ = stack[-1]
                cond = parent and not taken and bool(Reader(m.group(3), self).value())
                stack[-1] = (parent, taken or cond, cond)
                return cond
            if kw == 'else':
                parent, taken, _ = stack[-1]
                stack[-1] = (parent, True, parent and not taken)
                return parent and not taken
            if kw == 'endif':
                parent, _, _ = stack.pop()
                return parent
            raise GcodeError('unsupported o-word %s' % kw)
        if not active:
            return active
        for c in comments:
            cm = re.match(r'\s*(DEBUG|PRINT|ABORT|MSG|LOG|LOGAPPEND|LOGOPEN|LOGCLOSE)\s*,?(.*)$', c, re.I)
            if cm:
                kind = cm.group(1).upper()
                text = self._subst(cm.group(2)) if kind in ('DEBUG', 'PRINT', 'ABORT', 'LOG') else cm.group(2)
                self.messages.append((kind, text.strip()))
                if kind == 'ABORT':
                    raise GcodeError('ABORT: ' + text.strip())
        if not code:
            return active
        am = re.match(r'(#<[A-Za-z0-9_]+>|#\d+)\s*=\s*(.*)$', code)
        if am:
            r = Reader(am.group(1), self)
            r.i = 0
            ref = r.param_ref()
            self.set_param(ref, Reader(am.group(2), self).value())
            return active
        self._words(code)
        return active

    def _words(self, code):
        rd = Reader(code, self)
        words = []
        while True:
            c = rd.peek()
            if not c:
                break
            if not (c.isalpha() or c in '@^'):
                raise GcodeError('unexpected %r' % code[rd.i:])
            rd.i += 1
            words.append((c.upper(), rd.value()))
        gs = [v for k, v in words if k == 'G']
        ms = [v for k, v in words if k == 'M']
        w = {k: v for k, v in words if k not in 'GM'}
        if 'F' in w:
            self.feed = w['F']
        for g in gs:
            if abs(g - 90) < 1e-9:
                self.absolute = True
            elif abs(g - 91) < 1e-9:
                self.absolute = False
        for mcode in ms:
            if mcode == 19:
                if 'R' not in w or 'Q' not in w:
                    raise GcodeError('M19 needs R and Q')
                self.spindle = w['R'] % 360
                self.trace.append(('M19', round(self.spindle, 6)))
            elif mcode in (0, 1):
                self.trace.append(('M0',))
                if self.pause_answer == 'abort':
                    raise GcodeError('operator stopped at M0')
            elif mcode == 66:
                pass
            else:
                raise GcodeError('unsupported M%g' % mcode)
        motion = None
        for g in gs:
            if g in (0, 1, 38.2, 38.6):
                motion = g
            elif abs(g - 54.1) < 1e-9:
                self.active = int(round(w['P']))
                self.off.setdefault(self.active, [0.0, 0.0, 0.0])
                self.trace.append(('G54.1', self.active))
                return
            elif g == 10:
                if int(w.get('L', 0)) != 20:
                    raise GcodeError('only G10 L20 modeled')
                n = int(round(w['P']))
                self.off.setdefault(n, [0.0, 0.0, 0.0])
                for k, ax in enumerate('XYZ'):
                    if ax in w:
                        self.off[n][k] = self.M[k] - w[ax]
                        self.trace.append(('G10', n, ax, round(self.off[n][k], 9)))
                return
            elif g == 30:
                self.trace.append(('G30', tuple(sorted(a for a in 'XYZ' if a in w))))
                self.M[2] = 10.0  # model G30 Z as a high retract
                if not [a for a in 'XYZ' if a in w]:
                    self.M[0], self.M[1] = -5.0, -5.0
                return
            elif g not in (90, 91, 20, 21, 40, 49, 80, 17, 94):
                raise GcodeError('unsupported G%g' % g)
        if motion is None and any(a in w for a in 'XYZ@^'):
            raise GcodeError('axis words without motion mode (modal motion not modeled)')
        if motion is None:
            return
        cur = self.wpos()
        tgt = list(cur)
        if '@' in w or '^' in w:
            r0, a0 = math.hypot(cur[0], cur[1]), math.degrees(math.atan2(cur[1], cur[0]))
            if self.absolute:
                r = w.get('@', r0)
                a = w.get('^', a0)
            else:
                r = r0 + w.get('@', 0.0)
                a = a0 + w.get('^', 0.0)
            tgt[0], tgt[1] = r * math.cos(math.radians(a)), r * math.sin(math.radians(a))
        for k, ax in enumerate('XYZ'):
            if ax in w:
                tgt[k] = w[ax] if self.absolute else cur[k] + w[ax]
        if self.feed <= 0:
            raise GcodeError('feed rate is zero')
        self.move(tgt, {0: 'G0', 1: 'G1', 38.2: 'G38.2', 38.6: 'G38.6'}[motion])
