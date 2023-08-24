o<probe_circular_boss> sub
(Probe in x positive or negative direction and set 0)

(PRINT, begin probe_circular_boss, probing X first)
(PRINT, _diameter_to_position is #<_diameter_to_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _first_position_to_probe ia #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

G90 (set to absolute mode)

#1 = #5420 (current relative X position)
#2 = #5421 (current relative Y position)
#3 = #5422 (current relative Z position)
#4 = #5220 (current active wcs)
#<radius_to_position> = [#<_diameter_to_position> / 2]
(PRINT, # 1 is #1)
(PRINT, # 2 is #2)
(PRINT, # 3 is #3)
(PRINT, # 4 is #4)

(first X position)
G1 X[#1 + #<radius_to_position>] F#<_probe_rough_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 X#1
(PRINT, first x touch successful)

(first retract)
G91 (set to incremental mode)
o100 if [#<_metric> EQ 1]  
	G38.6 X.1
	o100 else
	G38.6 X.05
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X#1
(PRINT, second x touch successful)

#<_first_x_touch> = #5420
(PRINT, _first_x_touch is #<_first_x_touch>)

(second retract)
G91 (set to incremental mode)
o101 if [#<_metric> EQ 1]  
	G38.6 X.1
	o101 else
	G38.6 X.05
o101 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(second X position)
G1 X[#1 - #<radius_to_position>] F#<_probe_rough_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 X#1
(PRINT, first x touch successful)

(first retract)
G91 (set to incremental mode)
o110 if [#<_metric> EQ 1]  
	G38.6 X-.1
	o110 else
	G38.6 X-.05
o110 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X#1
(PRINT, second x touch successful)

#<_second_x_touch> = #5420
(PRINT, _second_x_touch is #<_second_x_touch>)


(X finished retract)
G91 (set to incremental mode)
o102 if [#<_metric> EQ 1]  
	G38.6 X-.1
	o102 else
	G38.6 X-.05
o102 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(PRINT, centering x)
#<_x_center> = [#<_first_x_touch> + #<_second_x_touch>]
(PRINT, _x_center is #<_x_center>)
G1 X#<_x_center> F#<_probe_rough_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X#<_x_wcs_offset> 
G54.1 P#4

(PRINT, probing of x complete, begin probing of y)

(first Y position)
G1 Y[#2 + #<radius_to_position>] F#<_probe_rough_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#2
(PRINT, first y touch successful)

(first retract)
G91 (set to incremental mode)
o120 if [#<_metric> EQ 1]  
	G38.6 Y.1
	o120 else
	G38.6 Y.05
o120 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#2
(PRINT, second y touch successful)

#<_first_y_touch> = #5421
(PRINT, _first_y_touch is #<_first_y_touch>)

(second retract)
G91 (set to incremental mode)
o121 if [#<_metric> EQ 1]  
	G38.6 Y.1
	o121 else
	G38.6 Y.05
o121 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(second Y position)
G1 Y[#2 - #<radius_to_position>] F#<_probe_rough_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#2
(PRINT, first y touch successful)

(first retract)
G91 (set to incremental mode)
o130 if [#<_metric> EQ 1]  
	G38.6 Y-.1
	o130 else
	G38.6 Y-.05
o130 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#2
(PRINT, second y touch successful)

#<_second_y_touch> = #5421
(PRINT, _second_y_touch is #<_second_y_touch>)

(Y finished retract)
G91 (set to incremental mode)
o122 if [#<_metric> EQ 1]  
	G38.6 Y-.1
	o122 else
	G38.6 Y-.05
o122 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(PRINT, centering y)
#<_y_center> = [[#<_first_y_touch> + #<_second_y_touch>]/2]
(PRINT, _y_center is #<_y_center>)
G1 Y#<_y_center> F#<_probe_rough_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 Y#<_y_wcs_offset>
G54.1 P#4

(PRINT, end probe_bore_four_point probe)
o<probe_circular_boss> endsub

M02 (end program)
