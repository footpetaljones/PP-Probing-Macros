o<probe_result> sub
(probe_result: shared result step called by every probing macro after its touches)
(call it with the positioning wcs active - it compares the feature with its nominal in the measuring wcs,)
(sets the _result_ outputs, shows them with DEBUG, checks tolerances, logs, and updates the measuring wcs)
(arguments: #1 macro code, #2 has X, #3 has Y, #4 has Z, #5 X, #6 Y, #7 Z - feature in the positioning wcs)
(#8 measured size, #9 size type: 0 none, 1 internal - bore or pocket, 2 external - boss)
(macro codes: 1 z, 2 x_edge, 3 y_edge, 4 xy_corner, 5 x_pocket, 6 y_pocket, 7 x_boss, 8 y_boss)
(9 circular_bore, 10 circular_boss, 11 bore_three_point, 12 boss_three_point, 13 circular_bore_island)
(wear corrections for cut-measure-cut are stored as pending and written by probe_apply_wear)

#<macro> = #1
#<has_x> = #2
#<has_y> = #3
#<has_z> = #4
#<feature_x> = #5
#<feature_y> = #6
#<feature_z> = #7
#<size> = #8
#<size_type> = #9

(optional inputs - values of 0 mean off; per-feature inputs are cleared at the end of this step)
#<set_wcs> = 1
o100 if [EXISTS[#<_set_wcs>]]
	#<set_wcs> = #<_set_wcs>
o100 endif
#<display> = 1
o101 if [EXISTS[#<_display_results>]]
	#<display> = #<_display_results>
o101 endif
#<log> = 0
o102 if [EXISTS[#<_log_results>]]
	#<log> = #<_log_results>
o102 endif
#<action> = 1
o103 if [EXISTS[#<_tolerance_action>]]
	#<action> = #<_tolerance_action>
o103 endif
#<feature_number> = 0
o104 if [EXISTS[#<_feature_number>]]
	#<feature_number> = #<_feature_number>
o104 endif
#<nominal_size> = 0
o105 if [EXISTS[#<_nominal_size>]]
	#<nominal_size> = #<_nominal_size>
o105 endif
#<tolerance_plus> = 0
o106 if [EXISTS[#<_size_tolerance_plus>]]
	#<tolerance_plus> = ABS[#<_size_tolerance_plus>]
o106 endif
#<tolerance_minus> = 0
o107 if [EXISTS[#<_size_tolerance_minus>]]
	#<tolerance_minus> = ABS[#<_size_tolerance_minus>]
o107 endif
#<position_tolerance> = 0
o108 if [EXISTS[#<_position_tolerance>]]
	#<position_tolerance> = ABS[#<_position_tolerance>]
o108 endif
#<update_wcs_minimum> = 0
o109 if [EXISTS[#<_update_wcs_minimum>]]
	#<update_wcs_minimum> = ABS[#<_update_wcs_minimum>]
o109 endif
#<update_wcs_maximum> = 0
o110 if [EXISTS[#<_update_wcs_maximum>]]
	#<update_wcs_maximum> = ABS[#<_update_wcs_maximum>]
o110 endif
#<update_tool_minimum> = 0
o115 if [EXISTS[#<_update_tool_minimum>]]
	#<update_tool_minimum> = ABS[#<_update_tool_minimum>]
o115 endif
#<update_tool> = 0
o111 if [EXISTS[#<_update_tool>]]
	#<update_tool> = #<_update_tool>
o111 endif
#<feedback> = 1
o112 if [EXISTS[#<_update_feedback>]]
	#<feedback> = #<_update_feedback>
o112 endif
o113 if [[#<feedback> LE 0] OR [#<feedback> GT 1]]
	#<feedback> = 1 (0 or out of range means full correction)
o113 endif
o114 if [[#<update_tool> GT 0] AND #<has_z>]
	#<set_wcs> = 0 (a Z touch used for length wear does not also move the wcs)
o114 endif

(offset from the positioning wcs to the measuring wcs - no motion while switched)
#<positioning_wcs> = #5220
#<position_x> = #5420
#<position_y> = #5421
#<position_z> = #5422
G54.1 P#<_measuring_wcs>
#<to_measuring_x> = [#5420 - #<position_x>]
#<to_measuring_y> = [#5421 - #<position_y>]
#<to_measuring_z> = [#5422 - #<position_z>]
G54.1 P#<positioning_wcs>

(feature in the measuring wcs and deviation from nominal)
#<_result_x> = [#<feature_x> + #<to_measuring_x>]
#<_result_y> = [#<feature_y> + #<to_measuring_y>]
#<_result_z> = [#<feature_z> + #<to_measuring_z>]
#<_result_x_dev> = 0
#<_result_y_dev> = 0
#<_result_z_dev> = 0
o120 if [#<has_x>]
	#<_result_x_dev> = [#<_result_x> - #<_x_wcs_offset>]
o120 endif
o121 if [#<has_y>]
	#<_result_y_dev> = [#<_result_y> - #<_y_wcs_offset>]
o121 endif
o122 if [#<has_z>]
	#<_result_z_dev> = [#<_result_z> - #<_z_wcs_offset>]
o122 endif
(true position: diameter of the zone around the nominal that holds the feature, 2 x its distance from nominal)
(unmeasured axes have a deviation of 0, so a single-axis feature gives 2 x its one deviation)
#<_result_tp_dev> = [2 * SQRT[[#<_result_x_dev> * #<_result_x_dev>] + [#<_result_y_dev> * #<_result_y_dev>] + [#<_result_z_dev> * #<_result_z_dev>]]]
#<largest_position_dev> = ABS[#<_result_x_dev>]
o124 if [ABS[#<_result_y_dev>] GT #<largest_position_dev>]
	#<largest_position_dev> = ABS[#<_result_y_dev>]
o124 endif
o125 if [ABS[#<_result_z_dev>] GT #<largest_position_dev>]
	#<largest_position_dev> = ABS[#<_result_z_dev>]
o125 endif

#<_result_size> = #<size>
#<_result_size_dev> = 0
#<size_check> = [[#<size_type> GT 0] AND [#<nominal_size> GT 0]]
o130 if [#<size_check>]
	#<_result_size_dev> = [#<size> - #<nominal_size>]
o130 endif

(status: 0 ok, 1 size out - material left, 2 size out - material missing, 3 position out, 4 over update maximum)
#<_result_size_status> = 0
o140 if [#<size_check> AND [[#<tolerance_plus> GT 0] OR [#<tolerance_minus> GT 0]]]
	#<oversize> = [#<_result_size_dev> GT #<tolerance_plus>]
	#<undersize> = [#<_result_size_dev> LT [#<tolerance_minus> * -1]]
	o141 if [#<oversize> OR #<undersize>]
		#<_result_size_status> = 2
		o142 if [[[#<size_type> EQ 1] AND #<undersize>] OR [[#<size_type> EQ 2] AND #<oversize>]]
			#<_result_size_status> = 1
		o142 endif
	o141 endif
o140 endif
#<_result_position_status> = 0
o143 if [[#<position_tolerance> GT 0] AND [#<_result_tp_dev> GT #<position_tolerance>]]
	#<_result_position_status> = 1
o143 endif
(the wcs maximum only applies when the wcs is being set)
#<over_maximum> = 0
o144 if [[#<update_wcs_maximum> GT 0] AND [#<set_wcs> EQ 1]]
	o145 if [[#<largest_position_dev> GT #<update_wcs_maximum>] OR [ABS[#<_result_size_dev>] GT #<update_wcs_maximum>]]
		#<over_maximum> = 1
	o145 endif
o144 endif
#<_result_status> = 0
o146 if [#<_result_size_status> EQ 1]
	#<_result_status> = 1
o146 endif
o147 if [#<_result_position_status> EQ 1]
	#<_result_status> = 3
o147 endif
o148 if [#<_result_size_status> EQ 2]
	#<_result_status> = 2
o148 endif
o149 if [#<over_maximum>]
	#<_result_status> = 4
o149 endif

(display - the Status tab lists newest first, so lines are sent bottom-up)
o200 if [#<display> EQ 1]
	o230 if [#<position_tolerance> GT 0]
		(DEBUG,   true position #<_result_tp_dev>   tolerance #<position_tolerance>)
	o230 endif
	o201 if [#<has_z>]
		(DEBUG,   Z #<_result_z>   nominal #<_z_wcs_offset>   dev #<_result_z_dev>)
	o201 endif
	o202 if [#<has_y>]
		(DEBUG,   Y #<_result_y>   nominal #<_y_wcs_offset>   dev #<_result_y_dev>)
	o202 endif
	o203 if [#<has_x>]
		(DEBUG,   X #<_result_x>   nominal #<_x_wcs_offset>   dev #<_result_x_dev>)
	o203 endif
	o204 if [#<size_type> GT 0]
		o205 if [#<size_check>]
			(DEBUG,   size #<_result_size>   nominal #<nominal_size>   dev #<_result_size_dev>)
		o205 else
			(DEBUG,   size #<_result_size>)
		o205 endif
	o204 endif
	o206 if [#<_result_status> EQ 0]
		(DEBUG,   result OK)
	o206 endif
	o207 if [#<_result_status> EQ 1]
		(DEBUG,   SIZE OUT OF TOLERANCE - material left, rework possible)
	o207 endif
	o208 if [#<_result_status> EQ 2]
		(DEBUG,   SIZE OUT OF TOLERANCE - material missing, scrap)
	o208 endif
	o209 if [#<_result_status> EQ 3]
		(DEBUG,   POSITION OUT OF TOLERANCE - true position over #<position_tolerance>)
	o209 endif
	o210 if [#<_result_status> EQ 4]
		(DEBUG,   DIFFERENCE OVER THE WCS UPDATE MAXIMUM #<update_wcs_maximum>)
	o210 endif
	o211 if [#<macro> EQ 1]
		(DEBUG, probe_z  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o211 endif
	o212 if [#<macro> EQ 2]
		(DEBUG, probe_x_edge  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o212 endif
	o213 if [#<macro> EQ 3]
		(DEBUG, probe_y_edge  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o213 endif
	o214 if [#<macro> EQ 4]
		(DEBUG, probe_xy_corner  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o214 endif
	o215 if [#<macro> EQ 5]
		(DEBUG, probe_x_pocket  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o215 endif
	o216 if [#<macro> EQ 6]
		(DEBUG, probe_y_pocket  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o216 endif
	o217 if [#<macro> EQ 7]
		(DEBUG, probe_x_boss  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o217 endif
	o218 if [#<macro> EQ 8]
		(DEBUG, probe_y_boss  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o218 endif
	o219 if [#<macro> EQ 9]
		(DEBUG, probe_circular_bore  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o219 endif
	o220 if [#<macro> EQ 10]
		(DEBUG, probe_circular_boss  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o220 endif
	o221 if [#<macro> EQ 11]
		(DEBUG, probe_bore_three_point  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o221 endif
	o222 if [#<macro> EQ 12]
		(DEBUG, probe_boss_three_point  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o222 endif
	o223 if [#<macro> EQ 13]
		(DEBUG, probe_circular_bore_island  feature #<feature_number>  G54.1 P#<_measuring_wcs>)
	o223 endif
o200 endif

(out of tolerance: 0 flag only, 1 retract to G30 and pause, 2 retract to G30 and abort after logging)
#<abort_after_log> = 0
o300 if [[#<_result_status> GT 0] AND [#<action> GT 0]]
	G90 (set absolute mode)
	G30 Z#5422 (retract Z only to the G30 height)
	G30 (move to the G30 position)
	o301 if [#<action> EQ 2]
		#<abort_after_log> = 1
	o301 else
		M0 (feature out of tolerance)
		M66 P0 L0 (queue buster - nothing below runs until cycle start)
	o301 endif
o300 endif

(update the measuring wcs - axes inside the wcs update minimum are left unchanged)
#<wcs_updated> = 0
#<wcs_held> = 0
o400 if [[#<set_wcs> EQ 1] AND [#<over_maximum> EQ 0] AND [#<abort_after_log> EQ 0]]
	o401 if [#<has_x> AND [ABS[#<_result_x_dev>] GE #<update_wcs_minimum>]]
		G10 L20 P#<_measuring_wcs> X[#5420 + #<to_measuring_x> - #<_result_x_dev>]
		#<wcs_updated> = 1
	o401 endif
	o402 if [#<has_y> AND [ABS[#<_result_y_dev>] GE #<update_wcs_minimum>]]
		G10 L20 P#<_measuring_wcs> Y[#5421 + #<to_measuring_y> - #<_result_y_dev>]
		#<wcs_updated> = 1
	o402 endif
	o403 if [#<has_z> AND [ABS[#<_result_z_dev>] GE #<update_wcs_minimum>]]
		G10 L20 P#<_measuring_wcs> Z[#5422 + #<to_measuring_z> - #<_result_z_dev>]
		#<wcs_updated> = 1
	o403 endif
	o404 if [#<has_x> AND [ABS[#<_result_x_dev>] LT #<update_wcs_minimum>]]
		#<wcs_held> = 1
	o404 endif
	o405 if [#<has_y> AND [ABS[#<_result_y_dev>] LT #<update_wcs_minimum>]]
		#<wcs_held> = 1
	o405 endif
	o406 if [#<has_z> AND [ABS[#<_result_z_dev>] LT #<update_wcs_minimum>]]
		#<wcs_held> = 1
	o406 endif
o400 endif
#<_result_wcs_set> = #<wcs_updated>

(wear correction for _update_tool - stored as pending until probe_apply_wear runs with that tool loaded)
(internal size: diameter wear + error, external size: diameter wear - error, Z face: length wear - error)
#<wear_kind> = 0 (1 diameter, 2 length)
#<wear_correction> = 0 (program units)
#<wear_skipped> = 0 (1 under the tool minimum, 2 no size or Z, 3 aborted)
o420 if [#<update_tool> GT 0]
	o421 if [#<abort_after_log>]
		#<wear_skipped> = 3
	o421 elseif [#<size_check>]
		o422 if [ABS[#<_result_size_dev>] LT #<update_tool_minimum>]
			#<wear_skipped> = 1
		o422 elseif [#<size_type> EQ 1]
			#<wear_kind> = 1
			#<wear_correction> = [#<_result_size_dev> * #<feedback>]
		o422 else
			#<wear_kind> = 1
			#<wear_correction> = [#<_result_size_dev> * #<feedback> * -1]
		o422 endif
	o421 elseif [#<has_z> AND [#<has_x> EQ 0]]
		o423 if [ABS[#<_result_z_dev>] LT #<update_tool_minimum>]
			#<wear_skipped> = 1
		o423 else
			#<wear_kind> = 2
			#<wear_correction> = [#<_result_z_dev> * #<feedback> * -1]
		o423 endif
	o421 else
		#<wear_skipped> = 2
	o421 endif
o420 endif
o430 if [#<wear_kind> GT 0]
	o431 if [EXISTS[#<_wear_pending_tool>] EQ 0]
		#<_wear_pending_tool> = 0
		#<_wear_pending_diameter> = 0
		#<_wear_pending_length> = 0
	o431 endif
	o432 if [[#<_wear_pending_tool> NE 0] AND [#<_wear_pending_tool> NE #<update_tool>]]
		(DEBUG, pending wear correction for T#<_wear_pending_tool> was never applied - replaced)
		#<_wear_pending_diameter> = 0
		#<_wear_pending_length> = 0
	o432 endif
	#<_wear_pending_tool> = #<update_tool>
	o433 if [#<wear_kind> EQ 1]
		#<_wear_pending_diameter> = [#<_wear_pending_diameter> + [#<wear_correction> / U_INCH[1]]]
	o433 else
		#<_wear_pending_length> = [#<_wear_pending_length> + [#<wear_correction> / U_INCH[1]]]
	o433 endif
o430 endif

o410 if [#<display> EQ 1]
	o440 if [#<wear_kind> EQ 1]
		(DEBUG, T#<update_tool> diameter wear #<wear_correction> pending - call probe_apply_wear after the tool change)
	o440 endif
	o441 if [#<wear_kind> EQ 2]
		(DEBUG, T#<update_tool> length wear #<wear_correction> pending - call probe_apply_wear after the tool change)
	o441 endif
	o442 if [#<wear_skipped> EQ 1]
		(DEBUG, T#<update_tool> wear not changed - difference under the tool minimum #<update_tool_minimum>)
	o442 endif
	o443 if [#<wear_skipped> EQ 2]
		(DEBUG, T#<update_tool> wear not changed - needs _nominal_size on a size feature or probe_z)
	o443 endif
	o444 if [#<wear_skipped> EQ 3]
		(DEBUG, T#<update_tool> wear not changed - aborted)
	o444 endif
	o411 if [#<set_wcs> NE 1]
		(DEBUG, G54.1 P#<_measuring_wcs> not updated - inspect only)
	o411 endif
	o412 if [[#<set_wcs> EQ 1] AND #<over_maximum>]
		(DEBUG, G54.1 P#<_measuring_wcs> not updated - difference over the wcs update maximum #<update_wcs_maximum>)
	o412 endif
	o413 if [[#<set_wcs> EQ 1] AND #<abort_after_log>]
		(DEBUG, G54.1 P#<_measuring_wcs> not updated - aborted)
	o413 endif
	o414 if [[#<set_wcs> EQ 1] AND [#<over_maximum> EQ 0] AND [#<abort_after_log> EQ 0]]
		o415 if [#<wcs_updated> AND #<wcs_held>]
			(DEBUG, G54.1 P#<_measuring_wcs> updated - axes under the wcs update minimum #<update_wcs_minimum> unchanged)
		o415 elseif [#<wcs_updated>]
			(DEBUG, G54.1 P#<_measuring_wcs> updated)
		o415 else
			(DEBUG, G54.1 P#<_measuring_wcs> not updated - difference under the wcs update minimum #<update_wcs_minimum>)
		o415 endif
	o414 endif
o410 endif

(results file - 1 append, 2 start a new file with a header row)
o500 if [#<log> EQ 2]
	(LOGOPEN,/home/operator/gcode/probe_results.csv)
	(LOG,epoch,feature,macro,wcs,set_wcs,wcs_updated,status,x_nominal,x,x_dev,y_nominal,y,y_dev,z_nominal,z,z_dev,true_position,size_nominal,size,size_dev,update_tool,wear_correction)
	(LOGCLOSE)
	#<_log_results> = 1
o500 endif
o510 if [#<log> GT 0]
	(short names keep each LOG line under the 255 character limit)
	#<t> = #<_epochtime>
	#<fn> = #<feature_number>
	#<w> = #<_measuring_wcs>
	#<sw> = #<set_wcs>
	#<up> = #<wcs_updated>
	#<st> = #<_result_status>
	#<xn> = 0
	#<yn> = 0
	#<zn> = 0
	o512 if [#<has_x>]
		#<xn> = #<_x_wcs_offset>
	o512 endif
	o513 if [#<has_y>]
		#<yn> = #<_y_wcs_offset>
	o513 endif
	o514 if [#<has_z>]
		#<zn> = #<_z_wcs_offset>
	o514 endif
	#<xm> = #<_result_x>
	#<xd> = #<_result_x_dev>
	#<ym> = #<_result_y>
	#<yd> = #<_result_y_dev>
	#<zm> = #<_result_z>
	#<zd> = #<_result_z_dev>
	#<tp> = #<_result_tp_dev>
	#<sn> = #<nominal_size>
	#<sm> = #<_result_size>
	#<sd> = #<_result_size_dev>
	#<ut> = #<update_tool>
	#<wc> = #<wear_correction>
	(LOGAPPEND,/home/operator/gcode/probe_results.csv)
	o521 if [#<macro> EQ 1]
		(LOG,#<t>,#<fn>,probe_z,#<w>,#<sw>,#<up>,#<st>,,,,,,,#<zn>,#<zm>,#<zd>,#<tp>,,,,#<ut>,#<wc>)
	o521 endif
	o522 if [#<macro> EQ 2]
		(LOG,#<t>,#<fn>,probe_x_edge,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,,,,,,,#<tp>,,,,#<ut>,#<wc>)
	o522 endif
	o523 if [#<macro> EQ 3]
		(LOG,#<t>,#<fn>,probe_y_edge,#<w>,#<sw>,#<up>,#<st>,,,,#<yn>,#<ym>,#<yd>,,,,#<tp>,,,,#<ut>,#<wc>)
	o523 endif
	o524 if [#<macro> EQ 4]
		(LOG,#<t>,#<fn>,probe_xy_corner,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,#<yn>,#<ym>,#<yd>,,,,#<tp>,,,,#<ut>,#<wc>)
	o524 endif
	o525 if [#<macro> EQ 5]
		(LOG,#<t>,#<fn>,probe_x_pocket,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,,,,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o525 endif
	o526 if [#<macro> EQ 6]
		(LOG,#<t>,#<fn>,probe_y_pocket,#<w>,#<sw>,#<up>,#<st>,,,,#<yn>,#<ym>,#<yd>,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o526 endif
	o527 if [#<macro> EQ 7]
		(LOG,#<t>,#<fn>,probe_x_boss,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,,,,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o527 endif
	o528 if [#<macro> EQ 8]
		(LOG,#<t>,#<fn>,probe_y_boss,#<w>,#<sw>,#<up>,#<st>,,,,#<yn>,#<ym>,#<yd>,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o528 endif
	o529 if [#<macro> EQ 9]
		(LOG,#<t>,#<fn>,probe_circular_bore,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,#<yn>,#<ym>,#<yd>,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o529 endif
	o530 if [#<macro> EQ 10]
		(LOG,#<t>,#<fn>,probe_circular_boss,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,#<yn>,#<ym>,#<yd>,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o530 endif
	o531 if [#<macro> EQ 11]
		(LOG,#<t>,#<fn>,probe_bore_three_point,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,#<yn>,#<ym>,#<yd>,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o531 endif
	o532 if [#<macro> EQ 12]
		(LOG,#<t>,#<fn>,probe_boss_three_point,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,#<yn>,#<ym>,#<yd>,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o532 endif
	o533 if [#<macro> EQ 13]
		(LOG,#<t>,#<fn>,probe_circular_bore_island,#<w>,#<sw>,#<up>,#<st>,#<xn>,#<xm>,#<xd>,#<yn>,#<ym>,#<yd>,,,,#<tp>,#<sn>,#<sm>,#<sd>,#<ut>,#<wc>)
	o533 endif
	(LOGCLOSE)
o510 endif

(clear the per-feature inputs so they cannot carry into the next probing call)
#<_set_wcs> = 1
#<_feature_number> = 0
#<_nominal_size> = 0
#<_size_tolerance_plus> = 0
#<_size_tolerance_minus> = 0
#<_position_tolerance> = 0
#<_update_wcs_minimum> = 0
#<_update_wcs_maximum> = 0
#<_update_tool_minimum> = 0
#<_update_tool> = 0
#<_update_feedback> = 1

o600 if [#<abort_after_log>]
	(ABORT, probing result out of tolerance - see the Status tab)
o600 endif

o<probe_result> endsub
