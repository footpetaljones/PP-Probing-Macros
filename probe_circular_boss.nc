o<probe_circular_boss> sub
(probe_circular_boss: probe a boss at +X -X +Y -Y and set the XY origin of the measuring wcs to the center)
(start above the boss center at the clearance height - X is centered before Y is probed)
(_first_position_to_probe is the Z probing height)
(required: _diameter_to_position, _z_clearance_position, _first_position_to_probe)
(required: _measuring_wcs, _x_wcs_offset, _y_wcs_offset)

(PRINT, begin probe_circular_boss, probing X first)
(PRINT, _diameter_to_position is #<_diameter_to_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

G90 (set absolute mode)

#<start_x> = #5420 (start X in the positioning wcs)
#<start_y> = #5421 (start Y in the positioning wcs)
#<start_wcs> = #5220 (positioning wcs)
#<radius_to_position> = [#<_diameter_to_position> / 2]
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, start_x is #<start_x>)
(PRINT, start_y is #<start_y>)
(PRINT, start_wcs is #<start_wcs>)

(+X side - position)
G1 X[#<start_x> + #<radius_to_position>] F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch toward the center)
F#<_probe_rough_feed_per_min>
G38.2 X#<start_x>
(PRINT, +X fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X#<tip_r>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<start_x>
(PRINT, +X slow touch successful)

#<_first_x_touch> = #5061 (trip point)
(PRINT, _first_x_touch is #<_first_x_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X#<tip_r>
G90 (set absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(-X side - position)
G1 X[#<start_x> - #<radius_to_position>] F#<_probe_rough_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch toward the center)
F#<_probe_rough_feed_per_min>
G38.2 X#<start_x>
(PRINT, -X fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<start_x>
(PRINT, -X slow touch successful)

#<_second_x_touch> = #5061 (trip point)
(PRINT, _second_x_touch is #<_second_x_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * -1]
G90 (set absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(center X and set measuring wcs X)
#<_x_center> = [[#<_first_x_touch> + #<_second_x_touch>] / 2]
(PRINT, _x_center is #<_x_center>)
G1 X#<_x_center> F#<_probe_rapid_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X#<_x_wcs_offset>
G54.1 P#<start_wcs>

(PRINT, X complete, probing Y)

(+Y side - position)
G1 Y[#<start_y> + #<radius_to_position>] F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch toward the center)
F#<_probe_rough_feed_per_min>
G38.2 Y#<start_y>
(PRINT, +Y fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y#<tip_r>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Y#<start_y>
(PRINT, +Y slow touch successful)

#<_first_y_touch> = #5062 (trip point)
(PRINT, _first_y_touch is #<_first_y_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y#<tip_r>
G90 (set absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(-Y side - position)
G1 Y[#<start_y> - #<radius_to_position>] F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast touch toward the center)
F#<_probe_rough_feed_per_min>
G38.2 Y#<start_y>
(PRINT, -Y fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Y#<start_y>
(PRINT, -Y slow touch successful)

#<_second_y_touch> = #5062 (trip point)
(PRINT, _second_y_touch is #<_second_y_touch>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * -1]
G90 (set absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(center Y and set measuring wcs Y)
#<_y_center> = [[#<_first_y_touch> + #<_second_y_touch>] / 2]
(PRINT, _y_center is #<_y_center>)
G1 Y#<_y_center> F#<_probe_rapid_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 Y#<_y_wcs_offset>
G54.1 P#<start_wcs>

(PRINT, end probe_circular_boss)
o<probe_circular_boss> endsub
