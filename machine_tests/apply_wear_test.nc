(apply_wear_test: checks probe_apply_wear on PathPilot - needs probe_apply_wear.nc in the subroutines folder)
(uses T12 and leaves it with no wear - Status tab lists newest first)

G20 G90 G40 G49
T12 M6
G10 L1 P12 W0.0010 I0.0020 (start: length wear .0010, diameter wear .0020)
G43 H12

(inch program: pending values are always inches)
#<_wear_pending_tool> = 12
#<_wear_pending_diameter> = -0.0005
#<_wear_pending_length> = 0.0003
o<probe_apply_wear> call
(DEBUG, A inch  - expect Dwear 0.0015 Lwear 0.0013: Dwear#5411 Lwear#5409)

(metric program: same inch pending values, written through U_INCH)
G21
#<_wear_pending_tool> = 12
#<_wear_pending_diameter> = 0.0005
#<_wear_pending_length> = -0.0003
o<probe_apply_wear> call
(DEBUG, B metric - expect Dwear 0.0020 Lwear 0.0010 again: Dwear#5411 Lwear#5409)

(wrong tool loaded: must not apply)
#<_wear_pending_tool> = 5
#<_wear_pending_diameter> = 0.1000
o<probe_apply_wear> call
(DEBUG, C wrong tool - expect Dwear 0.0020 unchanged: Dwear#5411)

G20
G10 L1 P12 W0 I0
G49
M30
