o<probe_bore_three_point> sub

(PRINT, begin probe_bore_three_point)
(PRINT, _first_vector is #<_first_vector>)
(PRINT, _second_vector is #<_second_vector>)
(PRINT, _third_vector is #<_third_vector>)
(PRINT, _diameter_to_probe is #<_diameter_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

#1 = #5420 (current relative X position)
#2 = #5421 (current relative Y position)
#4 = #5220 (current active wcs)
(PRINT, # 1 is #1)
(PRINT, # 2 is #2)
(PRINT, # 4 is #4)

G90 (set absolute mode)

(PRINT, probing first vector)
(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 @#<_diameter_to_probe> ^#<_first_vector>
(PRINT, first first_vector touch successful)

(first retract)
G91 (set incremental mode)
G38.6 @[[#5410/2]*-1]
G90 (set absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 @#<_diameter_to_probe>
(PRINT, second first_vector touch successful)

#<_first_vector_x_location> = #5420
#<_first_vector_y_location> = #5421
(PRINT, _first_vector_x_location is #<_first_vector_x_location>)
(PRINT, _first_vector_x_location is #<_first_vector_x_location>)

(retract from first touch point)
G38.6 X#1 Y#1 F#<_probe_rapid_feed_per_min>

(PRINT, probing second vector)
(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 @#<_diameter_to_probe> ^#<_second_vector>
(PRINT, first second_vector touch successful)

(second retract)
G91 (set incremental mode)
G38.6 @[[#5410/2]*-1]
G90 (set absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 @#<_diameter_to_probe>
(PRINT, second second_vector touch successful)

#<_second_vector_x_location> = #5420
#<_second_vector_y_location> = #5421
(PRINT, _second_vector_x_location is #<_second_vector_x_location>)
(PRINT, _second_vector_y_location is #<_second_vector_y_location>)

(retract from second touch point)
G38.6 X#1 Y#1 F#<_probe_rapid_feed_per_min>

(PRINT, probing third vector)
(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 @#<_diameter_to_probe> ^#<_third_vector>
(PRINT, first third_vector touch successful)

(third retract)
G91 (set incremental mode)
G38.6 @[[#5410/2]*-1]
G90 (set absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 @#<_diameter_to_probe>
(PRINT, second third_vector touch successful)

#<_third_vector_x_location> = #5420
#<_third_vector_y_location> = #5421
(PRINT, _third_vector_x_location is #<_third_vector_x_location>)
(PRINT, _third_vector_y_location is #<_third_vector_y_location>)

(retract from third touch point)
G38.6 X#1 Y#1 F#<_probe_rapid_feed_per_min>

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
G54.1 P#4

(PRINT, end probe_bore_three_point)
o<probe_bore_three_point> endsub