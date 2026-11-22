o<probe_z_for_position> sub
(probe_z_for_position: touch Z and check the height is between two limits - no WCS is set)
(retracts to G30 before checking so an out-of-range result stops with the probe clear)
(required: _first_position_to_probe, _min_allowable_position, _max_allowable_position)
(limits and the result are in the positioning wcs)

(PRINT, begin probe_z_for_position)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _min_allowable_position is #<_min_allowable_position>)
(PRINT, _max_allowable_position is #<_max_allowable_position>)

#<start_z> = #5422 (start Z in the positioning wcs)
#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)

o100 if [#<_first_position_to_probe> LT #<start_z>]
	#<dir> = -1 (probing down)
o100 else
	#<dir> = 1 (probing up)
o100 endif

G90 (set absolute mode)

(fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, slow touch successful)

#<_z_position_found> = #5063 (trip point)
(PRINT, _z_position_found is #<_z_position_found>)

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z[#<tip_r> * #<dir> * -1]
G90 (set absolute mode)

G30

o200 if [#<_z_position_found> GT #<_max_allowable_position>]
	(DEBUG, probed Z #<_z_position_found> is above the maximum #<_max_allowable_position>)
	(ABORT, Probed Z value of #<_z_position_found> is greater than maximum allowed value #<_max_allowable_position>)
o200 endif

o210 if [#<_z_position_found> LT #<_min_allowable_position>]
	(DEBUG, probed Z #<_z_position_found> is below the minimum #<_min_allowable_position>)
	(ABORT, Probed Z value of #<_z_position_found> is less than minimum allowed value #<_min_allowable_position>)
o210 endif

(PRINT, end probe_z_for_position)
o<probe_z_for_position> endsub
