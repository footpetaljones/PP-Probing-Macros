# tormach-probing-v2 post: plan

Status: **plan, not started.** `post/tormach-probing-v2.cps` is the stock Tormach PathPilot post
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
| Results | Fusion-importable `RESULTS.TXT`: the post writes `START`, `RESULTSFILE`, `DOCUMENTID`, `MODELVERSION`, `TIMESTAMP`, and per toolpath `TOOLPATHID`, `TOOLPATH`, `G331` (CAD transform), `G330` (work plane), `CYCLEDEPTH`, component/feature header; the macros write `SIZE` / `POSN` lines; `END` at batch end. Enabled by Fusion's **Print results**. | Decision 2. |
| Batch | Results file persists across programs (component counter); a post property closes the batch with `END`. MDI reset needed after an abort. | Only with decision 2. |
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
| Wrong size | `wrongSizeAction == "stop-message"`, `toleranceSize` | `_size_tolerance_plus` = `_size_tolerance_minus` = `toleranceSize` |
| Out of position | `outOfPositionAction == "stop-message"`, `tolerancePosition` | `_position_tolerance` (see decision 1) |
| Angle askew | `angleAskewAction`, `toleranceAngle` | none (no angle macros) → post warning |
| Update tool wear | `updateToolWear`; `toolDiameterOffset` (XY) / `toolLengthOffset` (Z) | `_update_tool` (offset number = tool number on PathPilot; validated 1–1000, not 99) |
| Error correction % | `toolWearErrorCorrection` | `_update_feedback` = % / 100 |
| Update threshold | `toolWearUpdateThreshold` | `_update_minimum` |
| (no Fusion field) | — | `_update_maximum`: post property, see decision 3 |
| Print results | `printResults` | `_log_results = 1` (CSV); `_feature_number` = running count in the program |

Post properties (new group **Probing**), written once at program start, only in programs that probe:

| Property | Default | Writes |
|---|---|---|
| Show results on Status tab | Yes | `_display_results` |
| Out-of-tolerance action | Pause (M0) | `_tolerance_action` 1; Abort = 2; Flag only = 0 |
| Orient wireless probe | Yes | `_orient_probe` |
| Maximum correction (0 = none) | 0 | `_update_maximum` per call (decision 3) |
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
7. **Circular hole with island**: the stock post feeds Z down at the hole center (onto the island) and
   `probe_circular_bore` ignores `_z_clearance_position` → stop with an error (decision 4).
8. **Angle askew** checked in Fusion → warning that it is not checked.

Not changed: macro names, T99/H99 check, pattern/mirror checks, plane-angle cycles rejected.

## 5. Decisions needed

1. **Position tolerance**: Fusion's field follows Renishaw `M` (true position). Macros today check each axis
   against ± tolerance. Keep per axis, or switch XY features to true position (`_result_tp_dev` already exists)?
2. **Results file**: CSV only (as now), or also Fusion-importable `RESULTS.TXT`? The Fusion format needs post
   header lines plus a new log mode in `probe_result`; suggested as a later step.
3. **Maximum correction**: a post property (applies to every probing op in the program), or leave unset?
4. **Hole with island**: error in the post, or add island support to `probe_circular_bore` (the KB article
   already describes it)?
5. **Protected positioning** (proposal): `protectedProbeMove()` is a plain `G1`. A `G38.3` move followed by
   `#5070` (1 = probe tripped) → abort "probe hit something while positioning" would stop on an unexpected
   contact. Would need a small macro (`o<probe_protected_move>`).

## 6. Testing

- Fusion test setup with one op per cycle type: WCS and geometry probing, tolerances on/off, tool wear on a
  semi-finish/finish pair, print results on/off, an override-driving-WCS op.
- Post it, diff against the stock post's output (only the intended lines change), run the output through
  `tools/sim_macros.py` against modeled parts, then on the 1500MX sim.
