o<probe_z> sub
(Probe in x positive or negative direction and set 0)

(PRINT, begin probe_z probe)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _z_wcs_offset is #<_z_wcs_offset>)

G90 (set to absolute mode)

(fast probe)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, first touch successful)

(first retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z[[U_INCH[#5410]]/2]

G90 (set to absolute mode)

(slow probe)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, second touch successful)

G10 L20 P#<_measuring_wcs> Z#<_z_wcs_offset>

(second retract)
G91 (set to incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z[[U_INCH[#5410]]/2]

G90 (set to absolute mode)

(PRINT, end probe_z probe)
o<probe_z> endsub
