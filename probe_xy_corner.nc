o<probe_xy_corner> sub
(Probe in x positive or negative direction and set 0)

(PRINT, begin probe_xy_corner probe, probing X first)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _second_position_to_probe is #<_second_position_to_probe>)
(PRINT, _second_x_position is #<_second_x_position>)
(PRINT, _second_y_position is #<_second_y_position>)
(PRINT, _second_z_position is #<_second_z_position>)
(PRINT, _z_clearance_position is #<_z_clearance_position>)
(PRINT, _measuring_wcs is #<_measuring_wcs)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)

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
o100 if [#<_metric> EQ 1]  
	o110 if [#<_first_position_to_probe> LT 0]
    G38.6 X-.1
	o110 else
	G38.6 X.1
	o110 endif
o100 else
	o120 if [#<_first_position_to_probe> GT 0]
	G38.6 X-.05
	o120 else
	G38.6 X.05
	o120 endif
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, second touch successful)

G54.1 P#<_measuring_wcs>

o160 if [#<_first_position_to_probe> GT 0]
    G10 L20 P#<_measuring_wcs> X#<_x_wcs_offset> 
    o160 else
    G10 L20 P#<_measuring_wcs> X#<_x_wcs_offset> 
o160 endif

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o130 if [#<_metric> EQ 1]  
	o140 if [#<_first_position_to_probe> LT 0]
    G38.6 X-.1
	o140 else
	G38.6 X.1
	o140 endif
o130 else
    o150 if [#<_first_position_to_probe> GT 0]
	G38.6 X-.05
	o150 else
	G38.6 X.05
	o150 endif
o130 endif

G90 (set to absolute mode)

(PRINT, probing of x complete, begin probing of y)
G54.1 P#3
G1 Z#<_z_clearance_position> F#<_rapid_ruff> (rapid move to Z clearance height)
G1 X#<_second_x_position> Y#<_second_y_position>
G1 Z#<_second_z_position> F#<_probe_rough_feed_per_min>

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, first touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o200 if [#<_metric> EQ 1]  
	o210 if [#<_second_position_to_probe> LT 0]
    G38.6 Y-.1
	o210 else
	G38.6 Y.1
	o210 endif
o200 else
	o220 if [#<_second_position_to_probe> GT 0]
	G38.6 Y-.05
	o220 else
	G38.6 Y.05
	o220 endif
o200 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_second_position_to_probe>
(PRINT, second touch successful)

G54.1 P#<_measuring_wcs>

o260 if [#<_second_position_to_probe> GT 0]
    G10 L20 P#<_measuring_wcs> Y#<_y_wcs_offset>
    o260 else
    G10 L20 P#<_measuring_wcs> Y#<_y_wcs_offset>
o260 endif

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o230 if [#<_metric> EQ 1]  
	o240 if [#<_second_position_to_probe> LT 0]
    G38.6 Y-.1
	o240 else
	G38.6 Y.1
	o240 endif
o230 else
    o250 if [#<_second_position_to_probe> GT 0]
	G38.6 Y-.05
	o250 else
	G38.6 Y.05
	o250 endif
o230 endif

G90 (set to absolute mode)

(PRINT, end probe_xy_outer_corner probe)
o<probe_xy_corner> endsub

M02 (end program)

