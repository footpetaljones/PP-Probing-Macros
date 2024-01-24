G90 G64 G50 G17 G40 G80 G94 G91.1 G49
G20
G30 Z0 (retract to G30 location)
M5 M9 (turn off spindle and coolant)

#<_first_position_to_probe> = .5
#<_measuring_wcs> = 2 (G55)

T99 G43 H99 M6
G54 (set to positioning wcs)
G0 X-.25 Y.25 (rapid move to XY location to start probing)
G38.3 Z1 F#<_probe_rapid_feed_per_min> (fast speed protected move to Z clearance height)
G38.3 Z-.25 F#<_probe_rough_feed_per_min> (medium speed protected move to Z probing height)

o<probe_x_edge> call (call probing program)
G54 (reset to positioning wcs)
G90 (reset to absolute positioning)
G30 Z0 (retract to G30 location)
M30

