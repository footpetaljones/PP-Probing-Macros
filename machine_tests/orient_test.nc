(orient_test: checks the probe_orient sign on the machine)
(needs probe_orient.nc in the subroutines folder and the probe type set to wireless)
(mark one side of the probe body, run, and at each M0 note where the mark points)
(judge where the mark ends up, not which way the spindle turned to get there)
(each step the mark must end up 90 degrees further COUNTER-CLOCKWISE viewed from above)

G20 G90 G40
(DEBUG, _probe_wireless is #<_probe_wireless> - must be 1 for the spindle to turn)
#<_orient_probe> = 1
#<_orient_offset> = 0

o<probe_orient> call [0]
M0 (direction 0 = +X - note where the mark points)
o<probe_orient> call [90]
M0 (direction 90 = +Y - mark 90 deg CCW from the last stop)
o<probe_orient> call [180]
M0 (direction 180 = -X - mark another 90 deg CCW)
o<probe_orient> call [270]
M0 (direction 270 = -Y - mark another 90 deg CCW)
M5
M30
