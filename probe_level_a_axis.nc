o<probe_level_a_axis> sub
(probe_level_a_axis: touch Z at two Y positions on a face held in the A axis and rotate the A origin)
(of the measuring wcs so that face is level - intended for manual use)
(start above the first point at the probing height; both touches use _first_position_to_probe as the Z target)
(required: _first_position_to_probe, _second_x_position, _second_y_position, _second_z_position)
(required: _z_clearance_position, _measuring_wcs)

(PRINT, begin probe_level_a_axis)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)

#<_first_starting_position> = #5421 (first point Y in the positioning wcs)
#<start_wcs> = #5220 (positioning wcs)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, _first_starting_position is #<_first_starting_position>)
(PRINT, start_wcs is #<start_wcs>)

G90 (set absolute mode)

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [0]

(first point - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, first point fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z#<tip_r>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, first point slow touch successful)

#<first_z> = #5063 (trip point)
(PRINT, first Z touch at #<first_z>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z#<tip_r>
G90 (set absolute mode)

(move to the second point)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>
G1 X#<_second_x_position> Y#<_second_y_position> F#<_probe_rapid_feed_per_min>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

#<_second_starting_position> = #5421 (second point Y in the positioning wcs)
(PRINT, _second_starting_position is #<_second_starting_position>)

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [0]

(second point - fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, second point fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z#<tip_r>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, second point slow touch successful)

#<second_z> = #5063 (trip point)
(PRINT, second Z touch at #<second_z>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z#<tip_r>
G90 (set absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(angle of the face - ATAN of the ratio keeps the result within +-90 degrees)
#<_y_distance> = [#<_first_starting_position> - #<_second_starting_position>]
#<_z_difference> = [#<first_z> - #<second_z>]
(PRINT, Y distance is #<_y_distance>)
(PRINT, Z difference is #<_z_difference>)
#<_a_angle> = ATAN[#<_z_difference> / #<_y_distance>]/[1]
(PRINT, A axis angle is #<_a_angle> degrees)

(rotate the measuring wcs A origin by the angle: the current A reading increases by _a_angle)
G54.1 P#<_measuring_wcs>
#<a_before> = #5423 (current A in the measuring wcs)
G10 L20 P#5220 A[#<a_before> + #<_a_angle>]
(DEBUG, G54.1 P#<_measuring_wcs> A origin rotated by #<_a_angle> degrees)
G54.1 P#<start_wcs>

(PRINT, end probe_level_a_axis)
o<probe_level_a_axis> endsub
