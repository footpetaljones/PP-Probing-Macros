# Probing test part

Status: **modeled and posted.** Fusion document "Probing test part" (Tormach Projects > Probing) with setups
Machining, Probing inch and Probing metric. All three posted with `post/tormach-probing-v2.cps` and checked by hand
on 2026-11-23. Open: the tool wear reference operation (see Fusion notes), a simulator run of the posted
probing programs, an on-machine run.

## Part

- 6061-T6, finished 3.500 x 3.500 x 0.875 in. Stock 3.750 x 3.750 x 1.000 in, held in a vise by the bottom.
- WCS G54: X/Y at the part center, Z0 on the finished top.
- Outside contour 0.500 deep so the sides can be probed. The bottom 0.375 stays in the vise.

| # | Feature | Center (X, Y) | Size | Depth | Probing cycles it serves |
|---|---|---|---|---|---|
| 1 | Plain bore | 0, 0 | Ø0.500 | 0.500 | circular hole, partial circular hole (3 point) |
| 2 | Rectangular pocket | +0.900, +0.900 | 1.250 X x 1.000 Y, R0.200 corners | 0.250 | X/Y channel, rectangular hole, inner corner, Z on the floor |
| 3 | Rectangular pocket with island | -0.900, +0.900 | 1.250 x 1.000 pocket, R0.200 corners, 0.500 x 0.375 island flush with the top | 0.250 | channel with island, rectangular hole with island, X/Y wall and rectangular boss on the island |
| 4 | Bore with island (annular groove) | -0.900, -0.900 | Ø1.125 outside, Ø0.375 island flush with the top | 0.250 | circular hole with island |
| 5 | Round boss in a counterbore | +0.900, -0.900 | Ø0.625 boss flush with the top, Ø1.250 counterbore | 0.250 | circular boss, partial circular boss (3 point) |
| 6 | Outside | — | 3.500 x 3.500 | 0.500 | X/Y single surface, outer corner |
| 7 | Top face | — | — | Z0 | Z |

Clearances checked for a Ø4 mm (0.157 in) stylus with 0.050 in probe clearance:
- Island walls in #3: ball edge at 0.457 in X (pocket half-width 0.625) and 0.395 in Y (0.500).
- #4: positioning circle Ø0.868, ball inside edge 0.355 from center (island radius 0.188), outside edge 0.513 (groove radius 0.563).
- #5: positioning circle Ø0.882, ball outside edge 0.520 from center (counterbore radius 0.625).

## Setups

1. **Machining** (inch): face, outside contour, pockets, bores, groove, counterbore with tools from the NK Mill library.
2. **Probing, inch** and 3. **Probing, metric** - the same operations with values entered in each unit:
   - WCS probing: Z on the top (G54), plain bore center (G54 XY), outer corner (G55), +X and -Y sides (G56),
     inner corner of #2 (G57).
   - Geometry probing (inspect only, G54) with print results: rectangular pocket #2 with size and position
     tolerance, rectangular pocket with island #3, rectangular boss on the island, bore with island #4 with
     tool wear on its finishing tool, round boss #5 with tolerance, 3-point bore #1 and 3-point boss #5,
     Z on the #2 floor with length wear.

The post output of both probing setups is checked line by line and run through `tools/sim_macros.py`
against a model of this part (inner corner fix, diameters, island path, tolerances, wear).

## Fusion notes

- **WCS probing of G55-G58** sits in folders "Update G55" ... "Update G58". The folder has Override WCS Offset =
  the WCS to update (2-5); the operation has Override Driving WCS = 1, so the probe moves in G54. Posted:
  `G54` moves, `#<_measuring_wcs> = 2..5`. With the part where the model puts it, the probed axes of G55-G58
  come out equal to G54 (G55 XY, G56 X and Y, G57 XY, G58 X); that is the check for these operations. Their Z is
  not set. The first build had it reversed (moves in G55, updates G54).
- **Out of position tolerance is posted doubled**: 0.004 in entered gives `#<_position_tolerance> = 0.008`
  (0.1 mm gives 0.2). Fusion passes the zone diameter in `cycle.tolerancePosition`; probe_result compares true
  position (2 x radial deviation) against it, so the entered value is the allowed radial deviation.
- Geometry operations use Fusion's default clearance height (retract + 50 mm), so they rapid to Z2.34 between
  features. Harmless; not changed.
- Fusion API: reading `probe_selection` on an `OperationInput` for a probe operation crashes Fusion
  (CadProbe::getDraggedPointCadObject). Add the operation first, then set the selection on the operation.
- Fusion API: `probe_operation_selection` (tool wear reference operation) cannot be set by script
  (InternalValidationError). The two tool wear operations in each probing setup need it selected in the UI
  (reference: "Pockets, groove and counterbore", T201); until then they have an error and are not posted.
- Machining: outside contour is the outer loop of the top face, 0 stock to leave. Checked in the posted program:
  path X/Y +/-2.000 (part +/-1.750 plus tool radius 0.250), Z-0.500, climb. The pocket operation stays exactly one
  tool radius (0.125) from the three islands/bosses. The first build had the contour on the island of #3.
- **Pocket corners changed from R0.125 to R0.200** (2026-11-23; sketches Pocket and Pocket with island now
  dimensioned). Fusion lost the face selections of every probe operation that touched the top face, the pockets,
  the island or the boss, and of the pocket operation (they showed the body instead of faces, probing type
  unknown). Reselected by script; the probing type had to be set again where Fusion picked another one
  (inner corner, X channel, rectangular pocket, 3-point boss, channel with island, Y wall).
- **Inner corner G57 with R0.200**: Fusion starts the corner probe clearance + r = 0.159 from each wall, which
  is inside the 0.200 corner radius, so both touches land on the radius: about 0.006 in short in X and Y.
  Needs a larger probe clearance in that operation (0.15 in or more) or a smaller corner radius.
- **Pocket operation with compensation "In control: wear"** generates nothing for the three pockets with an
  island/boss (#3, #4, #5; Fusion warning), only #2. With "In computer" all four are cut.
