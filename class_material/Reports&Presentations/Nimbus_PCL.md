# NIMBUS — Pocket Checklist (PCL)
### MAE 155B Group 2 | Flying Wing RC Aircraft
### Rev 1.0 — 2026-05-17

---

## LIMITATIONS

| Parameter | Value |
|---|---|
| Max gross weight (loaded) | **2.78 kg** (6.1 lb) |
| Payload (800 g package) | Secured at CG station — see W&B |
| Battery | 3S 11.1 V LiPo, 150 g |
| Stall speed V_S (loaded) | **13.3 m/s** (29.8 mph) |
| Takeoff speed V_TO | **14.9 m/s** (33.3 mph) |
| Design cruise | 20 m/s (44.7 mph) |
| Max cruise (solved) | 24 m/s (54 mph) |
| Never-exceed V_NE | **25 m/s** (56 mph) |
| Max bank angle | **51 deg** |
| Max positive load factor | **+3.8 g** |
| Max negative load factor | **–1.5 g** |
| Min turn radius | 24 m (at 20 m/s) |
| Max wind for ops | [TBD by team — suggest 7 m/s] |

---

## WEIGHT & BALANCE

> **Critical: Verify CG before every flight.**
> Flying wing SM = 4.84% — a misplaced battery or payload will make the aircraft uncontrollable.

| State | CG from nose | % MAC |
|---|---|---|
| Loaded (800 g payload) | **349.5 mm** (13.75 in) | 23.1% |
| Unloaded (no payload) | ~350.0 mm | 23.4% |
| AFT LIMIT (NP, 0% SM) | ~360 mm | 25.0% |

**Battery:** x = 111 mm from nose (current design). If SM advisor recommends adjustment, target x ≈ 462 mm for SM = 7.5%.

**Payload CG:** must be at x = 349 mm station in cargo bay.

**CG check procedure:**
1. Fully assembled (battery in, payload in, prop on)
2. Lift aircraft by two fingers at x = 349.5 mm (13.75 in from nose)
3. Aircraft must balance level ± 2 deg
4. If nose-heavy: move battery aft. If tail-heavy: move battery forward.

---

## PILOT NOTES — FLIGHT CHARACTERISTICS

### Longitudinal Modes

| Mode | Freq (wn) | Damping (ζ) | Period | Rating |
|---|---|---|---|---|
| Short period | 6.69 rad/s | 0.617 | 1.2 s | Level 1 — well damped |
| Phugoid | 0.38 rad/s | 0.055 | **~17 s** | Level 1 — **lightly damped** |

**Phugoid awareness:** The aircraft will slowly oscillate in pitch with a 17-second cycle if disturbed. It is stable but takes a long time to damp out. Apply small, slow corrections — one gentle input every 8–9 seconds. Do NOT rapidly chase the oscillation or you will amplify it.

### Lateral/Directional Modes

| Mode | Value | Rating |
|---|---|---|
| Dutch roll wn / ζ | 4.24 rad/s / 0.079 | Below Level 2 — **lightly damped** |
| Roll subsidence τ | 0.080 s | Level 1 — crisp response |
| Spiral t_double | 24.6 s | Level 1 — slow divergence |

**Dutch roll awareness:** In turns, expect mild yaw–roll coupling. Use coordinated rudder. Do not hold large aileron deflections — the roll response is crisp and will overshoot.

**Spiral:** If left in a bank without correction, aircraft will slowly steepen. Check and correct bank every 20 seconds.

### Trim

- Elevon trim: **~5 deg TE down** (nose-up trim moment needed, normal for flying wing)
- If aircraft pitches up at cruise — increase trim TE down (more trim authority needed)
- If aircraft pitches down at cruise — decrease trim TE down

---

## PRE-FLIGHT CHECKLIST

### A — VEHICLE INSPECTION
- [ ] No cracks, delamination, or damage on wing surfaces
- [ ] Spar tube fully seated through both wing panels
- [ ] Wing joint secure — no play or rocking
- [ ] Both elevon surfaces: move freely, no binding, hinges intact
- [ ] Both rudder surfaces: move freely (both vertical fins)
- [ ] Prop: no nicks, cracks, or chips — firmly seated on motor shaft
- [ ] Motor: spin by hand → bearings smooth, no grinding
- [ ] All motor mount screws tight
- [ ] Landing gear: all 3 legs secure and straight
- [ ] Payload secured in bay — no loose movement, door/cover closed

### B — BATTERY & ELECTRICAL
- [ ] Battery voltage: **≥ 11.7 V** (≥ 3.9 V/cell) before flight
- [ ] Battery connector: polarity confirmed before plugging in
- [ ] Battery strap/velcro tight — battery cannot shift in flight
- [ ] ESC wire harness routed clear of prop arc and servos
- [ ] Receiver: seated and secured

### C — TRANSMITTER
- [ ] **Transmitter power ON first** (before connecting battery)
- [ ] Correct model file selected: **NIMBUS**
- [ ] Elevon mixing: **ON** (elevator + aileron combined)
- [ ] Elevon throw: ±20 deg (verify at full deflection)
- [ ] Rudder throw: ±25 deg (verify at full deflection)
- [ ] Throttle stick: at **idle (bottom)** before battery connect
- [ ] All trims centered (or saved trim loaded from model file)

### D — BATTERY CONNECT & FUNCTION CHECK
- [ ] Call "CONNECTING BATTERY" — clear prop arc
- [ ] Connect battery — listen for ESC initialization beeps
- [ ] Wait 5 seconds — do not touch throttle
- [ ] Slowly advance throttle to 10% — motor spins up smoothly
- [ ] Return to idle

### E — CONTROL SURFACE FUNCTION CHECK
*(Have a team member confirm deflections at the aircraft)*

- [ ] Elevator UP stick → **both** elevons deflect **leading edge down / trailing edge up** ✓
- [ ] Elevator DOWN stick → **both** elevons deflect **trailing edge down** ✓
- [ ] Roll RIGHT stick → right elevon **down**, left elevon **up** ✓
- [ ] Roll LEFT stick → left elevon **down**, right elevon **up** ✓
- [ ] Rudder RIGHT → right fin deflects **right** ✓
- [ ] Rudder LEFT → left fin deflects **left** ✓
- [ ] All surfaces move to full deflection without binding

### F — RANGE CHECK
- [ ] Carry aircraft 30 m from transmitter
- [ ] Cycle all controls at full deflection — no glitching
- [ ] Return aircraft

### G — WEIGHT & BALANCE FINAL
- [ ] CG check complete — balances at **349.5 mm from nose**
- [ ] Payload mass confirmed: **800 g**
- [ ] Payload secured — cannot shift in turbulence or landing
- [ ] Battery position confirmed: **x = 111 mm** from nose

---

## TAKEOFF PROCEDURE

1. Point aircraft **directly into wind**
2. Advance throttle to **full smoothly** — hold straight with rudder
3. Aircraft lifts off near **14.9 m/s** (~30 mph) — ground incidence provides 3.2° nose-up already
4. Apply **minimal** back-stick rotation (~2.5 deg only) — do not pull aggressively
5. Maintain **+6 deg** climb angle at **11 m/s** climb speed
6. Retract/confirm no gear issues — aircraft climbs cleanly

> **Note:** Due to ground incidence (3.2° nose-up at rest), the aircraft naturally rotates onto takeoff angle. Over-rotating will cause early stall.

---

## CRUISE

- Maintain **20–24 m/s** (45–54 mph) for efficient cruise
- Target trim state: slight elevon TE down (5 deg pre-trimmed)
- Max bank in turns: **51 deg**
- Min turn radius: **24 m** — do not tighten beyond this at mission speed
- Monitor battery voltage during flight — **land if below 10.5 V** (3.5 V/cell)

---

## LANDING

1. Approach on final at **16 m/s** (36 mph) — 1.2 × V_stall
2. Reduce throttle to idle — maintain approach angle with elevator
3. Maintain runway heading with rudder
4. At 1–2 m AGL: gentle back-stick flare — bleed speed to ~14 m/s
5. Aircraft contacts in **3.2° nose-up attitude** — main gear touches first
6. After main gear contact: hold elevons neutral — let nose gear settle gently
7. Do **not** hold nose up after touchdown — risk of prop strike (43 mm clearance)

---

## EMERGENCY PROCEDURES

### Motor Failure
1. Maintain **~18 m/s** (best L/D speed) — nose neutral
2. L/D ≈ 16.6 — aircraft glides well — do not zoom or pull back
3. Pick landing area into wind — declare runway
4. Land as normal — approach at 16 m/s, flare at 1–2 m AGL

### Slow Pitch Oscillation (Phugoid)
1. Identify: aircraft pitching up and down with ~17 second period
2. **Do not chase** — wait for the pitch to slow before correcting
3. Apply one small, smooth input at the peak of each cycle (up or down)
4. Two to three corrections should damp the oscillation

### Yaw–Roll Oscillation (Dutch Roll)
1. Identify: simultaneous rocking in roll and yaw
2. Release all inputs — allow to self-damp (moderately damped)
3. If it does not damp: apply small coordinated rudder opposite to yaw
4. Do not apply aileron — this excites dutch roll further

### Uncommanded Roll / Spiral Dive
1. Identify: aircraft slowly steepening into a bank without input
2. This is spiral mode — apply aileron toward raised wing
3. Level the wings and resume cruise — spiral takes ~25 seconds to become significant

---

## ABORT CRITERIA — DO NOT FLY IF

- [ ] CG outside range (not balancing at 349.5 mm from nose ± 5 mm)
- [ ] Battery below 11.7 V before flight
- [ ] Any control surface binding or reversed deflection
- [ ] Prop damage (any chip, crack, or imbalance)
- [ ] Payload not secured / shifting in bay
- [ ] Wind above [TBD] m/s
- [ ] Any ESC glitch or motor irregularity during function check
- [ ] SM advisory shows negative SM (aircraft near or past neutral point)

---

## QUICK-REFERENCE DATA CARD

```
NIMBUS II — MAE 155B Group 2
------------------------------
WEIGHTS
  MTOW (loaded)   2.78 kg   6.1 lb
  Payload         0.80 kg   1.8 lb
  Empty           1.65 kg   3.6 lb

SPEEDS
  V_stall         13.3 m/s  29.8 mph
  V_TO            14.9 m/s  33.3 mph
  V_cruise        20 m/s    44.7 mph
  V_cruise max    24 m/s    54 mph
  V_NE            25 m/s    56 mph
  V_approach      16 m/s    36 mph  (1.2 Vs)
  V_best_LD       ~18 m/s   40 mph

GEOMETRY
  Span            1572 mm   61.9 in
  Root chord      236.5 mm  9.31 in
  CG (loaded)     349.5 mm  13.75 in from nose
  Battery x       111 mm    4.37 in from nose
  Main gear x     387 mm    15.24 in from nose
  Spar diameter   10 mm     (0.39 in)

STABILITY (AVL)
  Static margin   4.84%     (target 5-10%)
  Short period    wn=6.69, zeta=0.62  LEVEL 1
  Phugoid         T=17 s, zeta=0.055  LEVEL 1
  Dutch roll      wn=4.24, zeta=0.079 BELOW L2
  Spiral          t_x2=24.6 s         LEVEL 1

PROPULSION
  Motor           1100 KV
  Battery         3S 11.1 V LiPo
  Prop            10x4.5 APC MR
  Max current     35 A
  Batt min (fly)  10.5 V  (3.5 V/cell)
  Batt min (pre)  11.7 V  (3.9 V/cell)

CONTROL THROWS
  Elevon          +/- 20 deg
  Rudder          +/- 25 deg
  Trim (elevon)   +5 deg TE down
  Max bank        51 deg
  Min turn r      24 m
```

---

*Generated from MAE 155B Group 2 MATLAB pipeline — Rev 1.0 (2026-05-17)*
*Verify all values against latest `outputs/manufacturing_dimensions.txt` before flight day*
