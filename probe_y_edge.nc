o<probe_y_edge> sub
(probe_y_edge: probe one Y edge and set the Y origin of the measuring wcs)
(the probe moves from the start position toward _first_position_to_probe)
(required: _first_position_to_probe, _measuring_wcs, _y_wcs_offset)
(optional inputs and _result_ outputs: see probe_result)

(PRINT, begin probe_y_edge)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _y_wcs_offset is #<_y_wcs_offset>)

#<_first_starting_position> = #5421 (start Y in the positioning wcs)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, _first_starting_position is #<_first_starting_position>)

o100 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	#<dir> = 1 (probing toward +Y)
o100 else
	#<dir> = -1 (probing toward -Y)
o100 endif

G90 (set absolute mode)

(fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Y#<_first_position_to_probe>
(PRINT, fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Y#<_first_position_to_probe>
(PRINT, slow touch successful)

#<touch_y> = #5062 (trip point)
#<edge_y> = [#<touch_y> + [#<tip_r> * #<dir>]] (the edge is one tip radius past the probe center)
(PRINT, edge_y is #<edge_y>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Y[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(compare, report, and set the measuring wcs)
o<probe_result> call [3] [0] [1] [0] [0] [#<edge_y>] [0] [0] [0]

(PRINT, end probe_y_edge)
o<probe_y_edge> endsub
