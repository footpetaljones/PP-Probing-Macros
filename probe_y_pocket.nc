o<probe_y_pocket> sub
(probe_y_pocket: probe two opposing Y walls inside a pocket and set the Y origin of the measuring wcs to the center)
(the second wall is probed from _second_x/y/z_position after retracting to _z_clearance_position)
(required: _first_position_to_probe, _second_position_to_probe, _second_x_position, _second_y_position)
(required: _second_z_position, _z_clearance_position, _measuring_wcs, _y_wcs_offset)
(optional inputs and _result_ outputs: see probe_result)

(PRINT, begin probe_y_pocket)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

#<_first_starting_position> = #5421 (start Y in the positioning wcs)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, _first_starting_position is #<_first_starting_position>)

o100 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	#<dir> = 1 (probing toward +Y)
o100 else
	#<dir> = -1 (probing toward -Y)
o100 endif

G90 (set absolute mode)

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [180 - [90 * #<dir>]]

(first wall - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_first_position_to_probe>
(PRINT, first wall fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_first_position_to_probe>
(PRINT, first wall slow touch successful)

#<_first_y_touch> = #5062 (trip point)
(PRINT, _first_y_touch is #<_first_y_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(move to the second wall start)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>
G1 X#<_second_x_position> Y#<_second_y_position> F#<_probe_rapid_feed_per_min>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

#<_second_starting_position> = #5421 (second start Y in the positioning wcs)
(PRINT, _second_starting_position is #<_second_starting_position>)

o200 if [#<_second_position_to_probe> GT #<_second_starting_position>]
	#<dir> = 1 (probing toward +Y)
o200 else
	#<dir> = -1 (probing toward -Y)
o200 endif

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [180 - [90 * #<dir>]]

(second wall - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, second wall fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, second wall slow touch successful)

#<_second_y_touch> = #5062 (trip point)
(PRINT, _second_y_touch is #<_second_y_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(center, size, and result)
#<_y_center> = [[#<_first_y_touch> + #<_second_y_touch>] / 2]
(PRINT, _y_center is #<_y_center>)
#<width> = [ABS[#<_second_y_touch> - #<_first_y_touch>] + [2 * #<tip_r>]] (inside width)
(PRINT, width is #<width>)
G1 Y#<_y_center> F#<_probe_rough_feed_per_min>

(compare, report, and set the measuring wcs)
o<probe_result> call [6] [0] [1] [0] [0] [#<_y_center>] [0] [#<width>] [1]

(PRINT, end probe_y_pocket)
o<probe_y_pocket> endsub
