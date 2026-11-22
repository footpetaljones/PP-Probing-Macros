o<probe_xy_corner> sub
(probe_xy_corner: probe an X edge then a Y edge and set the XY origin of the measuring wcs to the corner)
(works for inside and outside corners - each probe direction comes from its target vs its start)
(required: _first_position_to_probe, _second_position_to_probe, _second_x_position, _second_y_position)
(required: _second_z_position, _z_clearance_position, _measuring_wcs, _x_wcs_offset, _y_wcs_offset)

(PRINT, begin probe_xy_corner, probing X first)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

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

(X edge - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, X fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, X slow touch successful)

(set measuring wcs X - the probe center was one tip radius short of the edge at the trip point)
#<overtravel> = [#5420 - #5061] (stopped position minus trip point, positioning wcs)
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X[#<_x_wcs_offset> - [#<tip_r> * #<dir>] + #<overtravel>]

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(PRINT, X complete, moving to Y start)
G54.1 P#<start_wcs>
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>
G1 X#<_second_x_position> Y#<_second_y_position> F#<_probe_rapid_feed_per_min>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

#<_second_starting_position> = #5421 (start Y in the positioning wcs)
(PRINT, _second_starting_position is #<_second_starting_position>)

o200 if [#<_second_position_to_probe> GT #<_second_starting_position>]
	#<dir> = 1 (probing toward +Y)
o200 else
	#<dir> = -1 (probing toward -Y)
o200 endif

(Y edge - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, Y fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, Y slow touch successful)

(set measuring wcs Y - the probe center was one tip radius short of the edge at the trip point)
#<overtravel> = [#5421 - #5062] (stopped position minus trip point, positioning wcs)
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 Y[#<_y_wcs_offset> - [#<tip_r> * #<dir>] + #<overtravel>]

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(PRINT, end probe_xy_corner)
o<probe_xy_corner> endsub
