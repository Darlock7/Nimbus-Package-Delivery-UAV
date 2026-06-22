<div align="center">

# NIMBUS

**UC San Diego · MAE 155B Aircraft Design · Spring 2026**

RC fixed-wing aircraft designed and optimized from scratch for a package delivery competition profit function.

![MATLAB](https://img.shields.io/badge/MATLAB-R2024b-orange?logo=mathworks&logoColor=white)
![Team](https://img.shields.io/badge/Team-6%20engineers-blue)
![Course](https://img.shields.io/badge/MAE%20155B-UCSD-gold)
![Status](https://img.shields.io/badge/Status-Flight%20Tested-brightgreen)

<br>

<img src="assets/images/Final_CAD.png" width="780"/>

<br>

<img src="assets/images/Final_CAD_2.png" width="49%"/> <img src="assets/images/Final_CAD_3.png" width="49%"/>

<br>

<img src="assets/images/IMG_7501.JPG" width="780"/>

<br>

<img src="assets/images/DSC_0167.JPG" width="32%"/> <img src="assets/images/DSC_0188.JPG" width="32%"/> <img src="assets/images/team2c.JPG" width="32%"/>

<img src="assets/images/IMG_7110.JPG" width="49%"/> <img src="assets/images/DSC_0225.JPG" width="49%"/>

<br>

<img src="assets/images/DSC_0219.JPG" width="680"/>

**Harshil Patel · John Sigafoos · Angel Ochoa · Juan Sanchez · Sara Chowdhury · Analisa Veloz**

*Group 2 — MAE 155B Aircraft Design, UC San Diego, Spring 2026*

</div>

---

## Overview

Nimbus is a swept flying-wing RC aircraft built around an end-to-end MATLAB analysis pipeline. The design is driven by a CMA-ES global optimizer that maximizes a competition profit score — trading off payload volume, cruise efficiency, structural weight, and aerodynamic performance. All subsystems (aerodynamics, propulsion, stability, structure, economics) are modeled from scratch and tightly coupled.

The aircraft was manufactured by the team and completed flight testing at Mission Bay Park, San Diego, in Spring 2026.

---

## Aircraft Specifications

| Parameter | Value | Unit |
|---|---|---|
| **Geometry** | | |
| Wingspan (full) | 1.5715 | m |
| Wing area | 0.3087 | m² |
| Aspect ratio | 8.0 | — |
| Taper ratio | 0.661 | — |
| Quarter-chord sweep | 28.3 | deg |
| Root / Tip chord | 0.2365 / 0.1563 | m |
| MAC | 0.1992 | m |
| Root airfoil | Eppler 222 | — |
| Tip airfoil | Eppler 230 | — |
| Geometric washout | −4.04 (Panknin) | deg |
| **Mass & Weights** | | |
| MTOW (loaded) | 2.78 | kg |
| Empty weight | 1.68 | kg |
| Payload | 800 | g |
| **Performance** | | |
| Design cruise speed | 20.0 | m/s |
| Stall speed (loaded) | 13.3 | m/s |
| Takeoff speed | 14.9 | m/s |
| Wing loading W/S | 87.4 | N/m² |
| Static thrust (bench-corrected) | 10.2 | N |
| Static thrust-to-weight | 0.36 | — |
| Cruise L/D | 14.34 | — |
| Min turn radius | 33.0 | m |
| Max bank angle | 51.0 | deg |
| **Propulsion** | | |
| Motor | SunnySky X2216 V3, 1100 KV | — |
| Propeller | APC 10×4.7SF | — |
| Battery | 3S LiPo, 11.1 V | — |
| Mission energy | 16.5 | Wh |
| Energy with reserve | 19.0 | Wh |
| **Stability** | | |
| Static margin (AVL) | 4.88 | % MAC |
| CG location (loaded) | 23.14 | % MAC |
| Trim elevon | 5.01 | deg |
| Short-period ωₙ / ζ | 6.68 / 0.62 | rad/s / — |
| Dutch roll ωₙ / ζ | 4.24 / 0.08 | rad/s / — |
| **Structure** | | |
| Spar material | Carbon fiber tube | — |
| Selected spar diameter | 10 | mm |
| Root bending moment (3.8g) | 5.05 | N·m |
| Bending factor of safety | 3.89 | — |
| **Economics** | | |
| Payload volume | 5 | L |
| Profit rate (800 g payload) | **2.70** | $/hr |

---

## Profit Optimizer

*Pipeline architecture and implementation by Juan Sanchez.*

The core of the design process is a **Covariance Matrix Adaptation Evolution Strategy (CMA-ES)** optimizer implemented from scratch in MATLAB — no toolboxes, no `fmincon`. CMA-ES was chosen specifically because the objective landscape is non-convex, non-smooth, and includes discontinuous constraint boundaries: gradient methods fail here. The algorithm adapts its search covariance matrix generation-over-generation, efficiently navigating a 13-dimensional design space.

**Design variables (13):** aspect ratio, taper ratio, quarter-chord sweep, root twist, wing loading, CG position (x_LE), vertical fin AR/taper/sweep, cruise speed, cargo volume, and fuselage half-width and length.

Each candidate design is fully evaluated through a **physics-in-the-loop** chain — every single function evaluation runs the complete MATLAB pipeline:

| Step | Module |
|---|---|
| 1 | Wing and fin geometry generation |
| 2 | Component mass buildup + inertia tensor |
| 3 | Airfoil surrogate (XFOIL) + aerodynamic polar |
| 4 | CTOL constraint checks (stall, takeoff ground roll, climb T/W, turn T/W) |
| 5 | AVL dynamic stability — eigenvalue analysis for all six modes |

Constraints are split into two tiers. Hard geometric/performance constraints (stall speed, takeoff distance, wingspan limit) cause immediate candidate rejection. Handling-quality violations (static margin band, short-period damping, phugoid stability, Dutch roll, trim authority) are applied as soft quadratic penalties per MIL-STD-1797 Level 1/2 thresholds — the optimizer penalizes rather than rejects, so it can trade stability margin against profit.

<div align="center">
<img src="assets/images/optimizer_block_diagram.png" width="520"/>
</div>

The optimizer ran for approximately **13,000 function evaluations** using `parfor` parallelization across candidates. The converged design point — AR = 8.0, W/S = 87.4 N/m², T/W = 0.28 — was used as the starting point for detailed design, yielding a final profit score of **$2.70/hr** under competition scoring rules.

Battery position is a key optimizer degree of freedom: shifting the pack forward lowers the static margin, reducing tail-trim drag and improving L/D, but tightens the SM constraint floor. The plot below shows this trade directly.

<div align="center">
<img src="assets/plots/SM_vs_Battery_Position.png" width="600"/>
</div>

---

## Package Deployment System

*Design and analysis by John Sigafoos.*

The PDS is a clamshell cargo door on the underside of the MH95 fuselage, designed to release a 300 g payload during cruise. The door hinge sits at 80% of the fuselage chord (x = 0.761 m from nose), with dual linear rail guides ensuring controlled opening geometry.

A custom **2D Hess-Smith source panel method** (200 panels) was implemented to model the fuselage Cp distribution at cruise and evaluate whether aerodynamic back-pressure at the door opening would impede package release. The analysis found that back-pressure force (22.98 N) exceeds package weight (2.94 N) at all door angles — confirming that a **spring-assisted ejection mechanism** is required.

| Parameter | Value | Unit |
|---|---|---|
| Cargo bay dimensions | 0.625 × 0.149 × 0.114 | m (L × W × H) |
| Cargo bay volume | ~10.6 | L |
| Package mass (drop item) | 300 | g |
| Door type | Clamshell, hinged at x/c = 0.80 | — |
| Analysis method | Hess-Smith 2D source panel (200 panels) | — |
| Dynamic pressure at cruise | 246.8 | Pa |
| Aero back-pressure force | **22.98** | N |
| Package weight | **2.94** | N |
| Deployment mode | Spring-assisted ejection | — |
| Min geometric door angle | 5.2 | deg |

<div align="center">

<img src="assets/images/Cross_section_PDS2.png" width="780"/>

<br>

<img src="assets/images/Cross_section_PDS_3.png" width="49%"/> <img src="assets/images/Cross_section_PDS.png" width="49%"/>

<br>

<img src="assets/images/DoorRails2.png" width="780"/>

<br>

<img src="assets/images/DoorRails.png" width="600"/>

*Dual rail guides and clamshell actuation detail*

</div>

**[Technical Drawing — Nimbus V3 (PDF)](assets/images/Nimbus%20V3%20Drawings.pdf)**

---

## Analysis Plots

*Run `export_plots.m` to auto-generate all figures into `assets/plots/`.*

### 3D Aircraft Geometry

<div align="center">
<img src="assets/plots/Aircraft_Geometry_3D_View.png" width="700"/>
</div>

---

### CTOL Constraint Diagram

<div align="center">
<img src="assets/plots/CTOL_Constraint_Diagram.png" width="650"/>
</div>

Design point: W/S = 71.5 N/m², T/W = 0.474, governed by the takeoff constraint. Available T/W at climb speed = 0.54 (14% margin).

---

### V-n Diagram — Maneuver and Gust Envelope

<div align="center">
<img src="assets/plots/V-n_Diagram_Maneuver_Envelope.png" width="650"/>
</div>

| | Value |
|---|---|
| Positive limit load factor | +3.8 g |
| Negative limit load factor | −1.5 g |
| Maneuver speed Vₐ | 24.1 m/s |
| Gust delta-n at Vc (9.1 m/s gust) | ±4.8 g |

---

### Airfoil Polars — Root (E222) and Tip (E230)

<div align="center">
<img src="assets/plots/Airfoil_Lift_Curve_Root_Tip.png" width="49%"/> <img src="assets/plots/Airfoil_Drag_Polar_Root_Tip.png" width="49%"/>
</div>

Evaluated via XFOIL surrogate at Re_root = 3.15×10⁵, Re_tip = 2.08×10⁵.

---

### Aircraft Polar — Lift Curve and Drag Polar

<div align="center">
<img src="assets/plots/Lift_Curve_CL_vs_Alpha.png" width="49%"/> <img src="assets/plots/Drag_Polar_CL_vs_CD.png" width="49%"/>
</div>

---

### Drag Build-Up

<div align="center">
<img src="assets/plots/Drag_Build-Up.png" width="600"/>
</div>

---

### Spanwise Lift and Twist

<div align="center">
<img src="assets/plots/Spanwise_Section_Lift_Coefficient.png" width="49%"/> <img src="assets/plots/Spanwise_Twist_Distribution.png" width="49%"/>
</div>

---

### Mission Profile

<div align="center">
<img src="assets/plots/Mission_Profile_3D.png" width="680"/>
<img src="assets/plots/Altitude_vs_Time.png" width="600"/>
</div>

---

### Propulsion — APC 10×4.7SF

<div align="center">
<img src="assets/plots/Thrust_vs_Speed_10x47.png" width="49%"/> <img src="assets/plots/Prop_Coefficients_10x47.png" width="49%"/>
</div>

---

### Profit Score vs. Payload Weight

<div align="center">
<img src="assets/plots/Profit_vs_Payload_Weight.png" width="600"/>
</div>

Optimal payload: 1200 g (J = $12.53/hr, SM = 13.9%). Design carries 800 g (J = $2.70/hr) to keep stall speed within the runway constraint.

---

<details>
<summary>Additional supporting plots</summary>

<br>

<div align="center">
<img src="assets/plots/Airfoil_Drag_Curve_Root_Tip.png" width="49%"/> <img src="assets/plots/Airfoil_LD_Ratio_Root_Tip.png" width="49%"/>
<img src="assets/plots/Airfoil_Pitching_Moment_Curve_Root_Tip.png" width="49%"/> <img src="assets/plots/Lift-to-Drag_vs_Alpha.png" width="49%"/>
<img src="assets/plots/Current_Draw_10x47.png" width="49%"/>
<br><br>
<img src="assets/plots/Spanwise_Chord_Distribution.png" width="49%"/> <img src="assets/plots/Spanwise_Effective_Angle_of_Attack.png" width="49%"/>
<img src="assets/plots/Spanwise_Lift_per_Unit_Span.png" width="49%"/> <img src="assets/plots/Spanwise_Zero-Lift_Pitching_Moment.png" width="49%"/>
</div>

</details>

---

<details>
<summary>Analysis pipeline</summary>

<br>

`main.m` runs every module in sequence:

| Module | Description |
|---|---|
| Weight sizing | Empty-weight fraction model with payload volume penalty |
| Mission energy | Climb + cruise + reserve from L/D and propulsive efficiency |
| Profit score | Competition J(x) — first-pass and physics-corrected |
| Mission profile | Lap geometry, runway, climb/descent distances |
| Propulsion | Thrust curve from motor KV + APC propeller surrogate |
| CTOL sizing | Constraint diagram: wing loading vs. thrust-to-weight |
| Wing geometry | Span, root/tip chord, MAC, elevon coordinates |
| Airfoil analysis | XFOIL surrogate database — interpolated at cruise Re |
| Twist distribution | Panknin method for spanwise washout |
| Vertical surfaces | Twin delta fin geometry and sizing |
| Drag polar | Raymer-style CD₀ build-up — wing, body, fins |
| Spanwise aero | Lift distribution across the span |
| Mass properties | Component-level CG and inertia tensor (CAD-imported) |
| Static stability | Neutral point and static margin (% MAC) |
| V-n diagram | Maneuver and gust load envelope |
| Dynamic stability | AVL eigenvalue analysis — short period, phugoid, Dutch roll, roll, spiral |
| Control surfaces | Trim deflection, max load factor, hinge moments, turn radius |
| Structure sizing | Spar bending, deflection, shear, landing impact |
| Monte Carlo | Profit sensitivity to design variable uncertainty |
| Profit optimizer | Full CMA-ES aircraft optimizer |

</details>

---

<details>
<summary>Code structure</summary>

<br>

```
MAE155B-Aircraft-Design/
├── main.m                    ← Entry point
├── run_project.m             ← Adds src/ to MATLAB path (run first)
├── export_plots.m            ← Saves all figures to assets/plots/
│
├── src/
│   ├── aerodynamics/         ← Airfoil surrogates, drag polar, spanwise aero, twist
│   ├── geometry/             ← Wing, winglet, fuselage geometry
│   ├── Stability/            ← Static/dynamic stability, CG, AVL interface
│   ├── propulsion/           ← Motor + propeller analysis and surrogate models
│   ├── energy/               ← Energy and battery sizing
│   ├── mission/              ← Flight performance and lap geometry
│   └── economics/            ← Profit function and CMA-ES optimizer
│
├── plotting/                 ← Visualization functions
├── data/
│   ├── airfoils/             ← Airfoil .dat files (XFOIL format)
│   ├── models/               ← Precomputed XFOIL surrogate database (.mat)
│   └── propellers/           ← APC propeller performance tables
│
├── AVL/Nimbus/               ← AVL executable + auto-generated geometry files
├── CFD/                      ← CFD surface model (.step, Fluent files)
├── assets/
│   ├── images/               ← Flight photos and CAD renders
│   └── plots/                ← MATLAB-generated figures (via export_plots.m)
└── outputs/                  ← Generated results (gitignored)
```

</details>

---

## How to Run

```matlab
% Set MATLAB working directory to repo root, then:
run_project   % adds src/ to path
main          % executes full analysis pipeline (~30 s)
```

Run flags at the top of `main.m` toggle optional long-running sections:

```matlab
showPlots       = true;    % show all figures
runProfitOpt    = false;   % CMA-ES aircraft optimizer  (~6–10 hrs)
runMonteCarlo   = false;   % profit sensitivity analysis (~30 s)
runCSopt        = false;   % control surface optimizer
runSweep        = false;   % dynamic stability parameter sweep
```

Export all plots for this portfolio page:

```
matlab -batch "run('run_project.m'); run('export_plots.m')"
```
