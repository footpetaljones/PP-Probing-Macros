o<probe_x_edge> sub
(Probe in x positive or negative direction and set 0)

(PRINT, begin probe_x_edge probe)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(DEBUG, Previous G54.1 P#<_measuring_wcs> X offset is #<_work_offset_x>)


#<_first_starting_position> = #5420

(PRINT, _first_starting_position is #<_first_starting_position>)

(set to measuring_wcs)
G90 (set to absolute mode)

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

(PRINT, end probe_x_edge probe)
o<probe_x_edge> endsub

M02 (end program)
