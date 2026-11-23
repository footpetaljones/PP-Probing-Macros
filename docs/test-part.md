# Probing test part

Status: **design.** To be modeled in Fusion with one machining setup and two probing setups (inch, metric).
Fusion did not respond on 2026-11-23, so nothing is modeled yet.

## Part

- 6061-T6, finished 3.500 x 3.500 x 0.875 in. Stock 3.750 x 3.750 x 1.000 in, held in a vise by the bottom.
- WCS G54: X/Y at the part center, Z0 on the finished top.
- Outside contour 0.500 deep so the sides can be probed. The bottom 0.375 stays in the vise.

| # | Feature | Center (X, Y) | Size | Depth | Probing cycles it serves |
|---|---|---|---|---|---|
| 1 | Plain bore | 0, 0 | Ø0.500 | 0.500 | circular hole, partial circular hole (3 point) |
| 2 | Rectangular pocket | +0.900, +0.900 | 1.250 X x 1.000 Y, R0.125 corners | 0.250 | X/Y channel, rectangular hole, inner corner, Z on the floor |
| 3 | Rectangular pocket with island | -0.900, +0.900 | 1.250 x 1.000 pocket, 0.500 x 0.375 island flush with the top | 0.250 | channel with island, rectangular hole with island, X/Y wall and rectangular boss on the island |
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
