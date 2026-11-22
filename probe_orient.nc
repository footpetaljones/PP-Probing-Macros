o<probe_orient> sub
(probe_orient: orient the spindle so the same point of the stylus faces the probing direction)
(argument: #1 probing direction in degrees CCW from +X - Z touches pass 0)
(only runs when #<_probe_wireless> is 1 - a wired probe is never rotated)
(optional: _orient_probe 1 default, 0 = never orient)
(optional: _orient_offset - spindle angle that faces the calibrated stylus point toward +X, default 0)
(the spindle angle counts clockwise from above, so R = offset - direction)

#<direction> = #1

#<orient> = 1
o100 if [EXISTS[#<_orient_probe>]]
	#<orient> = #<_orient_probe>
o100 endif
#<orient_offset> = 0
o110 if [EXISTS[#<_orient_offset>]]
	#<orient_offset> = #<_orient_offset>
o110 endif

o120 if [[#<orient> EQ 1] AND [#<_probe_wireless> EQ 1]]
	#<spindle_angle> = [[#<orient_offset> - #<direction>] MOD 360]
	o130 if [#<spindle_angle> LT 0]
		#<spindle_angle> = [#<spindle_angle> + 360]
	o130 endif
	(PRINT, probe_orient direction #<direction> spindle angle #<spindle_angle>)
	M19 R#<spindle_angle> Q10
o120 endif

o<probe_orient> endsub
