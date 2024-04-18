G90 G64 G17 G40 G80 G94 G91.1 G49
G20 (Inch)
G30 (Move to G30 position)
M5 (Turn off spindle)
M9 (Turn off coolant)

(Values for the parameters below must be entered)

#<_first_position_to_probe> =  (absolute value to probe to in the positioning wcs)
#<_max_allowable_position> =  (maximum value that the returned probe value is allowed to be without generating an error. Given in the positioning WCS)
#<_min_allowable_position> =   (minimum value that the returned probe value is allowed to be without generating an error. Given in the positioning WCS)

T99 G43 H99 M6 (Change to spindle probe)
G54 (set to positioning wcs)
F#<_probe_rapid_feed_per_min>

(Enter values for XYZ position to position probe)

G0 X   Y  (rapid move to XY location to start probing)
G1 Z  (rapid move to Z clearance height)

F#<_probe_rough_feed_per_min>

(Enter value for Z location to start probing)

G1 Z  (protected move to Z probing height)

o<probe_z_for_position> call 
G54 (reset to positioning wcs)
G90 (reset to absolute positioning)
G30 (retract to G30 location)
M30