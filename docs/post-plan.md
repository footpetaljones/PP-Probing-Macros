# tormach-probing-v2 post: plan

Status: **§4 steps 1–9 implemented in `1369ca5`; posted from Fusion with the test part on 2026-11-23 and checked by hand (see `docs/test-part.md`). Tool wear output not yet posted.** Decisions of 2026-11-23 in §5. Test with the probing test part (§6). `post/tormach-probing-v2.cps` is the stock Tormach PathPilot post
(revision 44229, 2026-06-12) with only the description changed (commit e68dca1).

## 1. What the stock post does for probing

- Fusion probing cycles go to `writeProbeCycle()`, which writes the required inputs
  (`_first_position_to_probe`, `_second_*`, `_diameter_to_*`, `_z_clearance_position`, `_x/_y/_z_wcs_offset`,
  `_first/_second/_third_vector`, `_measuring_wcs`) and calls the matching macro. The macro names are unchanged
  in v2, so those calls keep working.
- Probe tool must be T99 / H99 (validated).
- WCS probing only: geometry probing stops posting ("Geometry probing is not supported by the CNC control").
- None of the Fusion **Actions** tab settings are used (print results, tolerances, tool wear).
- X/Y plane angle cycles are rejected.

## 2. AudacityMicro post (Tormach_Inspection.cps, based on stock revision 44167)

| Area | What it does | For v2 |
|---|---|---|
| Results | Fusion-importable `RESULTS.TXT`: the post writes `START`, `RESULTSFILE`, `DOCUMENTID`, `MODELVERSION`, `TIMESTAMP`, and per toolpath `TOOLPATHID`, `TOOLPATH`, `G331` (CAD transform), `G330` (work plane), `CYCLEDEPTH`, component/feature header; the macros write `SIZE` / `POSN` lines; `END` at batch end. Enabled by Fusion's **Print results**. | Later, as its own step (decision 2). |
| Batch | Results file persists across programs (component counter); a post property closes the batch with `END`. MDI reset needed after an abort. | With the Fusion format, later. |
| Nominal size | `#<_FeatureLength>` / `#<_FeatureWidth>` from `cycle.width1/2`. | Same idea, as `_nominal_size`. |
| WCS change | `_dont_change_WCS` by manual passthrough. | Ours: `_set_wcs`, set from geometry probing. |
| Tolerances / tool wear | Not used. | Planned (§3). |
| Geometry probing | Still an error. | Planned (§3). |
| Inner corner | Expected corner = start + (clearance + **r**); stock uses **2r**. | Planned fix (§4). |
| Other | Program-end washdown / unload position / final tool change; tool-break-check lists; `forceDecimal` formats. | Not probing; left out unless wanted. |

## 3. Fusion → macro mapping

Fusion cycle fields (same names as Autodesk's Renishaw mapping: `getProbingArguments` in the Fanuc and Centroid posts).

| Fusion | `cycle.` field | Macro input |
|---|---|---|
| WCS probing (`operation-strategy` = `probe`) | `currentSection.probeWorkOffset` | `_measuring_wcs` (as now); `_set_wcs` left at default 1 |
| Geometry probing (`probe_geometry`) | `currentSection.workOffset` (0 → 1) | `_set_wcs = 0`, `_measuring_wcs` = active WCS; `_x/_y/_z_wcs_offset` = expected position (inspect only) |
| Feature size | `width1` (`width2` for the Y half of rectangular cycles) | `_nominal_size` on every size feature (size deviation is reported; no check without a tolerance) |
| Wrong size | `wrongSizeAction == "stop-message"`, `toleranceSize` | `_size_tolerance_plus` = `_size_tolerance_minus` = `toleranceSize` (Fusion has Size Upper/Lower and converts an asymmetric band to a symmetric one when posting) |
| Out of position | `outOfPositionAction == "stop-message"`, `tolerancePosition` | `_position_tolerance` (true position zone, same meaning as Renishaw M; macros changed in 961500b). Fusion posts twice the entered value: 0.004 entered → 0.008 |
| Angle askew | `angleAskewAction`, `toleranceAngle` | none (no angle macros) → post warning |
| Update tool wear | `updateToolWear`; `toolDiameterOffset` (XY) / `toolLengthOffset` (Z) | `_update_tool` (offset number = tool number on PathPilot; validated 1–1000, not 99) |
| Error correction % | `toolWearErrorCorrection` | `_update_feedback` = % / 100 |
| Update threshold | `toolWearUpdateThreshold` | `_update_tool_minimum` |
| (no Fusion field) | — | `_update_wcs_minimum` / `_update_wcs_maximum`: not output (decision 3) |
| Print results | `printResults` | `_log_results = 1` (CSV); `_feature_number` = running count in the program |

Post properties (new group **Probing**), written once at program start, only in programs that probe:

| Property | Default | Writes |
|---|---|---|
| Show results on Status tab | Yes | `_display_results` |
| Out-of-tolerance action | Pause (M0) | `_tolerance_action` 1; Abort = 2; Flag only = 0 |
| Orient wireless probe | Yes | `_orient_probe` |
| New results file each program | No | `_log_results = 2` on the first printed feature |

## 4. Changes, in order (one commit each)

1. **Geometry probing → inspect only.** Replace the error in `writeProbeWCS()` with `_set_wcs = 0` and
   `_measuring_wcs` = active WCS.
2. **Size and tolerance inputs** per §3, written just before each macro call.
3. **Tool wear.** Inputs per §3. Track the tools a probe op corrects; after a later tool change to one of
   them, write `o<probe_apply_wear> call` (it already does nothing unless that tool has a pending
   correction). Warn when a diameter-corrected tool's later operations use compensation *In computer*
   (diameter wear only acts through G41/G42).
4. **Print results** → `_log_results`, `_feature_number`.
5. **Probing properties** (§3 table) and a **program-start block** in programs that probe:
   - the property values;
   - `_wear_pending_tool = 0` (drop a correction left by an aborted program);
   - every per-feature input at its default (`_set_wcs = 1`, tolerances 0, …): globals survive between
     programs, and an abort inside a macro skips the clearing at its end. A leftover `_set_wcs = 0` would
     stop the next program's WCS probing from setting the WCS.
6. **Inner corner fix**: expected corner = start + approach·(clearance + r), as in Autodesk's generic posts
   and the AudacityMicro post. The stock 2r assigns the WCS one probe radius off (the macro sets the
   probed wall to `_x/_y_wcs_offset`). Verify on the sim before changing.
7. **Circular hole with island** → `o<probe_circular_bore_island> call` (the stock post feeds Z down at the hole
   center, onto the island). Position above the center at `cycle.retract` only (no feed down), write
   `_first_position_to_probe` = `z - cycle.depth`, `_z_clearance_position` = `cycle.retract`.
   Check the `_diameter_to_*` formulas while there: the stock post mixes radial terms into diameters
   (`width1 - (probeClearance + r)`, `width1 + (probeOvertravel - r)`); a position circle `probeClearance` from the
   wall is `width1 - 2·(probeClearance + r)`.
8. **No-island clearance height**: for channels and holes without an island the stock post writes
   `_z_clearance_position = 0`. The pocket macros retract to it between walls, so with Z0 below the probing
   depth the probe drives down toward Z0 (stopped by the G1 probe protection). The original article says to
   use the probing Z when there is no obstacle → write `z - cycle.depth`.
9. **Angle askew** checked in Fusion → warning that it is not checked.

10. **Probe moves**: Z never moves together with X/Y in probing sections (between the X and Y halves of rectangular
    cycles, after a cycle): Z first going up, X/Y first going down (`2aa01e0`). The macros had no combined moves.

Not changed: existing macro names, T99/H99 check, pattern/mirror checks, plane-angle cycles rejected.

## 5. Decisions

| # | Question | Decision (2026-11-23) |
|---|---|---|
| 1 | Position tolerance per axis or true position | **True position** (Renishaw M). Done in the macros: `_result_tp_dev` = 2·√(dx²+dy²+dz²), status 3 when over `_position_tolerance`; CSV `true_position` column. |
| 2 | Results file | **CSV** now; Fusion-importable `RESULTS.TXT` later as its own step. |
| 3 | Maximum correction | Limits split: `_update_wcs_minimum` / `_update_wcs_maximum` (WCS only) and `_update_tool_minimum` (wear); no wear maximum. The post **does not output the WCS limits**; Fusion's tool wear update threshold → `_update_tool_minimum`. (Renishaw `U`: over it, no tool or work offset update and an alarm; Fusion has no such field.) |
| 4 | Hole with island | **Separate macro** `probe_circular_bore_island` (done, `ffaa42d`); `probe_circular_bore` unchanged. |
| 5 | Protected positioning | **Not needed**: PathPilot treats every G1 with the probe as a protected move. |

Why a separate macro (decision 4):
- The original article's rule (`_diameter_to_position` = 0 means no obstacle) cannot be used: the stock post writes a
  non-zero `_diameter_to_position` and `_z_clearance_position = 0` for every bore and never writes
  `_first_position_to_probe`, so stock-posted programs would take the island path with a stale probing Z.
- A global switch (`#<_island> = 1`) cleared after each call is left set if a program aborts inside the macro; the
  next plain bore call from an older program would then run island moves.
- A call argument (`o<probe_circular_bore> call [1]`) does not persist, but LinuxCNC passes the caller's #1 when no
  argument is given.
- A separate macro (`o<probe_circular_bore_island>`) has none of these problems. Inputs: `_diameter_to_probe`,
  `_diameter_to_position`, `_z_clearance_position`, `_first_position_to_probe` (probing Z) - the set the original
  article listed for a bore with an obstacle, and the same as `probe_circular_boss`. Start above the bore center at
  the clearance height. **Chosen.**

## 6. Testing

- Fusion test setup with one op per cycle type: WCS and geometry probing, tolerances on/off, tool wear on a
  semi-finish/finish pair, print results on/off, an override-driving-WCS op.
- Post it, diff against the stock post's output (only the intended lines change), run the output through
  `tools/sim_macros.py` against modeled parts, then on the 1500MX sim.
