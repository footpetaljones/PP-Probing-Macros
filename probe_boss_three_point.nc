o<probe_boss_three_point> sub

(PRINT, begin probe_boss_three_point)
(PRINT, _first_vector is #<_first_vector>)
(PRINT, _second_vector is #<_second_vector>)
(PRINT, _third_vector is #<_third_vector>)
(PRINT, _diameter_to_probe is #<_diameter_to_probe>)
(PRINT, _diameter_to_position is #<_diameter_to_position)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> X offset is #<_work_offset_x>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> Y offset is #<_work_offset_y>)

#1 = #5420 (current relative X position)
#2 = #5421 (current relative Y position)
#3 = #5422 (current relative Z position)
#4 = #5220 (current active wcs)
#<_radius_to_position> = [#<_diameter_to_probe> / 2]
(PRINT, # 1 is #1)
(PRINT, # 2 is #2)
(PRINT, # 3 is #3)
(PRINT, # 4 is #4)

o1 if [#<_diameter_to_position> LE #<_diameter_to_probe>]
	(PRINT, diameter to position = #<_diameter_to_position>)
	(PRINT, diameter to probe = #<_diameter_to_probe>)
	(DEBUG, diameter to position = #<_diameter_to_position>)
	(DEBUG, diameter to probe = #<_diameter_to_probe>)
	(ABORT, diameter to position is less than or equal to diameter to probe in probe_boss_three_point routine)
o1 endif

G90 (set absolute mode)

(first vector position)
G1 @#<_diameter_to_position> ^#<_first_vector> F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(PRINT, probing first vector)
(fast probe)
G38.2 @#<_diameter_to_probe>
(PRINT, first first_vector touch successful)

(first retract)
G38.6 @[#<_diameter_to_probe>+[#5410/2]]

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 @#<_diameter_to_probe>
(PRINT, first_vector touch finished)

#<_first_vector_x_location> = #5420
#<_first_vector_y_location> = #5421
(PRINT, _first_vector_x_location is #<_first_vector_x_location>)
(PRINT, _first_vector_x_location is #<_first_vector_x_location>)

(retract from first touch point)
G38.6 @#<_diameter_to_position> F#<_probe_rapid_feed_per_min>
G1 Z#3 (retract to original Z position)

(return to start position)
G1 X#1 Y#1 (retract to original XY position)

(PRINT, probing second vector)
(second vector position)
G1 @#<_diameter_to_position> ^#<_second_vector> F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 @#<_diameter_to_probe> 
(PRINT, first second_vector touch successful)

(second retract)
G38.6 @[#<_diameter_to_probe>+[#5410/2]]

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 @#<_diameter_to_probe>
(PRINT, second_vector touch finished)

#<_second_vector_x_location> = #5420
#<_second_vector_y_location> = #5421
(PRINT, _second_vector_x_location is #<_second_vector_x_location>)
(PRINT, _second_vector_y_location is #<_second_vector_y_location>)

(retract from second touch point)
G38.6 @#<_diameter_to_position> F#<_probe_rapid_feed_per_min>
G1 Z#3 (retract to original Z position)

(return to start position)
G1 X#1 Y#1 (retract to original XY position)

(PRINT, probing third vector)
(second vector position)
G1 @#<_diameter_to_position> ^#<_third_vector> F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe>
(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 @#<_diameter_to_probe> 
(PRINT, first third_vector touch successful)

(third retract)
G38.6 @[#<_diameter_to_probe>+[#5410/2]]

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 @#<_diameter_to_probe>
(PRINT, second third_vector touch successful)

#<_third_vector_x_location> = #5420
#<_third_vector_y_location> = #5421
(PRINT, _third_vector_x_location is #<_third_vector_x_location>)
(PRINT, _third_vector_y_location is #<_third_vector_y_location>)

(retract from third touch point)
G38.6 @#<_diameter_to_position> F#<_probe_rapid_feed_per_min>
G1 Z#3 (retract to original Z position)

(return to start position)
G1 X#1 Y#1 (retract to original XY position)

(PRINT, probing of points finished, start of calculations)

(First perpendicular bisector)
#<variable> = [[#<_second_vector_x_location> + #<_first_vector_x_location>] / 2]
#<variable2> = [[#<_second_vector_y_location> + #<_first_vector_y_location>] / 2]
#<variable3> = [#<_second_vector_x_location> - #<_first_vector_x_location>]
#<variable4> = [[#<_second_vector_y_location> - #<_first_vector_y_location>] * -1]

(Second perpendicular bisector)
#<variable5> = [[#<_third_vector_x_location> + #<_second_vector_x_location>] / 2]
#<variable6> = [[#<_third_vector_y_location> + #<_second_vector_y_location>] / 2]
#<variable7> = [#<_third_vector_x_location> - #<_second_vector_x_location>]
#<variable8> = [[#<_third_vector_y_location> - #<_second_vector_y_location>] * -1]

(Find x center)
#<_x_center_mid1> = [#<variable2> * #<variable4> * #<variable8> + #<variable5> * #<variable4> *#<variable7> - #<variable> * #<variable3> * #<variable8> - #<variable6> * #<variable4> * #<variable8>]
#<_x_center_mid2> = [#<variable4> * #<variable7> - #<variable3> * #<variable8>]
#<_x_center> = [#<_x_center_mid1> / #<_x_center_mid2>]
(PRINT, _x_center is #<_x_center>)

(Find y center)
#<_y_center> = [[#<_x_center> - #<variable>] * #<variable3> / #<variable4> + #<variable2>]
(PRINT, _y_center is #<_y_center>)

(move to center)
G1 X#<_x_center> Y#<_y_center> F#<_probe_rough_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X#<_x_wcs_offset> Y#<_y_wcs_offset>
(DEBUG, Found G54.1 P#<_measuring_wcs> X offset is #<_work_offset_x>)
(DEBUG, Found G54.1 P#<_measuring_wcs> Y offset is #<_work_offset_y>)
G54.1 P#4

(PRINT, end probe_boss_three_point)
o<probe_boss_three_point> endsub
