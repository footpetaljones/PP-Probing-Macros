o<probe_y_boss> sub
(Probe in y positive or negative direction and set 0)

(PRINT, begin probe_y_boss)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

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
G38.2 Y#<_first_position_to_probe>
(PRINT, first fast y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	G38.6 Y[[#5410/2]*-1]
	o100 else
	G38.6 Y[#5410/2]
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_first_position_to_probe>
(PRINT, first slow y touch successful)

#<_first_y_touch> = #5062
(PRINT, _first_y_touch is #<_first_y_touch>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o110 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	G38.6 Y[[#5410/2]*-1]
	o110 else
	G38.6 Y[#5410/2]
o110 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(second Y position)
G1 X#<_second_x_position> Y#<_second_y_position>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

#<_second_starting_position> = #5421

(PRINT, _second_starting_position is #<_second_starting_position>)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, second fast y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o200 if [#<_second_position_to_probe> GT #<_second_starting_position>]
	G38.6 Y[[#5410/2]*-1]
	o200 else
	G38.6 Y[#5410/2]
o200 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, second slow y touch successful)

#<_second_y_touch> = #5062
(PRINT, _second_y_touch is #<_second_y_touch>)

(Y finished retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o210 if [#<_second_position_to_probe> GT #<_second_starting_position>]
	G38.6 Y[[#5410/2]*-1]
	o210 else
	G38.6 Y[#5410/2]
o210 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(PRINT, centering y)
#<_y_center> = [[#<_first_y_touch> + #<_second_y_touch>] / 2]
(PRINT, _y_center is #<_y_center>)
G1 Y#<_y_center>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 Y#<_y_wcs_offset>
G54.1 P#4

(PRINT, end probe_y_boss)
o<probe_y_boss> endsub
