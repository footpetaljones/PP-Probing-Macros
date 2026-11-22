o<probe_apply_wear> sub
(probe_apply_wear: write a pending wear correction from a probing call into the loaded tool)
(call right after the tool change for the corrected tool and before G41/G42 and the finishing cut:)
(T5 M6 G43 H5 then o<probe_apply_wear> call)
(reads the loaded tool wear with #5409 / #5411 - always inches - and writes it with G10 L1, which takes program units)
(re-issues G43 H#5400 so the new length wear is active)

o100 if [EXISTS[#<_wear_pending_tool>] EQ 0]
	#<_wear_pending_tool> = 0
	#<_wear_pending_diameter> = 0
	#<_wear_pending_length> = 0
o100 endif

o110 if [#<_wear_pending_tool> EQ 0]
	(DEBUG, probe_apply_wear - no pending wear correction)
o110 elseif [#<_wear_pending_tool> NE #5400]
	(DEBUG, probe_apply_wear - pending correction is for T#<_wear_pending_tool> but T#5400 is loaded - not applied)
o110 else
	#<old_diameter_wear> = #5411 (inches)
	#<old_length_wear> = #5409 (inches)
	#<new_diameter_wear> = [#<old_diameter_wear> + #<_wear_pending_diameter>]
	#<new_length_wear> = [#<old_length_wear> + #<_wear_pending_length>]
	G10 L1 P#5400 I[U_INCH[#<new_diameter_wear>]] W[U_INCH[#<new_length_wear>]]
	G43 H#5400
	(DEBUG, T#5400 length wear #<old_length_wear> to #<new_length_wear> in)
	(DEBUG, T#5400 diameter wear #<old_diameter_wear> to #<new_diameter_wear> in)
	#<_wear_pending_tool> = 0
	#<_wear_pending_diameter> = 0
	#<_wear_pending_length> = 0
o110 endif

o<probe_apply_wear> endsub
