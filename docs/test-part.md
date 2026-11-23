# Probing test part

Status: **modeled and posted.** Fusion document "Probing test part" (Tormach Projects > Probing) with setups
Machining, Probing inch and Probing metric. Rebuilt on 2026-11-23 for 2 x 2 bar stock; all three posted with
`post/tormach-probing-v2.cps` and checked by hand. Open: the WCS Z top probe point (see Fusion notes), a simulator
run of the posted probing programs, an on-machine run.

## Part

- 6061-T6 square bar, stock 2.000 x 2.000 x 6.0 in (saw cut), laid flat in the vise.
- Finished 5.750 X x 1.875 Y x 1.950 Z: 0.050 faced off the top; sides and ends contoured 0.500 deep so the outside
  can be probed. The vise holds the bottom 1.450.
- WCS G54: X/Y at the part center, Z0 on the finished top.

All features in one row along X at Y0, 0.250 deep except the bore.

| # | Feature | Center X | Size | Probing cycles it serves |
|---|---|---|---|---|
| 2 | Rectangular pocket | -2.150 | 1.000 X x 1.250 Y, R0.200 corners | X/Y channel, rectangular hole, inner corner (+X/+Y corner), Z on the floor |
| 3 | Rectangular pocket with island | -0.950 | 1.000 x 1.250, R0.200 corners; island 0.375 X x 0.500 Y flush with the top | channel with island, rectangular hole with island, Y wall and rectangular boss on the island |
| 1 | Plain bore | 0.000 | Ø0.500, 0.500 deep | circular hole, partial circular hole (3 point) |
| 4 | Groove (bore with island) | 0.975 | Ø1.125 outside, Ø0.375 island flush with the top | circular hole with island (T201 diameter wear) |
| 5 | Boss in a counterbore | 2.200 | Ø0.375 boss flush with the top, Ø1.000 counterbore | circular boss, partial circular boss (3 point) |
| - | Outside | - | 5.750 x 1.875, 0.500 deep | X/Y single surface, outer corner |
| - | Top face | - | Z0 | Z |

Walls between features 0.16-0.25, end walls 0.175-0.225, pocket walls to the sides 0.3125.

Clearances for the Ø3 mm (0.118 in) stylus, checked in the posted program:
- #4: positioning circle Ø0.8069 - ball 0.157 off the island, 0.100 off the outside wall. Probe circle Ø1.3069.
- #5: positioning circle Ø0.6931 - ball outer edge 0.095 from the counterbore wall.
- #3: X probes start 0.159 from the island and the pocket wall (gap 0.3125); Y probes between the island (±0.250) and
  the pocket wall (±0.625).
- Inner corner G57 (#2, corner X-1.650 Y0.625): start 0.209 from each wall, touches 0.009 clear of the R0.200.

## Setups

1. **Machining** (inch, NK Mill library): face (T102), outside contour 0.500 deep (T203), "Pockets, groove and
   counterbore" (T201, In computer), "Walls #2 #3 #4, wear" (T201, 2D contour, compensation wear: G41.2), bore (T201).
2. **Probing inch** and 3. **Probing metric** - the same operations with values entered in each unit:
   - WCS probing: Z on the top (G54), plain bore center (G54 XY); in folders that update another WCS while driving
     from G54: outer corner (G55), +X and -Y sides (G56), inner corner of #2 (G57), X channel #2 with tolerance (G58).
   - Geometry probing (inspect only, G54) with print results: rectangular pocket #2 and #3 with size and position
     tolerance, rectangular boss and Y wall on the island, X channel with island, round boss #5 with tolerance,
     3-point bore #1 and 3-point boss #5, groove #4 with T201 diameter wear, Z on the #2 floor with T201 length wear.

## Fusion notes

- **WCS probing of G55-G58** sits in folders "Update G55" ... "Update G58". The folder has Override WCS Offset =
  the WCS to update (2-5); the operation has Override Driving WCS = 1, so the probe moves in G54. Posted:
  `G54` moves, `#<_measuring_wcs> = 2..5`. With the part where the model puts it, the probed axes of G55-G58
  come out equal to G54 (G55 XY, G56 X and Y, G57 XY, G58 X); that is the check for these operations. Their Z is
  not set.
- **WCS Z top probe point**: Fusion picks the point on the top face nearest its center. With the bore at the center
  that is X0.3312 Y0, on the 0.1625 wall between the bore and the groove (0.022 clearance each side). The point can
  only be picked in the UI (setting `probe_dragged_origin_point` by script fails); intended spot X0 Y0.600.
- **Out of position tolerance is posted doubled**: 0.004 in entered gives `#<_position_tolerance> = 0.008`
  (0.1 mm gives 0.2). Fusion passes the zone diameter in `cycle.tolerancePosition`; probe_result compares true
  position (2 x radial deviation) against it, so the entered value is the allowed radial deviation.
- Geometry operations use Fusion's default clearance height (retract + 50 mm). Harmless; not changed.
- **Inner corner**: Fusion starts the corner probe clearance + r from each wall. With R0.200 corners the clearance
  must be over 0.141 in or the touches land on the radius (0.100 gave touches about 0.006 short). G57 uses
  0.15 in / 4 mm.
- **2D Pocket with "In control: wear"** generates nothing for pockets with an island/boss, whatever the leads. So the
  pocket operation is "In computer" (to size; its 0.5 mm stock to leave is not enabled) and "Walls #2 #3 #4, wear"
  (perpendicular lead 0.04 in + 0.02 in arc, face contours with side "start inside") recuts those walls with G41.2,
  one G41.2/G40 per wall, islands included. It is the reference operation for the T201 wear probing. #5 has no wear
  contour: 0.0625 in for the tool center between the counterbore wall and the boss leaves no room for a lead.
- Posted wear inputs: `_update_tool = 201`, `_update_feedback = 0.8`, `_update_tool_minimum = 0.0005`
  (0.012 mm metric). No move moves Z together with X/Y (post 2aa01e0).
- Machining checked in the posted program: contour path X ±3.125 Y ±1.1875 (tool radius 0.250 outside), Z-0.500,
  climb; pocket and wall paths exactly one tool radius (0.125) from every wall, island and boss.

### Fusion API notes
- Reading `probe_selection` on an `OperationInput` for a probe operation crashes Fusion
  (CadProbe::getDraggedPointCadObject). Add the operation first, then set the selection on the operation.
- `probe_operation_selection` (tool wear reference) and `probe_dragged_origin_point` cannot be set by script
  (InternalValidationError).
- Changing the model loses the face selections of the operations that touch changed faces; they show the body
  instead of faces and the probing type falls back. Reselect, then set `probingType` where Fusion picks another one.
- The setups keep the old model box (`surfaceXLow` ...; warning "Depth (Y) less than the depth of the selected
  model") until `setup.models` is assigned again; the operations are then invalid and must be regenerated before
  posting ("Initialization fails" otherwise).
- `operation.warning` returns the warning text.
