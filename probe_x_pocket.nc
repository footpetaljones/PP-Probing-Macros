o<probe_x_pocket> sub
(Probe in y positive or negative direction and set 0)

(PRINT, begin probe_x_pocket)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> X offset is #<_work_offset_x>)

G90 (set to incremental mode)

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
G38.2 X#<_first_position_to_probe>
(PRINT, first fast x touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_metric> EQ 1]  
	G38.6 X-.1
	o100 else
	G38.6 X-.05
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, first slow x touch successful)

#<_first_x_touch> = #5420
(PRINT, _first_x_touch is #<_first_x_touch>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o101 if [#<_metric> EQ 1]  
	G38.6 X-.1
	o101 else
	G38.6 X-.05
o101 endif

G90 (set to absolute mode)

(second X position)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>
G1 X#<_second_x_position> Y#<_second_y_position> F#<_probe_rapid_feed_per_min>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 X#<_second_position_to_probe>
(PRINT, second fast x touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o110 if [#<_metric> EQ 1]  
	G38.6 X.1
	o110 else
	G38.6 X.05
o110 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X#<_second_position_to_probe>
(PRINT, second slow x touch successful)

#<_second_x_touch> = #5420
(PRINT, _second_x_touch is #<_second_x_touch>)

(X finished retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o102 if [#<_metric> EQ 1]  
	G38.6 X.1
	o102 else
	G38.6 X.05
o102 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(PRINT, centering x)
#<_x_center> = [[#<_first_x_touch> + #<_second_x_touch>] / 2]
(PRINT, _x_center is #<_x_center>)
G1 X#<_x_center> F#<_probe_rough_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X#<_x_wcs_offset>
(DEBUG, Found G54.1 P#<_measuring_wcs> X offset is #<_work_offset_x>) 
G54.1 P#4

(PRINT, end probe_x_pocket)
o<probe_x_pocket> endsub
