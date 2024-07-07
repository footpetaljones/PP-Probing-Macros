o<probe_y_pocket> sub
(Probe in y positive or negative direction and set 0)

(PRINT, begin probe_y_pocket)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> Y offset is #<_work_offset_y>)


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
G38.2 Y#<_first_position_to_probe>
(PRINT, first fast y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_metric> EQ 1]  
	G38.6 Y-.1
	o100 else
	G38.6 Y-.05
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_first_position_to_probe>
(PRINT, first slow y touch successful)

#<_first_y_touch> = #5421
(PRINT, _first_y_touch is #<_first_y_touch>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o101 if [#<_metric> EQ 1]  
	G38.6 Y-.1
	o101 else
	G38.6 Y-.05
o101 endif

G90 (set to absolute mode)

(second Y position)
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>
G1 X#<_second_x_position> Y#<_second_y_position> F#<_probe_rapid_feed_per_min>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>
G90

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, second fast y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o110 if [#<_metric> EQ 1]  
	G38.6 Y.1
	o110 else
	G38.6 Y.05
o110 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, second slow y touch successful)

#<_second_y_touch> = #5421
(PRINT, _second_y_touch is #<_second_y_touch>)

(Y finished retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o102 if [#<_metric> EQ 1]  
	G38.6 Y.1
	o102 else
	G38.6 Y.05
o102 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rough_feed_per_min>

(PRINT, centering y)
#<_y_center> = [[#<_first_y_touch> + #<_second_y_touch>] / 2]
(PRINT, _y_center is #<_y_center>)
G1 Y#<_y_center> F#<_probe_rough_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 Y#<_y_wcs_offset>
(DEBUG, Found G54.1 P#<_measuring_wcs> Y offset is #<_work_offset_y>)
G54.1 P#4

(PRINT, end probe_y_boss)
o<probe_y_pocket> endsub
