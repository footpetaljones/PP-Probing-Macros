# CAM Driven Probing — Research Findings and Design Proposal

Status: **in progress.** Branch `macro-update-2026-11`: baseline, style cleanup, three-point fix and
trip-point accuracy are committed (see §7). New features not started.

---

## 1. Three-point macro defect (item 4)

### Root cause
`probe_bore_three_point` and `probe_boss_three_point` position and probe with
polar words (`@` / `^`). In LinuxCNC/PathPilot, polar coordinates are always
referenced to the **XY zero of the active WCS**, not to the current position.
In G91 they are still origin-referenced; `@` and `^` are added to the current
point's radius and angle *about the WCS origin*.

The macros therefore only work when the positioning WCS XY zero is already at
(or very near) the feature center. That is normally true when the positioning
WCS and the measuring WCS are the same and have been set to that bore before,
and normally false when positioning from a different WCS (vise corner, fixture
datum, etc.). That matches the reported symptom.

### What actually happens (bore, positioned from a WCS whose zero is elsewhere)
Simulation: bore Ø1.000 at X3.0 Y2.0 in the positioning WCS, probe Ø0.100,
`_diameter_to_probe` = 1.2, vectors 0/120/240, probe started at the bore center.

| Vector | `G38.2 @1.2 ^v` target | Touch lands at | "Retract" `G91 G38.6 @-r` |
|---|---|---|---|
| 0°   | X+1.200 Y+0.000 | 228° on the bore | drives stylus 0.048" **into** the wall |
| 120° | X−0.600 Y+1.039 | 195° | 0.047" into the wall |
| 240° | X−0.600 Y−1.039 | 220° | 0.050" into the wall |

G38.6 ignores probe input (Tormach G38 reference), so nothing stops the
retract. The following fine `G38.2` then starts with the probe already
tripped and errors. On the boss macro, `G1 @r ^v` sends the probe to a point
around the WCS zero and then feeds Z down there — a crash risk.

### Additional defects in the same two macros
1. `G38.6 X#1 Y#1` (return to start) uses the start **X** for Y. Should be `Y#2`.
   Masked when the start point is X0 Y0, which is the only case that works today.
2. Bore: `G38.2 @#<_diameter_to_probe>` uses the diameter as a radius → 2× overtravel.
3. Center calculation divides by `variable4` = −(P2.y − P1.y). Any vector set
   where touches 1 and 2 share a Y value (e.g. 30/150/270) → divide-by-zero.
4. Boss: `(PRINT, _diameter_to_position is #<_diameter_to_position)` is missing `>`.

### Fix
Compute Cartesian targets from the start point: `X = start_x + R·cos(v)`,
`Y = start_y + R·sin(v)`; retract along `−u(v)`; return with `X#1 Y#2`; solve the
center with the determinant (circumcenter) form and abort cleanly if the three
points are collinear/too close. Same inputs, same outputs, works from any WCS.

---

## 2. Other defects and inconsistencies found in the baseline

| Macro | Finding | Impact |
|---|---|---|
| x/y_pocket, circular_bore/boss, 3-pt | Touches read `#5420/#5421` (position after decel) instead of `#5061/#5062` (trip point). | Width/diameter reads large by 2× overtravel; centers mostly cancel. x/y_boss already use `#5061/#5062` — inconsistent. |
| x/y_edge, xy_corner, z | `G10 L20` executed at the stopped position, not the trip point. | WCS off by the decel overtravel (feed²/2·accel, plus servo lag). Fixable without changing any input parameter. |
| x/y_edge, xy_corner | Leave the **measuring** WCS active on exit; other macros restore the positioning WCS. z uses `G10 L20 P#<_measuring_wcs>` without switching. | Inconsistent caller contract (callers currently re-issue G54). |
| circular_bore | Ignores `_diameter_to_position` / `_z_clearance_position`, but the KB article says it supports obstacles via those parameters. | Article/macro mismatch. |
| circular_boss | Second X positioning move uses rough feed; Y uses rapid feed. | Cosmetic. |
| x_pocket | `G90 (set to incremental mode)` comment. Header says "Probe in y…". | Cosmetic. |
| y_pocket, circular_boss, xy_corner | End PRINT names the wrong macro. | Cosmetic. |
| x/y_boss, xy_corner | `G1` positioning moves without an F word (inherit modal F). | Implicit behavior. |
| several | `M02` after `endsub` in some files only; mixed tabs/4-spaces; `o100 else` indented inside its own block. | Style. |
| KB article | Chart marks `_first_position_to_probe` as required for circular_bore (macro doesn't use it). Three-point boss uses `_first_position_to_probe` as the **Z** probing height; article describes it as X. | Docs. |

---

## 3. Research summary

### PathPilot / LinuxCNC facts the design relies on
- **G38.6** (PathPilot extension): move away from the workpiece, **ignoring probe input**.
- **#5061–#5063**: coordinates at the moment the probe tripped (not where it stopped), in the WCS active at the time.
- **Polar `@ ^`**: referenced to the active WCS XY zero in both G90 and G91.
- **(DEBUG,…)** substitutes parameters and goes to the Status tab; the tab turns yellow but PathPilot does not switch to it. An `M0`/`M1` comment line shows at that line only.
- **(LOGAPPEND,file) / (LOG,…) / (LOGCLOSE)** write text with parameter substitution. The filename is literal (no parameter substitution) and directories are not created.
- **No wear offsets on PathPilot mills.** `G10 L1 P<tool> R<radius>` / `Z<length>` writes the tool table; only words given are changed.
- **M19 R<angle> Q<timeout>** orients the MX spindle (ATC uses `M19 R0 Q10`).
- **Global named parameters** persist across programs until PathPilot restarts. An optional global set by one program **leaks into the next** unless it is cleared.
- `EXISTS[#<_name>]` is available to test whether an optional global was set.

### Tolerance and cut-measure-cut practice
- **Renishaw Inspection Plus** optional inputs: `H` size tolerance, `M` true-position tolerance,
  `U` upper limit (exceeded → no WCS/tool update, stop), `V` null band (no tool update inside),
  `F` feedback fraction 0–1, `T` tool offset to update, `E` experience (bias) value,
  `S` work offset to update, `W` print/log. Outputs `#185–#199` include position, size, errors,
  true-position error, **metal condition**, an out-of-tolerance flag (`#198`) and a probe-error flag (`#199`).
  Two reaction modes: "flag and alarm" (stop, cycle start resumes) or "flag only" for unattended cells.
- **Renishaw AP301 / AP302 (cut-measure-cut / dynamic re-machining):** semi-finish or slave feature →
  measure → if on size continue; if **metal on** (material remains) update tool and re-cut;
  if **metal off** reject/scrap.
- **Heidenhain** inspection cycles return **good / rework / scrap** (Q183) with a reaction setting
  (Q309: 0 don't stop, 1 stop on rework or scrap, 2 stop on scrap only) and write a measuring log.
- **Heidenhain TRACK:** orients the probe to the programmed probe direction before every touch so the
  stylus always deflects the same way; the probe must be recalibrated when TRACK is enabled.

### Why orientation tracking works (and what it requires)
With the spindle angle locked to the probing direction, stylus eccentricity *e* at phase φ contributes
a constant `e·cos φ` along every probing direction. It becomes part of the effective tip radius, so
single-surface (edge) results and centers are both free of run-out, and directional lobing is removed
because the probe is always deflected in the same body direction.
This only holds if the effective tip diameter was **calibrated with the same tracking**. A diameter
calibrated at a fixed orientation will be wrong in tracking mode.

### Comparison repo (AudacityMicro/TormachInspectionMacros)
Already fixed the same 3-pt issues (Cartesian targets, Y#2, determinant center), switched to `#506x`
trip coordinates, adds a `_dont_change_WCS` flag and Fusion-format `RESULTS.TXT` logging via
`LOGAPPEND`. Weaknesses: deviations computed in the positioning WCS but compared to the measuring-WCS
nominal (only valid when the two are the same), and no tolerance/tool feedback logic.

---

## 4. Proposed design

### 4.1 Principles
1. **WCS-setting core unchanged.** Every existing required parameter keeps its meaning; calling programs
   written to the current article keep working with no edits.
2. All new behavior is driven by **optional** globals, tested with `EXISTS[]`, defaulting to today's behavior.
3. Optional inputs are **consumed**: each macro clears them on exit so they can't leak into the next call.
4. Shared logic lives in helper subroutines so the 12 macros stay small:
   - `o<probe_orient> call [direction_deg]` — M19 when wireless + enabled, otherwise no-op.
   - `o<probe_evaluate> call [...]` — deviations, tolerance status, action, tool update, outputs, DEBUG, log.
5. Every move absolute except where an incremental retract is clearer; mode restored to G90 on exit.

### 4.2 Optional inputs (implemented in `probe_result.nc`; 0 = off)

| Parameter | Default | Meaning | Cleared after each call |
|---|---|---|---|
| `#<_set_wcs>` | 1 | 0 = inspect only (measure, evaluate, don't touch the WCS). | yes (back to 1) |
| `#<_display_results>` | 1 | DEBUG summary on the Status tab. | no |
| `#<_log_results>` | 0 | 1 = append a CSV row; 2 = start a new file with a header row (then switches to 1). | no |
| `#<_feature_number>` | 0 | Tag shown in DEBUG and written to the log. | yes |
| `#<_nominal_size>` | 0 | Expected width/diameter (size features). Enables size checks. | yes |
| `#<_size_tolerance_plus>` / `#<_size_tolerance_minus>` | 0 | Size tolerance band (magnitudes). | yes |
| `#<_position_tolerance>` | 0 | ± per-axis position tolerance in the measuring WCS. | yes |
| `#<_update_minimum>` | 0 | Axes whose difference is under this are not updated. | yes |
| `#<_update_maximum>` | 0 | Any difference (position or size) over this: no update, status 4. | yes |
| `#<_tolerance_action>` | 1 | Status > 0: 0 flag only; 1 `G90`, `G30 Z#5422`, `G30`, `M0 (feature out of tolerance)`, cycle start accepts; 2 same retract, log, then ABORT. | no |
| `#<_orient_offset>` | 0 | (orientation step, not built yet) spindle angle K for tracking. | — |

The nominal position is the existing `_x/_y/_z_wcs_offset`: the measured feature position in the measuring WCS
before any update is compared with it. In inspect mode that is the inspection deviation; in set mode it is
the WCS shift, so `_position_tolerance` and `_update_minimum/_maximum` act on the shift.

### 4.3 Outputs (globals, readable after the call)

| Parameter | Meaning |
|---|---|
| `#<_result_x>` `#<_result_y>` `#<_result_z>` | Feature position in the measuring WCS before any update. |
| `#<_result_x_dev>` `_y_dev` `_z_dev` | Measured − nominal. |
| `#<_result_size>` / `#<_result_size_dev>` | Width or diameter / measured − nominal size (0 if no nominal). |
| `#<_result_tp_dev>` | True-position deviation, 2·√(dx²+dy²). |
| `#<_result_status>` | 0 ok, 1 size out – material left (rework), 2 size out – material missing (scrap), 3 position out, 4 over update maximum. Priority 4 > 2 > 3 > 1. |
| `#<_result_size_status>` / `#<_result_position_status>` | Individual flags (0/1/2 and 0/1). |
| `#<_result_wcs_set>` | 1 if any axis of the WCS was updated. |

Existing outputs (`_x_center`, `_y_center`, `_first_x_touch`, …) stay, in positioning-WCS coordinates.
Sizes: pocket/boss width from the two touches ± tip diameter; circular bore/boss diameter from the Y chord
(probed through the X center); three-point diameter from the circumcircle.

### 4.4 Order inside `probe_result`
1. Read optional inputs.
2. Switch to the measuring WCS just long enough to read the translation to it (no motion), switch back.
3. Feature position in the measuring WCS, deviations, size deviation, statuses.
4. DEBUG summary (sent bottom-up because the Status tab lists newest first).
5. Status > 0 and action 1: retract and `M0`; `M66 P0 L0` so nothing below runs before Cycle Start.
   Action 2: retract, skip the update, abort after logging.
6. WCS update unless inspect-only, over maximum or aborting; per axis, skipped under the minimum.
   `G10 L20 P#<_measuring_wcs> X[#5420 + translation − dev]` works from any position, including after the G30 retract.
7. DEBUG line with the WCS outcome; CSV row; clear per-feature inputs; ABORT if action 2.

CSV columns: `epoch,feature,macro,wcs,set_wcs,wcs_updated,status,x_nominal,x,x_dev,y_nominal,y,y_dev,z_nominal,z,z_dev,size_nominal,size,size_dev`
(unused axes are empty; values print with 6 decimals; epoch from `#<_epochtime>`).

### 4.5 Cut-measure-cut (implemented)
Extra inputs on the probing call (cleared after the call):

| Parameter | Default | Meaning |
|---|---|---|
| `#<_update_tool>` | 0 | Tool whose wear is corrected. Size features need `_nominal_size`; `probe_z` uses `_z_wcs_offset` as the face nominal and is then inspect-only for the WCS. |
| `#<_update_feedback>` | 1 | Fraction of the error applied (0 < F ≤ 1). |

`_update_minimum` / `_update_maximum` and the M0 accept step apply to wear the same way as to the WCS.
Corrections: internal size → diameter wear + error·F; external size → diameter wear − error·F; Z face → length wear − error·F.
The correction is stored in inches as pending (`_wear_pending_tool`, `_wear_pending_diameter`, `_wear_pending_length`);
a second correction for the same tool adds to it, one for another tool replaces it with a DEBUG warning.
`o<probe_apply_wear> call` after the tool change reads #5411/#5409 (inches), adds the pending values, writes
`G10 L1 P#5400 I[U_INCH[..]] W[U_INCH[..]]` (program units) and re-issues `G43 H#5400`. If another tool is
loaded it does nothing and keeps the correction.

```
(semi-finish bore with T5, leaving material)
T99 G43 H99 M6
#<_nominal_size> = 0.7450 (semi-finish target)
#<_set_wcs> = 0 (inspect only)
#<_update_tool> = 5
#<_tolerance_action> = 0 (no stop - the program branches)
(position the probe in the bore, then)
o<probe_circular_bore> call
o100 if [#<_result_status> EQ 2]
	(ABORT, bore oversize at semi-finish - scrap)
o100 endif
T5 M6 G43 H5
o<probe_apply_wear> call
(finish bore with cutter compensation)
```

### 4.6 Orientation (implemented)
- `o<probe_orient> call [direction]` runs before every probing direction in every macro (Z touches pass 0).
- Only when `#<_probe_wireless>` is 1 and `#<_orient_probe>` (default 1, persists) is not 0.
- `M19 R[[_orient_offset − direction] MOD 360] Q10`; `_orient_offset` (default 0, persists) is the spindle angle
  that faces the calibrated stylus point toward +X. Spindle angle counts CW from above (M19 R0 → R90 is a
  quarter turn CW), so subtracting the direction keeps the same stylus point facing the probing direction.
- Directions: edges/pockets/bosses ±X = 0/180, ±Y = 90/270; circular bore 0,180,90,270; circular boss probes
  inward (180,0,270,90); three-point bore = vector; three-point boss = vector + 180.
- `machine_tests/orient_test.nc` checks the sign on the machine.
- Probe calibration is done in PathPilot (no calibration macro).

### 4.7 Results file
- `/home/operator/gcode/probe_results.csv` (fixed path; PathPilot's `LOG` filename can't be parameterized).
- One line per feature:
  `epoch, feature_number, macro, measuring_wcs, set_wcs, nominal_x, meas_x, dev_x, …, size_nom, size_meas, size_dev, status, tool, tool_delta`.
- `LOGAPPEND` → `LOG` → `LOGCLOSE` per feature so the file is readable while a program runs.

### 4.8 Display (DEBUG)
One or two lines per feature, e.g.
`(DEBUG, F3 probe_circular_bore G55: X+0.00012 Y-0.00031 D0.74930 dev-0.00070 REWORK)`

### 4.9 Style conventions applied in the cleanup
- Header block per macro: purpose, required inputs, optional inputs, outputs.
- Comments lower-case, consistent wording (`(set absolute mode)` etc.).
- `o`-word numbering by section (100s first touch, 200s second touch, 300s calc, 900s evaluate);
  tab indentation, `else` aligned with `if`.
- Named locals instead of `#1–#4`; tip radius computed once (`#<tip_r> = [U_INCH[#5410]/2]`).
- F on every motion line; rapid feed for clearance moves, rough feed toward the part.
- No `M02` after `endsub`; LF line endings; trailing newline.
- Every macro restores G90 and the positioning WCS on exit.

---

## 5. Suggested additional functionality
1. ~~Probe calibration macros~~ — declined; PathPilot calibration is used.
2. **Clear probe-miss handling** — fast approach with `G38.3`, check `#5070`, then a specific abort
   ("no surface within travel") or flag-only for unattended runs.
3. **Edge skew / WCS rotation** — two touches on one edge → angle → `G10 L2 R`; optional abort if over a limit.
4. **Rectangular boss/pocket in one call** (X and Y), and **angled single surface / angled web**.
5. **Circular bore with obstacle** (implement what the article already describes).
6. **Auto-repeat** for three-point routines (re-probe once from the found center).
7. ~~Bias (experience) value~~ — declined.
8. ~~SPC averaging~~ — declined.
9. **Fusion inspection-results format** option for the log (import into Fusion).
10. **`o<probe_reset>`** helper to clear all optional/pending globals at program start.
11. **Fusion post** that emits these calls, including tolerance and tool-update inputs, from Fusion probing operations.

---

## 6. Decisions (2026-11-22)

| # | Decision |
|---|---|
| Names | Spell out "tolerance": `_size_tolerance_plus/_minus`, `_position_tolerance`, `_tolerance_action`. |
| Tool correction | **Wear offsets, G-code only.** Probe macro stores a pending correction; `o<probe_apply_tool_update>` runs after the tool change, reads #5409/#5411, writes `G10 L1 P W/I`, re-issues G43. |
| Out of tolerance default | Pause: DEBUG with the numbers, `G90`, retract via G30, `M0 (feature out of tolerance)`. |
| Trip point | Approved; done. |
| Retracts | Keep G91/G90 pairs, tidied; done. |
| Log | CSV, one line per feature (Audacity's Fusion format needs a post; revisit with our post). |
| Wireless detect | `#<_probe_wireless>` from stock PathPilot namedparams.py. |
| Three-point | No G52 (see §7); targets computed from the start position (SIN/COS). Close vectors allowed; DEBUG warning under 15° below 3 in / 75 mm diameter, under 5° at or above. |
| TSD scripts | One installs the new set, one restores the original set, both in `~/tmc/subroutines` (back up, write, verify). TSD scripts run under Python 2. |
| Update limits | `_update_minimum` / `_update_maximum` apply to both position and size differences. |
| Bias / SPC | Left out. |
| G30 retract | `G30 Z#5422` moves only Z (verified on the sim). |
| Calibration macro | Not needed: PathPilot's probe calibration is used. |
| M19 capability check | Not needed: only machines with spindle orientation can be set to a wireless probe. |
| KB article | Rewrite after the macros are final. |
| Post | A Fusion post that uses the new inputs comes later. |

## 7. Findings and work since the proposal

### Three-point and G52
LinuxCNC G52 exists but shares the G92 registers (#5210–5219). On PathPilot those are saved in
`emc.var` (present in the 1500MX backup), so an abort mid-cycle would leave a shift on **every** WCS,
across restarts. A scratch WCS leaves itself active (#5220 is saved) and overwrites an offset.
Computing targets from the start position changes nothing until the final `G10 L20`; that is what
the fix does (the Audacity repo does the same — no polar words anywhere).

### Wear offsets (PathPilot 2.14 mill)
- Stored in the tool table `mill_data/tool2.tbl`, not in `emc.var` (which only holds #5161–5390, #5650–5653):
  length wear in the **W** field, diameter wear in the **I** field (`T1 … Z+1.0 W+0.001 I+0.0002`).
- `machine_tests/wear_offset_units.nc` on the 1500MX sim (2026-11-22):
  - #5403 length, #5409 **length wear**, #5410 diameter, #5411 **diameter wear** (loaded tool).
  - Reads are always inches (same numbers in G20 and G21) → wrap with `U_INCH[]`.
  - `G10 L1 P<n> W<> I<>` writes are converted from program units (G21 0.1016/0.1524 → .0040/.0060 in);
    the Offsets tab matched during the M0.
  - Z position changed by exactly the length wear after `G43` → length wear is applied additively by G43.
  - The DEBUG timestamps cannot show whether the interpreter reads past M0 (DEBUG is displayed when executed),
    so the result step keeps an `M66 P0 L0` queue buster after the M0.

### Orientation
`M19 R0` then `M19 R90` turned the spindle a quarter turn CW viewed from above: spindle angle increases CW,
so tracking uses `R = K − θ` (θ = probing direction, CCW from +X; K = optional global, default 0).

### Commits on `macro-update-2026-11`
1. Baseline (macros as supplied).
2. Style cleanup of the 10 single-axis/circular macros — simulated traces identical to baseline.
3. Three-point fix — Cartesian targets, X/Y start return, circumcenter, 20° spacing check, trip coordinates.
4. Trip-point accuracy — all touches from #5061–#5063; edge/corner/Z `G10 L20` corrected for overtravel.
5. Decisions/findings recorded in this doc.
6. Three-point spacing warning; `probe_z_for_position### TSD scripts
- PathPilot's copies are in `~/tmc/subroutines` (Norman); the scripts replace them there. The macros may be missing
  on some machines; they are then added. PathPilot TSD scripts run under Python 2.
- `tools/build_tsd.py` generates both from the repo, each macro embedded with its SHA-256; rebuild and commit
  whenever a macro changes:
  - `tsd/install_probing_macros.py`: every `probe_*.nc` in the repo (16 files); removes `probe_z_for_position.nc`.
  - `tsd/restore_original_probing_macros.py`: the 14 macros of the baseline commit `9fe40cb`; removes
    `probe_result.nc`, `probe_orient.nc`, `probe_apply_wear.nc`.
- On the machine each: refuses while a program runs, if `~/tmc/subroutines` is missing or read-only, or if an
  embedded copy is damaged; copies every file it replaces or removes to
  `~/gcode/probing_macros_backup_<date>_<time>[_n]/` (reachable from the File tab); writes through a temporary
  name and renames, keeping the file mode; verifies every file; logs each file as added / replaced (original,
  new version, or other version) / removed; logs where `~/tmc` points; warns if `SUBROUTINE_PATH` would find
  another copy first or does not include `~/tmc/subroutines`.
- Follows the TSD template (DiagnosticTestBase, start_new_session, log, save_logs, result_dict); no sampler capture.
- `tools/test_tsd.py` runs both against stub PathPilot modules: 40 checks (install, reinstall, restore, round trip,
  backups, shadowing, path forms, refusals). `--python` runs the scripts under another interpreter; no Python 2 was
  available here, so 2.7 compatibility was checked statically (vermin: minimum 2.7 / 3.0).

 `tools/test_tsd.py` runs it against stub PathPilot modules: 19 checks.

### Tools
- `tools/check_macros.py` — static checks (o-word pairing, brackets, malformed parameters, un-bracketed math, `GG`).
- `tools/sim_macros.py`, `tools/test_macros.py` — G-code subset simulator against modeled parts;
  `--compare REV` diffs every move and offset write against another revision.

### probe_z_for_position / probe_level_a_axis
Fixed in commit 6 (typos and syntax that would stop the program; see the commit message).
