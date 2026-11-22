o<probe_x_pocket> sub
(probe_x_pocket: probe two opposing X walls inside a pocket and set the X origin of the measuring wcs to the center)
(the second wall is probed from _second_x/y/z_position after retracting to _z_clearance_position)
(required: _first_position_to_probe, _second_position_to_probe, _second_x_position, _second_y_position)
(required: _second_z_position, _z_clearance_position, _measuring_wcs, _x_wcs_offset)

(PRINT, begin probe_x_pocket)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)

#<_first_starting_position> = #5420 (start X in the positioning wcs)
#<start_wcs> = #5220 (positioning wcs)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, _first_starting_position is #<_first_starting_position>)
(PRINT, start_wcs is #<start_wcs>)

o100 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	#<dir> = 1 (probing toward +X)
o100 else
	#<dir> = -1 (probing toward -X)
o100 endif

G90 (set absolute mode)

(first wall - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, first wall fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, first wall slow touch successful)

#<_first_x_touch> = #5061 (trip point)
(PRINT, _first_x_touch is #<_first_x_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(move to the second wall start)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>
G1 X#<_second_x_position> Y#<_second_y_position> F#<_probe_rapid_feed_per_min>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

#<_second_starting_position> = #5420 (second start X in the positioning wcs)
(PRINT, _second_starting_position is #<_second_starting_position>)

o200 if [#<_second_position_to_probe> GT #<_second_starting_position>]
	#<dir> = 1 (probing toward +X)
o200 else
	#<dir> = -1 (probing toward -X)
o200 endif

(second wall - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 X#<_second_position_to_probe>
(PRINT, second wall fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<_second_position_to_probe>
(PRINT, second wall slow touch successful)

#<_second_x_touch> = #5061 (trip point)
(PRINT, _second_x_touch is #<_second_x_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(center and set measuring wcs)
#<_x_center> = [[#<_first_x_touch> + #<_second_x_touch>] / 2]
(PRINT, _x_center is #<_x_center>)
G1 X#<_x_center> F#<_probe_rough_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X#<_x_wcs_offset>
G54.1 P#<start_wcs>

(PRINT, end probe_x_pocket)
o<probe_x_pocket> endsub
