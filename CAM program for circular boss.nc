%
(Test probing)
(Test Fusion probing functions)
(T99  D=0.1181 CR=0.0591 - ZMIN=0. - probe)
G90 G64 G50 G17 G40 G80 G94 G91.1 G49
G20 (Inch)
G30 Z0
M5 M9

#<_diameter_to_position> = 1.75
#<_z_clearance_position> = 1
#<_first_position_to_probe> = -.375
#<_measuring_wcs> = 1 (given with number between 1 and 500 to be used with G54.1 Pxxx, set equivalent to #<driving_wcs> if same)
#<_x_wcs_offset> = 0
#<_y_wcs_offset> = 0

T99 G43 H99 M6
G54 (set to driving wcs)
G0 X0.25 Y-.25 (rapid move to XY location to start probe)
G1 Z1 F#<_probe_rapid_feed_per_min> (rapid move to Z clearance height)
G1 Z-.25 F#<_probe_rough_feed_per_min> (protected move to Z probing height)

o<probe__circular_boss> call 
G54 (set to driving wcs)
G90
G30 Z0
M30
%
