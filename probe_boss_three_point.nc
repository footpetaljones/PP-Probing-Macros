o<probe_boss_three_point> sub
(probe_boss_three_point: probe three points around a boss and set the XY origin of the measuring wcs to the center)
(start above the boss near its center at a Z clearance height)
(each point: move out to _diameter_to_position, down to _first_position_to_probe, probe toward the center)
(vectors are touch-point angles in degrees CCW from +X)
(a warning is shown when vectors are closer than 15 degrees under 3 in / 75 mm diameter or 5 degrees above)
(targets are computed from the start position so any positioning wcs can be used)
(required: _first_vector, _second_vector, _third_vector, _diameter_to_probe, _diameter_to_position)
(required: _first_position_to_probe - Z probing height, _measuring_wcs, _x_wcs_offset, _y_wcs_offset)
(optional inputs and _result_ outputs: see probe_result)

(PRINT, begin probe_boss_three_point)
(PRINT, _first_vector is #<_first_vector>)
(PRINT, _second_vector is #<_second_vector>)
(PRINT, _third_vector is #<_third_vector>)
(PRINT, _diameter_to_probe is #<_diameter_to_probe>)
(PRINT, _diameter_to_position is #<_diameter_to_position>)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

#<start_x> = #5420 (start X in the positioning wcs)
#<start_y> = #5421 (start Y in the positioning wcs)
#<start_z> = #5422 (start Z in the positioning wcs - used as the clearance height)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
#<_radius_to_position> = [#<_diameter_to_position> / 2]
#<_radius_to_probe> = [#<_diameter_to_probe> / 2]
(PRINT, start_x is #<start_x>)
(PRINT, start_y is #<start_y>)
(PRINT, start_z is #<start_z>)

o100 if [#<_diameter_to_position> LE #<_diameter_to_probe>]
	(DEBUG, diameter to position = #<_diameter_to_position>)
	(DEBUG, diameter to probe = #<_diameter_to_probe>)
	(ABORT, probe_boss_three_point - diameter to position must be larger than diameter to probe)
o100 endif

(vector spacing - used for the accuracy warning)
#<sep_12> = [ABS[#<_first_vector> - #<_second_vector>] MOD 360]
#<sep_13> = [ABS[#<_first_vector> - #<_third_vector>] MOD 360]
#<sep_23> = [ABS[#<_second_vector> - #<_third_vector>] MOD 360]
o110 if [#<sep_12> GT 180]
	#<sep_12> = [360 - #<sep_12>]
o110 endif
o120 if [#<sep_13> GT 180]
	#<sep_13> = [360 - #<sep_13>]
o120 endif
o130 if [#<sep_23> GT 180]
	#<sep_23> = [360 - #<sep_23>]
o130 endif
#<min_sep> = #<sep_12>
o140 if [#<sep_13> LT #<min_sep>]
	#<min_sep> = #<sep_13>
o140 endif
o150 if [#<sep_23> LT #<min_sep>]
	#<min_sep> = #<sep_23>
o150 endif

G90 (set absolute mode)

(first vector)
#<position_x> = [#<start_x> + [#<_radius_to_position> * COS[#<_first_vector>]]]
#<position_y> = [#<start_y> + [#<_radius_to_position> * SIN[#<_first_vector>]]]
#<target_x> = [#<start_x> + [#<_radius_to_probe> * COS[#<_first_vector>]]]
#<target_y> = [#<start_y> + [#<_radius_to_probe> * SIN[#<_first_vector>]]]
#<back_x> = [#<tip_r> * COS[#<_first_vector>]]
#<back_y> = [#<tip_r> * SIN[#<_first_vector>]]

(position)
G1 X#<position_x> Y#<position_y> F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [#<_first_vector> + 180]

(fast touch toward the center)
F#<_probe_rough_feed_per_min>
G38.2 X#<target_x> Y#<target_y>
(PRINT, first vector fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X#<back_x> Y#<back_y>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<target_x> Y#<target_y>
(PRINT, first vector slow touch successful)

#<_first_vector_x_location> = #5061
#<_first_vector_y_location> = #5062
(PRINT, _first_vector_x_location is #<_first_vector_x_location>)
(PRINT, _first_vector_y_location is #<_first_vector_y_location>)

(retract and return to start)
F#<_probe_rapid_feed_per_min>
G38.6 X#<position_x> Y#<position_y>
G1 Z#<start_z> F#<_probe_rapid_feed_per_min>
G1 X#<start_x> Y#<start_y> F#<_probe_rapid_feed_per_min>

(second vector)
#<position_x> = [#<start_x> + [#<_radius_to_position> * COS[#<_second_vector>]]]
#<position_y> = [#<start_y> + [#<_radius_to_position> * SIN[#<_second_vector>]]]
#<target_x> = [#<start_x> + [#<_radius_to_probe> * COS[#<_second_vector>]]]
#<target_y> = [#<start_y> + [#<_radius_to_probe> * SIN[#<_second_vector>]]]
#<back_x> = [#<tip_r> * COS[#<_second_vector>]]
#<back_y> = [#<tip_r> * SIN[#<_second_vector>]]

(position)
G1 X#<position_x> Y#<position_y> F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [#<_second_vector> + 180]

(fast touch toward the center)
F#<_probe_rough_feed_per_min>
G38.2 X#<target_x> Y#<target_y>
(PRINT, second vector fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X#<back_x> Y#<back_y>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<target_x> Y#<target_y>
(PRINT, second vector slow touch successful)

#<_second_vector_x_location> = #5061
#<_second_vector_y_location> = #5062
(PRINT, _second_vector_x_location is #<_second_vector_x_location>)
(PRINT, _second_vector_y_location is #<_second_vector_y_location>)

(retract and return to start)
F#<_probe_rapid_feed_per_min>
G38.6 X#<position_x> Y#<position_y>
G1 Z#<start_z> F#<_probe_rapid_feed_per_min>
G1 X#<start_x> Y#<start_y> F#<_probe_rapid_feed_per_min>

(third vector)
#<position_x> = [#<start_x> + [#<_radius_to_position> * COS[#<_third_vector>]]]
#<position_y> = [#<start_y> + [#<_radius_to_position> * SIN[#<_third_vector>]]]
#<target_x> = [#<start_x> + [#<_radius_to_probe> * COS[#<_third_vector>]]]
#<target_y> = [#<start_y> + [#<_radius_to_probe> * SIN[#<_third_vector>]]]
#<back_x> = [#<tip_r> * COS[#<_third_vector>]]
#<back_y> = [#<tip_r> * SIN[#<_third_vector>]]

(position)
G1 X#<position_x> Y#<position_y> F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [#<_third_vector> + 180]

(fast touch toward the center)
F#<_probe_rough_feed_per_min>
G38.2 X#<target_x> Y#<target_y>
(PRINT, third vector fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X#<back_x> Y#<back_y>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<target_x> Y#<target_y>
(PRINT, third vector slow touch successful)

#<_third_vector_x_location> = #5061
#<_third_vector_y_location> = #5062
(PRINT, _third_vector_x_location is #<_third_vector_x_location>)
(PRINT, _third_vector_y_location is #<_third_vector_y_location>)

(retract and return to start)
F#<_probe_rapid_feed_per_min>
G38.6 X#<position_x> Y#<position_y>
G1 Z#<start_z> F#<_probe_rapid_feed_per_min>
G1 X#<start_x> Y#<start_y> F#<_probe_rapid_feed_per_min>

(PRINT, touches complete, calculating center)

(center of the circle through the three touch points, computed relative to the start position)
#<p1_x> = [#<_first_vector_x_location> - #<start_x>]
#<p1_y> = [#<_first_vector_y_location> - #<start_y>]
#<p2_x> = [#<_second_vector_x_location> - #<start_x>]
#<p2_y> = [#<_second_vector_y_location> - #<start_y>]
#<p3_x> = [#<_third_vector_x_location> - #<start_x>]
#<p3_y> = [#<_third_vector_y_location> - #<start_y>]
#<den> = [2 * [[#<p1_x> * [#<p2_y> - #<p3_y>]] + [#<p2_x> * [#<p3_y> - #<p1_y>]] + [#<p3_x> * [#<p1_y> - #<p2_y>]]]]
o300 if [ABS[#<den>] LT 0.000000001]
	(ABORT, probe_boss_three_point - touch points are in a line - check vectors and diameters)
o300 endif
#<n1> = [[#<p1_x> * #<p1_x>] + [#<p1_y> * #<p1_y>]]
#<n2> = [[#<p2_x> * #<p2_x>] + [#<p2_y> * #<p2_y>]]
#<n3> = [[#<p3_x> * #<p3_x>] + [#<p3_y> * #<p3_y>]]
#<_x_center> = [#<start_x> + [[[#<n1> * [#<p2_y> - #<p3_y>]] + [#<n2> * [#<p3_y> - #<p1_y>]] + [#<n3> * [#<p1_y> - #<p2_y>]]] / #<den>]]
#<_y_center> = [#<start_y> + [[[#<n1> * [#<p3_x> - #<p2_x>]] + [#<n2> * [#<p1_x> - #<p3_x>]] + [#<n3> * [#<p2_x> - #<p1_x>]]] / #<den>]]
(PRINT, _x_center is #<_x_center>)
(PRINT, _y_center is #<_y_center>)

(measured diameter and vector spacing warning)
#<cx_rel> = [#<_x_center> - #<start_x>]
#<cy_rel> = [#<_y_center> - #<start_y>]
#<touch_r> = SQRT[[[#<p1_x> - #<cx_rel>] * [#<p1_x> - #<cx_rel>]] + [[#<p1_y> - #<cy_rel>] * [#<p1_y> - #<cy_rel>]]]
#<measured_diameter> = [2 * [#<touch_r> - #<tip_r>]]
(PRINT, measured_diameter is #<measured_diameter>)
#<small_diameter> = 3.0 (inch)
o310 if [#<_metric> EQ 1]
	#<small_diameter> = 75.0 (mm)
o310 endif
#<sep_limit> = 5
o320 if [#<measured_diameter> LT #<small_diameter>]
	#<sep_limit> = 15
o320 endif
o330 if [#<min_sep> LT #<sep_limit>]
	(DEBUG, probe_boss_three_point warning - vectors only #<min_sep> deg apart on a #<measured_diameter> boss - center may be inaccurate)
o330 endif

(move to center, compare, report, and set the measuring wcs)
G1 X#<_x_center> Y#<_y_center> F#<_probe_rough_feed_per_min>
o<probe_result> call [12] [1] [1] [0] [#<_x_center>] [#<_y_center>] [0] [#<measured_diameter>] [2]

(PRINT, end probe_boss_three_point)
o<probe_boss_three_point> endsub
