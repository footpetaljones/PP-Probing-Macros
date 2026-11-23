o<probe_circular_bore_island> sub
(probe_circular_bore_island: probe a bore with an island in its center at +X -X +Y -Y)
(and set the XY origin of the measuring wcs to the center)
(start above the bore center - each wall is reached over the island at the clearance height)
(the probe goes down on _diameter_to_position, between the island and the wall, at the Z height _first_position_to_probe)
(X is centered before Y is probed)
(required: _diameter_to_probe, _diameter_to_position, _z_clearance_position, _first_position_to_probe)
(required: _measuring_wcs, _x_wcs_offset, _y_wcs_offset)
(optional inputs and _result_ outputs: see probe_result)

(PRINT, begin probe_circular_bore_island, probing X first)
(PRINT, _diameter_to_probe is #<_diameter_to_probe>)
(PRINT, _diameter_to_position is #<_diameter_to_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

(check the inputs before any motion)
o100 if [#<_diameter_to_position> LE 0]
	(ABORT, probe_circular_bore_island - set _diameter_to_position to a circle between the island and the wall)
o100 endif
o101 if [#<_diameter_to_position> GE #<_diameter_to_probe>]
	(ABORT, probe_circular_bore_island - _diameter_to_position must be smaller than _diameter_to_probe)
o101 endif
o102 if [#<_first_position_to_probe> GE #<_z_clearance_position>]
	(ABORT, probe_circular_bore_island - _first_position_to_probe must be below _z_clearance_position)
o102 endif

G90 (set absolute mode)

#<start_x> = #5420 (start X in the positioning wcs)
#<start_y> = #5421 (start Y in the positioning wcs)
#<radius_to_position> = [#<_diameter_to_position> / 2]
#<radius_to_probe> = [#<_diameter_to_probe> / 2]
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, start_x is #<start_x>)
(PRINT, start_y is #<start_y>)

(clearance height above the center)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(+X wall - position over the island, orient, go down)
G1 X[#<start_x> + #<radius_to_position>] F#<_probe_rapid_feed_per_min>
o<probe_orient> call [0]
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch, back off, slow touch, retract)
F#<_probe_rough_feed_per_min>
G38.2 X[#<start_x> + #<radius_to_probe>]
(PRINT, +X fast touch successful)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * -1]
G90 (set absolute mode)
F#<_probe_fine_feed_per_min>
G38.2 X[#<start_x> + #<radius_to_probe>]
(PRINT, +X slow touch successful)
#<_first_x_touch> = #5061 (trip point)
(PRINT, _first_x_touch is #<_first_x_touch>)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * -1]
G90 (set absolute mode)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(-X wall - position over the island, orient, go down)
G1 X[#<start_x> - #<radius_to_position>] F#<_probe_rapid_feed_per_min>
o<probe_orient> call [180]
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch, back off, slow touch, retract)
F#<_probe_rough_feed_per_min>
G38.2 X[#<start_x> - #<radius_to_probe>]
(PRINT, -X fast touch successful)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X#<tip_r>
G90 (set absolute mode)
F#<_probe_fine_feed_per_min>
G38.2 X[#<start_x> - #<radius_to_probe>]
(PRINT, -X slow touch successful)
#<_second_x_touch> = #5061 (trip point)
(PRINT, _second_x_touch is #<_second_x_touch>)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X#<tip_r>
G90 (set absolute mode)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(center X - Y is probed through the X center)
#<_x_center> = [[#<_first_x_touch> + #<_second_x_touch>] / 2]
(PRINT, _x_center is #<_x_center>)

(PRINT, X complete, probing Y)

(+Y wall - position over the island, orient, go down)
G1 X#<_x_center> Y[#<start_y> + #<radius_to_position>] F#<_probe_rapid_feed_per_min>
o<probe_orient> call [90]
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch, back off, slow touch, retract)
F#<_probe_rough_feed_per_min>
G38.2 Y[#<start_y> + #<radius_to_probe>]
(PRINT, +Y fast touch successful)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * -1]
G90 (set absolute mode)
F#<_probe_fine_feed_per_min>
G38.2 Y[#<start_y> + #<radius_to_probe>]
(PRINT, +Y slow touch successful)
#<_first_y_touch> = #5062 (trip point)
(PRINT, _first_y_touch is #<_first_y_touch>)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * -1]
G90 (set absolute mode)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(-Y wall - position over the island, orient, go down)
G1 Y[#<start_y> - #<radius_to_position>] F#<_probe_rapid_feed_per_min>
o<probe_orient> call [270]
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch, back off, slow touch, retract)
F#<_probe_rough_feed_per_min>
G38.2 Y[#<start_y> - #<radius_to_probe>]
(PRINT, -Y fast touch successful)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y#<tip_r>
G90 (set absolute mode)
F#<_probe_fine_feed_per_min>
G38.2 Y[#<start_y> - #<radius_to_probe>]
(PRINT, -Y slow touch successful)
#<_second_y_touch> = #5062 (trip point)
(PRINT, _second_y_touch is #<_second_y_touch>)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y#<tip_r>
G90 (set absolute mode)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(center Y, diameter from the Y chord through the X center, end above the center)
#<_y_center> = [[#<_first_y_touch> + #<_second_y_touch>] / 2]
(PRINT, _y_center is #<_y_center>)
#<diameter> = [ABS[#<_second_y_touch> - #<_first_y_touch>] + [2 * #<tip_r>]]
(PRINT, diameter is #<diameter>)
G1 X#<_x_center> Y#<_y_center> F#<_probe_rapid_feed_per_min>

(compare, report, and set the measuring wcs)
o<probe_result> call [13] [1] [1] [0] [#<_x_center>] [#<_y_center>] [0] [#<diameter>] [1]

(PRINT, end probe_circular_bore_island)
o<probe_circular_bore_island> endsub
