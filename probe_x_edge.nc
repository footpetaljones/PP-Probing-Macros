o<probe_x_edge> sub
(probe_x_edge: probe one X edge and set the X origin of the measuring wcs)
(the probe moves from the start position toward _first_position_to_probe)
(required: _first_position_to_probe, _measuring_wcs, _x_wcs_offset)
(optional inputs and _result_ outputs: see probe_result)

(PRINT, begin probe_x_edge)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _x_wcs_offset is #<_x_wcs_offset>)

#<_first_starting_position> = #5420 (start X in the positioning wcs)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)
(PRINT, _first_starting_position is #<_first_starting_position>)

o100 if [#<_first_position_to_probe> GT #<_first_starting_position>]
	#<dir> = 1 (probing toward +X)
o100 else
	#<dir> = -1 (probing toward -X)
o100 endif

G90 (set absolute mode)

(orient the probe for this direction - wireless probe only)
o<probe_orient> call [90 - [90 * #<dir>]]

(fast touch)
F#<_probe_rough_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 X#<_first_position_to_probe>
(PRINT, slow touch successful)

#<touch_x> = #5061 (trip point)
#<edge_x> = [#<touch_x> + [#<tip_r> * #<dir>]] (the edge is one tip radius past the probe center)
(PRINT, edge_x is #<edge_x>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 X[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(compare, report, and set the measuring wcs)
o<probe_result> call [2] [1] [0] [0] [#<edge_x>] [0] [0] [0] [0]

(PRINT, end probe_x_edge)
o<probe_x_edge> endsub
