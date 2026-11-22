o<probe_z> sub
(probe_z: probe down in Z and set the Z origin of the measuring wcs)
(required: _first_position_to_probe, _measuring_wcs, _z_wcs_offset)

(PRINT, begin probe_z)
(PRINT, _first_position_to_probe is #<_first_position_to_probe>)
(PRINT, _measuring_wcs is #<_measuring_wcs>)
(PRINT, _z_wcs_offset is #<_z_wcs_offset>)

#<tip_r> = [[U_INCH[#5410]] / 2] (probe tip radius in program units)

G90 (set absolute mode)

(fast touch)
F#<_probe_rough_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, fast touch successful)

(back off)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z#<tip_r>
G90 (set absolute mode)

(slow touch)
F#<_probe_fine_feed_per_min>
G38.2 Z#<_first_position_to_probe>
(PRINT, slow touch successful)

(set measuring wcs at the trip point)
#<overtravel> = [#5422 - #5063] (stopped position minus trip point)
G10 L20 P#<_measuring_wcs> Z[#<_z_wcs_offset> + #<overtravel>]

(retract)
G91 (set incremental mode)
F#<_probe_rough_feed_per_min>
G38.6 Z#<tip_r>
G90 (set absolute mode)

(PRINT, end probe_z)
o<probe_z> endsub
