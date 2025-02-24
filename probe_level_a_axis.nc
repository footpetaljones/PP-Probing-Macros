o<probe_level_a_axis> sub

(PRINT, begin probe_a_axis_level probe)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _a_wcs_offset is #<_a_wcs_offset>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> A offset is #<_work_offset_a>)

#<_first_starting_position> = #5421

(PRINT, _first_starting_position is #<_first_starting_position>)

G90 (set to absolute mode)

#1 = #5420 (current relative X position)
#2 = #5421 (current relative Y position)
#3 = #5422 (current relative Z position)
#4 = #5220 (current active wcs)
(PRINT, # 1 is #1)
(PRINT, # 2 is #2)
(PRINT, # 3 is #3)
(PRINT, # 4 is #4)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, first touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_metric> EQ 1]  
	G38.6 Z.1
	o100 else
	G38.6 Z.05
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, second touch successful)

#10 = #5063
(PRINT, first Z touch at Z#10)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(PRINT, moving to second probing position)
G1 X#<_second_x_position> Y#<_second_y_position>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

#<_second_starting_position> = #5421

(PRINT, _second_starting_position is #<_second_starting_position>)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, first touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_metric> EQ 1]  
	G38.6 Z.1
	o100 else
	G38.6 Z.05
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, second touch successful)

#11 = #5063
(PRINT, second Z touch at Z#11)

(PRINT, retracting Z axis to clearance position of #<_z_clearance_position)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(PRINT, calculating Y distance)
#<_y_distance> = #<_first_starting_position> - #<_second_starting_position>
(PRINT, Y distance is #<_y_distance>)

(PRINT, calculating Z difference)
#<_z_difference> = #10 - #11
(PRINT, Z difference is #<_z_difference>)

(PRINT, calculating A axis angle and setting work coordinate)
#<_a_angle> = ATAN[#<_z_difference> / #<_y_distance>]
(PRINT, A axis angle is #_a_angle> degrees)
#<_new_a_offset> = #<_work_offset_a> - #<_a_angle>
(PRINT, New A axis offset is #<_new_a_offset>)
G10 L2 P#<_measuring_wcs> A#<_new_a_offset>
(PRINT, New G54.1 P#<_measuring_wcs> A offset set to #<_new_a_offset>)

o<probe_level_a_axis> endsub