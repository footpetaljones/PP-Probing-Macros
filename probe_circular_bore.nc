o<probe_circular_bore> sub
(Probe in x positive or negative direction and set 0)

(PRINT, begin probe_circular_bore, probing X first)
(PRINT, _diameter_to_probe is #<_diameter_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

G91 (set to incremental mode)

#1 = #5420 (current relative X position)
#2 = #5421 (current relative Y position)
#4 = #5220 (current active wcs)
(PRINT, # 1 is #1)
(PRINT, # 2 is #2)
(PRINT, # 4 is #4)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 X[#<_diameter_to_probe>/2]
(PRINT, first x touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[[#5410/2]*-1]
G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X[#<_diameter_to_probe>/2]
(PRINT, second x touch successful)

#<_first_x_touch> = #5420
(PRINT, _first_x_touch is #<_first_x_touch>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[[#5410/2]*-1]
G90 (set to absolute mode)

(return to start position)
G1 X#1 F#<_probe_rapid_feed_per_min>

(Probe second X position)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 X[#<_diameter_to_probe>/-2]
(PRINT, first x touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#5410/2]
G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 X[#<_diameter_to_probe>/-2]
(PRINT, second x touch successful)

#<_second_x_touch> = #5420
(PRINT, _second_x_touch is #<_second_x_touch>)

(X finished retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#5410/2]
G90 (set to absolute mode)

(PRINT, centering x)
M66 P0 L0 (queue buster)
#<_x_center> = [#<_first_x_touch> + #<_second_x_touch>]
(PRINT, _x_center is #<_x_center>)
G1 X#<_x_center> F#<_probe_rapid_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 X#<_x_wcs_offset> 
G54.1 P#4

(PRINT, probing of x complete, begin probing of y)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y[#<_diameter_to_probe>/2]
(PRINT, first y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[[#5410/2]*-1]
G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y[#<_diameter_to_probe>/2]
(PRINT, second y touch successful)

#<_first_y_touch> = #5421
(PRINT, _first_y_touch is #<_first_y_touch>)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[[#5410/2]*-1]
G90 (set to absolute mode)

(return to start position)
G90 (set to absolute mode)
G1 Y#2 F#<_probe_rapid_feed_per_min>
G91

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Y[#<_diameter_to_probe>/-2]
(PRINT, first y touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#5410/2]
G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Y[#<_diameter_to_probe>/-2]
(PRINT, second y touch successful)

#<_second_y_touch> = #5421
(PRINT, _second_y_touch is #<_second_y_touch>)

(Y finished retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#5410/2]
G90 (set to absolute mode)

(PRINT, centering y)
M66 P0 L0 (queue buster)
#<_y_center> = [#<_first_y_touch> + #<_second_y_touch>]
(PRINT, _y_center is #<_y_center>)
G1 Y#<_y_center> F#<_probe_rapid_feed_per_min>
G54.1 P#<_measuring_wcs>
G10 L20 P#5220 Y#<_y_wcs_offset>
G54.1 P#4

(PRINT, end probe_circular_bore)
o<probe_circular_bore> endsub