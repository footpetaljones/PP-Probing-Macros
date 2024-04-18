o<probe_z_for_position> sub
(Probe in x positive or negative direction and set 0)

(PRINT, begin probe_z probe)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs)
(PRINT, _z_wcs_offset is #<_z_wcs_offset>)

G90 (set to absolute mode)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, first touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o100 if [#<_metric> EQ 1]  
	G38.6 Z.1
	o100 else
	G38.6 Z.05
o100 endif

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, second touch successful)

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
o130 if [#<_metric> EQ 1]  
	o140 if [#<_first_position_to_probe> LT 0]
	G38.6 Z-.1
	o140 else
	GG38.6 Z.1
	o140 endif
o130 else
	o150 if [#<_first_position_to_probe> GT 0]
	G38.6 Z-.05
	o150 else
	G38.6 Z.05
	o150 endif
o130 endif

G90 (set to absolute mode)

G30

o200 if [#5063 GT #<_max_allowable_position>]
	(ABORT, Probed Z value of #5063 is greater than maximum allowed value #<_max_allowable_position>)
	o200 endif
	
o210 if [#5063 LT #<_min_allowable_position>]
	(ABORT, Probed Z value of #5063 is less than minumum allowed value #<_min_allowable_position>)
	o210 endif

(PRINT, end probe_z probe)
o<probe_z_for_position> endsub