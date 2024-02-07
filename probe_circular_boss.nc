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
G1 X[#1 + #<radius_to_position>] F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 X#1
(PRINT, first x touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_first_position_to_probe> GT #1]
	G38.6 X[[#5410/2]*-1]
	o100 else
	G38.6 X[#5410/2]
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
F#<_probe_rough_feed_per_min>
o110 if [#<_first_position_to_probe> GT #1]
	G38.6 X[[#5410/2]*-1]
	o110 else
	G38.6 X[#5410/2]
o110 endif

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
F#<_probe_rough_feed_per_min>
o200 if [#<_first_position_to_probe> GT #1]
	G38.6 X[[#5410/2]*-1]
	o200 else
	G38.6 X[#5410/2]
o200 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X#1
(PRINT, second x touch successful)

#<_second_x_touch> = #5420
(PRINT, _second_x_touch is #<_second_x_touch>)

(X finished retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o210 if [#<_first_position_to_probe> GT #1]
	G38.6 X[[#5410/2]*-1]
	o210 else
	G38.6 X[#5410/2]
o210 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(PRINT, centering x)
#<_x_center> = [#<_first_x_touch> + #<_second_x_touch>]
(PRINT, _x_center is #<_x_center>)
G1 X#<_x_center> F#<_probe_rapid_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X#<_x_wcs_offset> 
G54.1 P#4

(PRINT, probing of x complete, begin probing of y)

(first Y position)
G1 Y[#2 + #<radius_to_position>] F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#2
(PRINT, first y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o300 if [#<_second_position_to_probe> GT #2]
	G38.6 Y[[#5410/2]*-1]
	o300 else
	G38.6 Y[#5410/2]
o300 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#2
(PRINT, second y touch successful)

#<_first_y_touch> = #5421
(PRINT, _first_y_touch is #<_first_y_touch>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o310 if [#<_second_position_to_probe> GT #2]
	G38.6 Y[[#5410/2]*-1]
	o310 else
	G38.6 Y[#5410/2]
o310 endif

G90 (set to absolute mode)

G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min>

(second Y position)
G1 Y[#2 - #<radius_to_position>] F#<_probe_rapid_feed_per_min>
G1 Z#<_first_position_to_probe> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#2
(PRINT, first y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o400 if [#<_second_position_to_probe> GT #2]
	G38.6 Y[[#5410/2]*-1]
	o400 else
	G38.6 Y[#5410/2]
o400 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#2
(PRINT, second y touch successful)

#<_second_y_touch> = #5421
(PRINT, _second_y_touch is #<_second_y_touch>)

(Y finished retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o410 if [#<_second_position_to_probe> GT #2]
	G38.6 Y[[#5410/2]*-1]
	o410 else
	G38.6 Y[#5410/2]
o410 endif

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
