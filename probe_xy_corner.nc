o<probe_xy_corner> sub
(Probe in x positive or negative direction and set 0)

(PRINT, begin probe_xy_corner probe, probing X first)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> X offset is #<_work_offset_x>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> Y offset is #<_work_offset_y>)


#<_first_starting_position> = #5420

(PRINT, _first_starting_position is #<_first_starting_position>)

G90 (set to absolute mode)

#3 = #5220 (current active wcs)
(PRINT, # 3 is #3)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, first touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	G38.6 X[[#5410/2]*-1]
	o100 else
	G38.6 X[#5410/2]
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, second touch successful)

G54.1 P#<_measuring_wcs>

o160 if [#<_first_position_to_probe> GT #<_first_starting_position>]
    G10 L20 P#5220 X[#<_x_wcs_offset> - [#5410/2]]
    o160 else
    G10 L20 P#5220 X[#<_x_wcs_offset> + [#5410/2]]
o160 endif

(DEBUG, Found G54.1 P#<_measuring_wcs> X offset is #<_work_offset_x>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o110 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	G38.6 X[[#5410/2]*-1]
	o110 else
	G38.6 X[#5410/2]
o110 endif

G90 (set to absolute mode)

(PRINT, probing of x complete, begin probing of y)
G54.1 P#3
G1 Z#<_z_clearance_position> F#<_probe_rapid_feed_per_min> (rapid move to Z clearance height)
G1 X#<_second_x_position> Y#<_second_y_position>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

#<_second_starting_position> = #5421

(PRINT, _second_starting_position is #<_second_starting_position>)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, first touch successful)

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
(PRINT, second touch successful)

G54.1 P#<_measuring_wcs>

o260 if [#<_second_position_to_probe> GT #<_second_starting_position>]
    G10 L20 P#5220 Y[#<_y_wcs_offset> - [#5410/2]]
    o260 else
    G10 L20 P#5220 Y[#<_y_wcs_offset> + [#5410/2]]
o260 endif

(DEBUG, Found G54.1 P#<_measuring_wcs> Y offset is #<_work_offset_y>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o210 if [#<_second_position_to_probe> GT #<_second_starting_position>]
	G38.6 Y[[#5410/2]*-1]
	o210 else
	G38.6 Y[#5410/2]
o210 endif

G90 (set to absolute mode)

(PRINT, end probe_xy_outer_corner probe)
o<probe_xy_corner> endsub

M02 (end program)
