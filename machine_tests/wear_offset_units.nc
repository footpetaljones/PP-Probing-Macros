(wear_offset_units: check how PathPilot reads and writes tool wear from G-code)
(run on a sim or with the spindle clear - uses T12 and leaves T12 with no wear)
(Status tab lists newest first - note the clock time when you press Cycle Start at the M0)

G20 G90 G40 G49
T12 M6
G10 L1 P12 Z1.2345 R0.1875 W0.0031 I0.0042 (G20: length 1.2345, dia 0.375, len wear .0031, dia wear .0042)
G43 H12
(DEBUG, 1 G20 read  L#5403 D#5410 Lwear#5409 Dwear#5411 Zpos#5422 - expect 1.2345 0.375 .0031 .0042)
G21
G43 H12
(DEBUG, 2 G21 read  L#5403 D#5410 Lwear#5409 Dwear#5411 - same numbers = reads are always inch)
G10 L1 P12 W0.1016 I0.1524 (G21: .0040 in and .0060 in if converted)
G43 H12
(DEBUG, 3 G21 write Lwear#5409 Dwear#5411 - .004 .006 = converted, .1016 .1524 = written raw)
G20
M0 (check T12 Dia Wear and Len Wear on the Offsets tab, then Cycle Start)
G10 L1 P12 W0 I0 (clear the wear)
G43 H12
(DEBUG, 4 cleared   Lwear#5409 Dwear#5411 Zpos#5422 - compare Zpos with line 1)
G49
M30
