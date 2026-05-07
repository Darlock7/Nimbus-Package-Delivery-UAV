# Nimbus — RC Aircraft Design · MAE 155B

Conceptual and preliminary design of an RC fixed-wing aircraft optimized for a package delivery profit function, developed as a 6-person team capstone project in MAE 155B at UC San Diego.

The design is driven end-to-end by a CMA-ES optimizer that maximizes a competition profit score — balancing payload volume, cruise speed, aerodynamic efficiency, and structural weight. All aerodynamic, stability, propulsion, and performance analyses are implemented from scratch in MATLAB and coupled directly to the optimizer.

---

## Aircraft Configuration

| Parameter | Value |
|---|---|
| Gross weight | ~2.25 kg |
| Payload | 800 g · 70.5 cm³ |
| Cruise speed | 20 m/s |
| Wing area | 0.309 m² |
| Aspect ratio | 8 |
| Taper ratio | 0.661 |
| Quarter-chord sweep | 28.3° |
| Fuselage length | 0.95 m |
| Wing airfoil | MH series (XFOIL surrogate) |
| Centerbody airfoil | MH95 |
| Tail configuration | Delta winglets |

---

## Analysis Pipeline

`main.m` runs every section in sequence. The full pipeline:

| Section | Description |
|---|---|
| Weight sizing | Empty-weight fraction model with payload volume penalty |
| Mission energy | Climb + cruise + reserve energy from L/D and propulsive efficiency |
| Profit score | Competition scoring function J(x) — first-pass and physics-corrected |
| Mission profile | Lap geometry, runway, climb/descent distances |
| Propulsion | Thrust curve from motor KV + APC propeller surrogate |
| CTOL sizing | Wing loading vs. thrust-to-weight constraint diagram |
| Wing geometry | Span, root/tip chord, MAC, control surface coordinates |
| Airfoil analysis | XFOIL surrogate database — interpolated at cruise Reynolds number |
| Twist distribution | Panknin method for required spanwise washout |
| Vertical surfaces | Delta winglet geometry and sizing |
| Drag polar | Raymer-style CD0 build-up — wing, body, fin, interference |
| Spanwise aero | Lift distribution across the span |
| Mass properties | Component-level CG and inertia tensor |
| Static stability | Neutral point and static margin (% MAC) |
| V-n diagram | Maneuver and gust load envelope |
| Dynamic stability | AVL eigenvalue analysis — short period, phugoid, Dutch roll, roll, spiral |
| Control surface sizing | Trim deflection, max load factor, turn radius |
| Control surface optimizer | CMA-ES elevon/rudder geometry optimizer |
| Monte Carlo | Profit sensitivity to design variable uncertainty |
| Profit optimizer | Full CMA-ES aircraft optimizer (6–10 hrs) |

---

## Code Structure

```
MAE155B-Aircraft-Design/
├── main.m                    ← Entry point — run this
├── run_project.m             ← Adds src/ to MATLAB path (run first)
│
├── src/
│   ├── aerodynamics/         ← Airfoil surrogates, drag polar, spanwise aero, twist
│   ├── geometry/             ← Wing, winglet, fuselage geometry
│   ├── Stability/            ← Static and dynamic stability, CG, AVL interface
│   ├── propulsion/           ← Motor + propeller analysis and surrogate models
│   ├── energy/               ← Energy and battery sizing
│   ├── mission/              ← Flight performance and lap geometry
│   └── economics/            ← Profit function and CMA-ES optimizer
│
├── plotting/                 ← All visualization functions
│   ├── preliminarySizingCTOL.m
│   ├── plotAircraftGeometry3D.m
│   ├── plotVNDiagram.m
│   └── ...
│
├── data/
│   ├── airfoils/             ← Airfoil .dat files (XFOIL format)
│   ├── models/               ← Precomputed XFOIL surrogate database (.mat)
│   └── propellers/           ← APC propeller performance tables
│
├── AVL/Nimbus/               ← AVL executable + auto-generated geometry files
├── CFD/                      ← CFD surface model (.step, Fluent files)
└── outputs/                  ← Generated results (gitignored)
```

---

## How to Run

```matlab
% 1. Set MATLAB working directory to repo root, then:
run_project   % adds src/ to path

% 2. Run the main script
main          % executes the full analysis pipeline
```

Run flags at the top of `main.m` toggle optional long-running sections:

```matlab
showPlots       = true;   % all figures
runProfitOpt    = false;  % CMA-ES optimizer (~6–10 hrs)
runMonteCarlo   = false;  % sensitivity analysis
runCSopt        = false;  % control surface optimizer
runSweep        = false;  % dynamic stability sweep
```

For setup instructions (SSH, git, MATLAB source control on Windows) see [`SETUP.md`](SETUP.md).

---

## Team

Group 2 — MAE 155B Aircraft Design, UC San Diego (Spring 2026)

Harshil Patel · John Sigafoos · Angel Ochoa · Juan Sanchez · Sara Chowdhury · Analisa Veloz
