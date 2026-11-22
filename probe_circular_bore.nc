o<probe_circular_bore> sub
(probe_circular_bore: probe a bore at +X -X +Y -Y and set the XY origin of the measuring wcs to the center)
(start inside the bore near its center at the probing height - X is centered before Y is probed)
(required: _diameter_to_probe, _measuring_wcs, _x_wcs_offset, _y_wcs_offset)
(optional inputs and _result_ outputs: see probe_result)

(PRINT, begin probe_circular_bore, probing X first)
(PRINT, _diameter_to_probe is #<_diameter_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

#<start_x> = #5420 (start X in the positioning wcs)
#<start_y> = #5421 (start Y in the positioning wcs)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, start_x is #<start_x>)
(PRINT, start_y is #<start_y>)

(+X wall - fast touch, back off, slow touch, retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.2 X[#<_diameter_to_probe> / 2]
(PRINT, +X fast touch successful)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * -1]
F#<_probe_fine_feed_per_min>
G38.2 X[#<_diameter_to_probe> / 2]
(PRINT, +X slow touch successful)
#<_first_x_touch> = #5061 (trip point)
(PRINT, _first_x_touch is #<_first_x_touch>)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * -1]
G90 (set absolute mode)

(return to start)
G1 X#<start_x> F#<_probe_rapid_feed_per_min>

(-X wall - fast touch, back off, slow touch, retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.2 X[#<_diameter_to_probe> / -2]
(PRINT, -X fast touch successful)
F#<_probe_rough_feed_per_min>
G38.6 X#<tip_r>
F#<_probe_fine_feed_per_min>
G38.2 X[#<_diameter_to_probe> / -2]
(PRINT, -X slow touch successful)
#<_second_x_touch> = #5061 (trip point)
(PRINT, _second_x_touch is #<_second_x_touch>)
F#<_probe_rough_feed_per_min>
G38.6 X#<tip_r>
G90 (set absolute mode)

(center X - Y is probed through the X center)
#<_x_center> = [[#<_first_x_touch> + #<_second_x_touch>] / 2]
(PRINT, _x_center is #<_x_center>)
G1 X#<_x_center> F#<_probe_rapid_feed_per_min>

(PRINT, X complete, probing Y)

(+Y wall - fast touch, back off, slow touch, retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.2 Y[#<_diameter_to_probe> / 2]
(PRINT, +Y fast touch successful)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * -1]
F#<_probe_fine_feed_per_min>
G38.2 Y[#<_diameter_to_probe> / 2]
(PRINT, +Y slow touch successful)
#<_first_y_touch> = #5062 (trip point)
(PRINT, _first_y_touch is #<_first_y_touch>)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * -1]
G90 (set absolute mode)

(return to start)
G1 Y#<start_y> F#<_probe_rapid_feed_per_min>

(-Y wall - fast touch, back off, slow touch, retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.2 Y[#<_diameter_to_probe> / -2]
(PRINT, -Y fast touch successful)
F#<_probe_rough_feed_per_min>
G38.6 Y#<tip_r>
F#<_probe_fine_feed_per_min>
G38.2 Y[#<_diameter_to_probe> / -2]
(PRINT, -Y slow touch successful)
#<_second_y_touch> = #5062 (trip point)
(PRINT, _second_y_touch is #<_second_y_touch>)
F#<_probe_rough_feed_per_min>
G38.6 Y#<tip_r>
G90 (set absolute mode)

(center Y, diameter from the Y chord through the X center, and result)
#<_y_center> = [[#<_first_y_touch> + #<_second_y_touch>] / 2]
(PRINT, _y_center is #<_y_center>)
#<diameter> = [ABS[#<_second_y_touch> - #<_first_y_touch>] + [2 * #<tip_r>]]
(PRINT, diameter is #<diameter>)
G1 Y#<_y_center> F#<_probe_rapid_feed_per_min>

(compare, report, and set the measuring wcs)
o<probe_result> call [9] [1] [1] [0] [#<_x_center>] [#<_y_center>] [0] [#<diameter>] [1]

(PRINT, end probe_circular_bore)
o<probe_circular_bore> endsub
