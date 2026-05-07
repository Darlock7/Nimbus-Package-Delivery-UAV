function deployOut = doorDeploymentCFD(inp)
% doorDeploymentCFD  —  Aft cargo door back-pressure and deployment analysis
%
% 2D source panel method (Hess-Smith) on the MH95 fuselage longitudinal
% cross-section (side view). Computes the Cp distribution on the fuselage
% and evaluates whether aerodynamic back-pressure at the cargo door opening
% exceeds the package weight for each door angle.
%
% The door is modeled as a panel on the LOWER surface of the fuselage,
% hinged at the forward edge (x_hinge), rotating downward at angle theta.
% Deployment requires: W_package > F_back  (gravity > aerodynamic resistance)
%
% Units: SI throughout.
%
% Inputs (struct):
%   inp.airfoilFile       path to MH95 .dat airfoil file  [string]
%   inp.Lf_m              fuselage chord length  [m]
%   inp.Wf_m              fuselage body width (spanwise, for 3-D area)  [m]
%   inp.V_cruise_mps      cruise airspeed  [m/s]
%   inp.rho_kgm3          air density  [kg/m^3]
%   inp.alpha_deg         fuselage angle of attack  [deg]  (use 0 for level)
%   inp.m_package_kg      package mass  [kg]
%   inp.package_h_m       package height (vertical dimension)  [m]
%   inp.door_xfrac        door hinge x/c location (fraction of Lf, 0=nose)  [-]
%   inp.door_length_m     door panel length in fore-aft direction  [m]
%   inp.door_angles_deg   vector of door angles to evaluate  [deg]
%   inp.Npanels           number of source panels  (default: 200)
%   inp.showPlot          generate figures  [logical]
%
% Outputs (struct):
%   deployOut.Cp_vec          Cp at each panel midpoint  [-]
%   deployOut.x_mid_m         panel midpoint x-coordinates  [m]
%   deployOut.y_mid_m         panel midpoint y-coordinates  [m]
%   deployOut.Cp_at_door      Cp at door x-location (closed fuselage)  [-]
%   deployOut.F_back_N        back-pressure force vs door angle  [N]
%   deployOut.W_package_N     package weight  [N]
%   deployOut.deploys_aero    logical: weight > back-pressure at each angle  [-]
%   deployOut.theta_geo_deg   minimum angle for package to clear gap  [deg]
%   deployOut.min_angle_deg   minimum door angle for full deployment  [deg]
%   deployOut.q_inf_Pa        dynamic pressure  [Pa]
%   deployOut.fig             figure handle (if showPlot)

%% ── 1. Unpack inputs ───────────────────────────────────────────────────────
airfoilFile    = inp.airfoilFile;
Lf             = inp.Lf_m;
Wf             = inp.Wf_m;
V_inf          = inp.V_cruise_mps;
rho            = inp.rho_kgm3;
alpha_deg      = inp.alpha_deg;
m_pkg          = inp.m_package_kg;
pkg_h          = inp.package_h_m;
door_xfrac     = inp.door_xfrac;
door_L         = inp.door_length_m;
angles_deg     = inp.door_angles_deg(:)';

Npanels = 200;
if isfield(inp, 'Npanels') && ~isempty(inp.Npanels)
    Npanels = inp.Npanels;
end
showPlot = isfield(inp, 'showPlot') && inp.showPlot;

alpha_rad  = deg2rad(alpha_deg);
q_inf      = 0.5 * rho * V_inf^2;     % [Pa]  dynamic pressure
W_pkg      = m_pkg * 9.81;            % [N]   package weight

%% ── 2. Load and scale MH95 airfoil ─────────────────────────────────────────
fid = fopen(airfoilFile, 'r');
if fid == -1
    error('doorDeploymentCFD: cannot open airfoil file: %s', airfoilFile);
end
fgetl(fid);                              % skip header line
coords = fscanf(fid, '%f %f', [2 Inf]);
fclose(fid);

x_norm = coords(1,:)';   % [0, 1]  normalized x/c
y_norm = coords(2,:)';   % normalized y/c  (upper surface first, then lower)

% Scale to actual fuselage dimensions
x_af = x_norm * Lf;      % [m]
y_af = y_norm * Lf;      % [m]  (chord = Lf for both dimensions)

% Ensure the profile is closed (TE point appears at start and end)
if norm([x_af(1)-x_af(end), y_af(1)-y_af(end)]) > 1e-6
    x_af(end+1) = x_af(1);
    y_af(end+1) = y_af(1);
end

%% ── 3. Redistribute panels uniformly along arc length ───────────────────────
% Cosine clustering near LE and TE for better resolution
s_raw  = [0; cumsum(sqrt(diff(x_af).^2 + diff(y_af).^2))];
s_total = s_raw(end);
s_new   = linspace(0, s_total, Npanels + 1)';

x_pan = interp1(s_raw, x_af, s_new, 'pchip');
y_pan = interp1(s_raw, y_af, s_new, 'pchip');

%% ── 4. Panel geometry ───────────────────────────────────────────────────────
N   = Npanels;
dx  = diff(x_pan);
dy  = diff(y_pan);
len = sqrt(dx.^2 + dy.^2);       % panel lengths [m]

% Panel angles from x-axis
phi = atan2(dy, dx);              % [rad]  panel orientation

% Outward normal direction (90° CCW from panel direction)
nx = -sin(phi);
ny =  cos(phi);

% Panel midpoints
xm = 0.5*(x_pan(1:N) + x_pan(2:N+1));
ym = 0.5*(y_pan(1:N) + y_pan(2:N+1));

%% ── 5. Source panel influence coefficients ───────────────────────────────────
% A(i,j) = normal velocity at midpoint of panel i due to unit source on panel j
% B(i,j) = tangential velocity at midpoint of panel i due to unit source on panel j

A = zeros(N, N);
B = zeros(N, N);

for i = 1:N
    for j = 1:N
        % Transform field point (xm_i, ym_i) to local frame of panel j
        dpx = xm(i) - x_pan(j);
        dpy = ym(i) - y_pan(j);

        cpj = cos(phi(j));
        spj = sin(phi(j));

        X =  dpx*cpj + dpy*spj;    % along panel j
        Y = -dpx*spj + dpy*cpj;    % normal to panel j (outward if left of panel)

        lj  = len(j);
        r1sq = X^2 + Y^2;
        r2sq = (X - lj)^2 + Y^2;

        if i == j
            % Self-influence: panel's source always induces normal vel = 1/2
            u_loc = 0;
            v_loc = 0.5;
        else
            % Limit argument of log to avoid log(0)
            if r1sq < 1e-30, r1sq = 1e-30; end
            if r2sq < 1e-30, r2sq = 1e-30; end

            u_loc = (1/(4*pi)) * log(r1sq / r2sq);
            v_loc = (1/(2*pi)) * (atan2(Y, X - lj) - atan2(Y, X));
        end

        % Rotate velocity back to global frame
        Vx = u_loc * cpj - v_loc * spj;
        Vy = u_loc * spj + v_loc * cpj;

        % Project onto panel i's normal and tangent
        A(i,j) = Vx * nx(i) + Vy * ny(i);   % normal component
        B(i,j) = Vx * cpj   + Vy * spj;     % tangential component (wrong — see below)

        % Tangential of panel i, not j
        tx_i = cos(phi(i));
        ty_i = sin(phi(i));
        B(i,j) = Vx * tx_i + Vy * ty_i;
    end
end

%% ── 6. Freestream boundary condition and solve ───────────────────────────────
% Freestream velocity components
Vx_inf = V_inf * cos(alpha_rad);
Vy_inf = V_inf * sin(alpha_rad);

% Normal freestream at each panel
Vn_inf = Vx_inf * nx + Vy_inf * ny;    % [N×1]

% Solve: A * sigma = -Vn_inf
sigma = A \ (-Vn_inf);                  % [N×1] source strengths [m/s]

%% ── 7. Tangential velocity and pressure coefficient ─────────────────────────
% Tangential freestream at each panel
tx = cos(phi);   ty = sin(phi);
Vt_inf = Vx_inf * tx + Vy_inf * ty;

% Total tangential velocity at each panel midpoint
Vt = B * sigma + Vt_inf;               % [m/s]

% Pressure coefficient
Cp = 1 - (Vt / V_inf).^2;             % [-]

%% ── 8. Find Cp at door x-location (lower surface) ─────────────────────────
% Door hinge x-position
x_door_hinge = door_xfrac * Lf;

% Identify lower-surface panels (ny < 0 means normal points downward → lower surface)
is_lower = ny < 0;

% Among lower-surface panels, find the one nearest to the door hinge
x_lower = xm(is_lower);
Cp_lower = Cp(is_lower);

if isempty(x_lower)
    error('doorDeploymentCFD: no lower-surface panels found. Check panel orientation.');
end

[~, idx_door] = min(abs(x_lower - x_door_hinge));
Cp_at_door    = Cp_lower(idx_door);
x_door_actual = x_lower(idx_door);

%% ── 9. Door angle sweep — force balance ────────────────────────────────────
% Door area exposed to external flow (3-D: door length × fuselage width)
A_door = door_L * Wf;                  % [m^2]

% Aerodynamic model:
%   Closed fuselage: Cp at door = Cp_at_door (from panel method)
%   Fully open (θ = 90°): base pressure Cp_base ≈ -0.15 (blunt body, empirical)
%   Interpolation: Cp_eff(θ) = Cp_door*(1 - sin(θ)) + Cp_base*sin(θ)
%
% Physical interpretation: as door swings down, the door panel acts as a
% deflector that accelerates flow around the opening, reducing (and eventually
% reversing) the pressure at the gap.  At θ=90° the opening is blunt and
% base pressure dominates.
Cp_base = -0.15;    % empirical base pressure coefficient for streamlined body

theta_rad  = deg2rad(angles_deg);
Cp_eff     = Cp_at_door .* (1 - sin(theta_rad)) + Cp_base .* sin(theta_rad);

% Back-pressure force on package (acts to push package BACK into bay)
F_back_N   = Cp_eff .* q_inf .* A_door;  % [N]  positive = resists deployment

% Deployment condition: weight > back pressure force
deploys_aero = W_pkg > F_back_N;

%% ── 10. Geometric deployment condition ──────────────────────────────────────
% Minimum door angle for the package to physically clear the gap
% Gap height (perpendicular to fuselage): door_L × sin(θ)  must exceed pkg_h
if pkg_h >= door_L
    warning('doorDeploymentCFD: package height (%.3f m) >= door length (%.3f m). Check geometry.', ...
        pkg_h, door_L);
    theta_geo_deg = 90;
else
    theta_geo_deg = rad2deg(asin(pkg_h / door_L));
end

%% ── 11. Combined minimum deployment angle ───────────────────────────────────
% Aerodynamic minimum: smallest angle where deploys_aero = true
aero_ok = find(deploys_aero, 1, 'first');
if isempty(aero_ok)
    theta_aero_deg = Inf;
    fprintf('\n  WARNING: package weight (%.2f N) < back-pressure force at all angles.\n', W_pkg);
    fprintf('  Mechanical ejection or spring assist required.\n');
else
    theta_aero_deg = angles_deg(aero_ok);
end

min_angle_deg = max(theta_geo_deg, theta_aero_deg);

%% ── 12. Report ──────────────────────────────────────────────────────────────
fprintf('\n');
fprintf('=================================================================\n');
fprintf('CARGO DOOR DEPLOYMENT ANALYSIS (Source Panel Method)\n');
fprintf('=================================================================\n');
fprintf('Fuselage: MH95, Lf = %.3f m, Wf = %.4f m\n', Lf, Wf);
fprintf('Cruise:   V∞ = %.1f m/s,  q∞ = %.1f Pa,  α = %.1f°\n', ...
    V_inf, q_inf, alpha_deg);
fprintf('Package:  m = %.3f kg  →  W = %.2f N\n', m_pkg, W_pkg);
fprintf('Door:     hinge at x/c = %.2f (x = %.3f m),  L = %.3f m\n', ...
    door_xfrac, x_door_actual, door_L);
fprintf('          door area   = %.5f m² (%.4f m × %.4f m)\n', A_door, door_L, Wf);
fprintf('-----------------------------------------------------------------\n');
fprintf('Cp at door (closed fuselage, lower surface) = %+.4f\n', Cp_at_door);
fprintf('Back-pressure force (closed)               = %+.3f N\n', Cp_at_door * q_inf * A_door);
fprintf('Package weight                             =  %.3f N\n', W_pkg);
fprintf('-----------------------------------------------------------------\n');
fprintf('Geometric min angle (package clears gap)   = %.1f°\n', theta_geo_deg);
fprintf('Aerodynamic min angle (weight > F_back)    = %.1f°\n', theta_aero_deg);
fprintf('COMBINED MINIMUM DOOR ANGLE                = %.1f°\n', min_angle_deg);
fprintf('=================================================================\n\n');

%% ── 13. Pack outputs ────────────────────────────────────────────────────────
deployOut.Cp_vec        = Cp;
deployOut.x_mid_m       = xm;
deployOut.y_mid_m       = ym;
deployOut.Cp_at_door    = Cp_at_door;
deployOut.F_back_N      = F_back_N;
deployOut.Cp_eff        = Cp_eff;
deployOut.W_package_N   = W_pkg;
deployOut.deploys_aero  = deploys_aero;
deployOut.theta_geo_deg = theta_geo_deg;
deployOut.min_angle_deg = min_angle_deg;
deployOut.q_inf_Pa      = q_inf;
deployOut.angles_deg    = angles_deg;

%% ── 14. Plots ───────────────────────────────────────────────────────────────
if ~showPlot
    return
end

fig = figure('Name', 'Door Deployment Analysis', 'Color', 'w', 'NumberTitle', 'off');

% ── Plot 1: Fuselage Cp distribution ────────────────────────────────────────
ax1 = subplot(2, 2, [1 2], 'Parent', fig);
hold(ax1, 'on'); box(ax1, 'on'); grid(ax1, 'on');

% Split into upper and lower surface for clean plotting
is_upper = ny >= 0;
x_up = xm(is_upper);  Cp_up = Cp(is_upper);
x_lo = xm(is_lower);  Cp_lo = Cp(is_lower);

% Sort by x for clean line
[x_up_s, idx_u] = sort(x_up);  Cp_up_s = Cp_up(idx_u);
[x_lo_s, idx_l] = sort(x_lo);  Cp_lo_s = Cp_lo(idx_l);

plot(ax1, x_up_s, Cp_up_s, 'b-', 'LineWidth', 2, 'DisplayName', 'Upper surface');
plot(ax1, x_lo_s, Cp_lo_s, 'r-', 'LineWidth', 2, 'DisplayName', 'Lower surface');
yline(ax1, 0, 'k--', 'LineWidth', 1);

% Mark door location
xline(ax1, x_door_actual, 'g-', 'LineWidth', 2, 'DisplayName', sprintf('Door hinge (x = %.2f m)', x_door_actual));
xline(ax1, x_door_actual + door_L, 'g--', 'LineWidth', 1.5, 'DisplayName', sprintf('Door TE (x = %.2f m)', x_door_actual + door_L));

% Mark Cp at door
plot(ax1, x_door_actual, Cp_at_door, 'go', 'MarkerSize', 10, 'LineWidth', 2.5, ...
    'DisplayName', sprintf('Cp_{door} = %+.3f', Cp_at_door));

xlabel(ax1, 'x [m]');
ylabel(ax1, 'Cp  [-]');
title(ax1, sprintf('MH95 Fuselage Cp Distribution  (V∞ = %.0f m/s, α = %.1f°)', V_inf, alpha_deg));
set(ax1, 'YDir', 'reverse');   % Cp plot convention: negative up
legend(ax1, 'Location', 'best');

% ── Plot 2: Fuselage profile with door highlighted ───────────────────────────
ax2 = subplot(2, 2, 3, 'Parent', fig);
hold(ax2, 'on'); box(ax2, 'on'); grid(ax2, 'on'); axis(ax2, 'equal');

fill(ax2, x_af, y_af, [0.85 0.92 1.0], 'EdgeColor', [0.2 0.4 0.8], 'LineWidth', 1.2);

% Overlay door region on lower surface
mask_door = is_lower & xm >= x_door_actual & xm <= (x_door_actual + door_L);
if any(mask_door)
    x_door_lo = xm(mask_door);
    y_door_lo = ym(mask_door);
    [x_door_lo_s, idx_d] = sort(x_door_lo);
    y_door_lo_s = y_door_lo(idx_d);
    plot(ax2, x_door_lo_s, y_door_lo_s, 'r-', 'LineWidth', 4, 'DisplayName', 'Door panel');
end

% Draw door at minimum deployment angle
theta_draw = deg2rad(min_angle_deg);
x_hinge_pt = x_door_actual;
% Get y-coordinate on lower surface at hinge
[~, ih] = min(abs(x_lo - x_door_actual));
y_hinge_pt = x_lo(ih) * 0 + ym(is_lower);
[~, idx_h2] = min(abs(xm - x_door_actual));
y_hinge_pt2 = ym(idx_h2);
x_door_end = x_hinge_pt + door_L * cos(-theta_draw);  % door rotates downward
y_door_end = y_hinge_pt2 - door_L * sin(theta_draw);
plot(ax2, [x_hinge_pt, x_door_end], [y_hinge_pt2, y_door_end], ...
    'm-', 'LineWidth', 3, 'DisplayName', sprintf('Door at θ = %.0f° (min deploy)', min_angle_deg));

xlabel(ax2, 'x [m]');
ylabel(ax2, 'y [m]');
title(ax2, 'Fuselage Profile with Door Location');
legend(ax2, 'Location', 'best');

% ── Plot 3: Back-pressure force vs door angle ────────────────────────────────
ax3 = subplot(2, 2, 4, 'Parent', fig);
hold(ax3, 'on'); box(ax3, 'on'); grid(ax3, 'on');

% Back-pressure force (resist deployment — positive means resists)
plot(ax3, angles_deg, F_back_N, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Aerodynamic back-pressure force');
yline(ax3, W_pkg, 'b-', 'LineWidth', 2, 'DisplayName', sprintf('Package weight  W = %.2f N', W_pkg));
yline(ax3, 0, 'k--', 'LineWidth', 1);

% Shade region where aero force > weight (deployment blocked)
blocked = ~deploys_aero;
if any(blocked)
    theta_block = angles_deg(blocked);
    F_block     = F_back_N(blocked);
    fill(ax3, [theta_block, fliplr(theta_block)], ...
         [F_block, repmat(W_pkg, 1, sum(blocked))], ...
         [1 0.8 0.8], 'FaceAlpha', 0.4, 'EdgeColor', 'none', 'DisplayName', 'Back-pressure > Weight (blocked)');
end

% Mark geometric minimum
xline(ax3, theta_geo_deg, 'g--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Geometric min: %.1f°', theta_geo_deg));

% Mark combined minimum
xline(ax3, min_angle_deg, 'm-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Min deploy angle: %.1f°', min_angle_deg));

xlabel(ax3, 'Door angle θ [deg]');
ylabel(ax3, 'Force [N]');
title(ax3, 'Back-Pressure Force vs. Door Angle');
legend(ax3, 'Location', 'best');

sgtitle(fig, sprintf('Nimbus Cargo Door Deployment — Source Panel Analysis\n(MH95, Lf=%.2fm, V∞=%.0fm/s, m_{pkg}=%.0fg)', ...
    Lf, V_inf, m_pkg*1000), 'FontSize', 12, 'FontWeight', 'bold');

deployOut.fig = fig;

%% ── Figure 2: Door Placement Selection Map ──────────────────────────────────
% For every possible door hinge x-location on the lower surface, compute the
% minimum deployment angle.  This tells you WHERE to put the door.

% Sorted lower-surface Cp data
[x_lo_s, idx_sort] = sort(x_lower);
Cp_lo_s = Cp_lower(idx_sort);

% Sweep over hinge x-locations
min_angle_sweep = zeros(size(x_lo_s));
for k = 1:length(x_lo_s)
    Cp_k    = Cp_lo_s(k);
    Cp_eff_k = Cp_k .* (1 - sin(theta_rad)) + Cp_base .* sin(theta_rad);
    F_back_k = Cp_eff_k .* q_inf .* A_door;
    ok_k     = find(W_pkg > F_back_k, 1, 'first');
    if isempty(ok_k)
        theta_aero_k = 90;
    else
        theta_aero_k = angles_deg(ok_k);
    end
    min_angle_sweep(k) = max(theta_geo_deg, theta_aero_k);
end

% Best hinge location (minimises required door angle)
[best_angle, best_idx] = min(min_angle_sweep);
x_best = x_lo_s(best_idx);

fig2 = figure('Name', 'Door Placement Selection', 'Color', 'w', 'NumberTitle', 'off');

% ── Panel A: Fuselage profile, lower surface colored by Cp ──────────────────
ax_a = subplot(3, 1, 1, 'Parent', fig2);
hold(ax_a, 'on'); box(ax_a, 'on'); grid(ax_a, 'on'); axis(ax_a, 'equal');

% Draw fuselage filled shape
fill(ax_a, x_af, y_af, [0.93 0.95 0.98], 'EdgeColor', [0.4 0.4 0.8], 'LineWidth', 1.2, ...
    'DisplayName', 'Fuselage (MH95)');

% Color lower-surface panels by Cp
% Green = suction (Cp < 0, favourable); Red = pressure (Cp > 0, unfavourable)
cmap_n = 256;
Cp_all_lo = Cp_lo_s;
Cp_lim    = max(abs(Cp_all_lo));
if Cp_lim == 0, Cp_lim = 0.1; end

for k = 1:length(x_lo_s)-1
    xp = [x_lo_s(k), x_lo_s(k+1), x_lo_s(k+1), x_lo_s(k)];
    % y-coords: get matching lower-surface panel midpoint y values
    [~, ki1] = min(abs(xm(is_lower) - x_lo_s(k)));
    [~, ki2] = min(abs(xm(is_lower) - x_lo_s(k+1)));
    y_lo_all  = ym(is_lower);
    yp = [y_lo_all(ki1), y_lo_all(ki2), y_lo_all(ki2)+0.002, y_lo_all(ki1)+0.002];
    Cp_avg = 0.5*(Cp_lo_s(k) + Cp_lo_s(k+1));
    % Map Cp to colour: Cp < 0 → green, Cp > 0 → red
    t = (Cp_avg + Cp_lim) / (2*Cp_lim);  % 0 = full green, 1 = full red
    t = max(0, min(1, t));
    col = [t, 1-t, 0.2];
    fill(ax_a, xp, yp, col, 'EdgeColor', 'none', 'FaceAlpha', 0.85, 'HandleVisibility', 'off');
end

% Mark selected door hinge and door length span
y_hinge_lo = ym(is_lower);
[~, ih_lo] = min(abs(xm(is_lower) - x_door_actual));
y_h_lo = y_hinge_lo(ih_lo);
plot(ax_a, x_door_actual, y_h_lo, 'ms', 'MarkerSize', 10, 'LineWidth', 2.5, ...
    'DisplayName', sprintf('Selected hinge x = %.2f m', x_door_actual));

% Mark best hinge
[~, ib_lo] = min(abs(xm(is_lower) - x_best));
y_b_lo = y_hinge_lo(ib_lo);
plot(ax_a, x_best, y_b_lo, 'g^', 'MarkerSize', 10, 'LineWidth', 2.5, 'MarkerFaceColor', 'g', ...
    'DisplayName', sprintf('Best hinge x = %.2f m  (θ_{min} = %.0f°)', x_best, best_angle));

% Colourbar proxy patches
patch(ax_a, NaN, NaN, [0 0.9 0.2], 'DisplayName', 'Cp < 0  (suction — favourable)');
patch(ax_a, NaN, NaN, [0.9 0.1 0.2], 'DisplayName', 'Cp > 0  (pressure — back-pressure)');

xlabel(ax_a, 'x [m]');  ylabel(ax_a, 'y [m]');
title(ax_a, 'Fuselage Lower Surface — Cp Colour Map  (green = suction, red = pressure)');
legend(ax_a, 'Location', 'best', 'FontSize', 8);

% ── Panel B: Lower surface Cp vs x ──────────────────────────────────────────
ax_b = subplot(3, 1, 2, 'Parent', fig2);
hold(ax_b, 'on'); box(ax_b, 'on'); grid(ax_b, 'on');

% Shade favourable (Cp < 0) region
x_fill_full = [x_lo_s(1), x_lo_s(end), x_lo_s(end), x_lo_s(1)];
y_fill_fav  = [0, 0, min(Cp_lo_s)*1.1, min(Cp_lo_s)*1.1];
fill(ax_b, x_fill_full, y_fill_fav, [0.8 1.0 0.8], 'EdgeColor', 'none', ...
    'FaceAlpha', 0.5, 'DisplayName', 'Suction region (favourable)');

% Shade unfavourable (Cp > 0) region
y_fill_bad = [0, 0, max(Cp_lo_s)*1.1, max(Cp_lo_s)*1.1];
fill(ax_b, x_fill_full, y_fill_bad, [1.0 0.85 0.85], 'EdgeColor', 'none', ...
    'FaceAlpha', 0.5, 'DisplayName', 'Pressure region (back-pressure)');

plot(ax_b, x_lo_s, Cp_lo_s, 'k-', 'LineWidth', 2.5, 'DisplayName', 'Lower surface Cp');
yline(ax_b, 0, 'k--', 'LineWidth', 1);

% Mark selected and best hinge
xline(ax_b, x_door_actual, 'm-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Selected hinge x = %.2f m', x_door_actual));
xline(ax_b, x_best, 'g-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Best hinge x = %.2f m', x_best));

set(ax_b, 'YDir', 'reverse');
xlabel(ax_b, 'x [m]');  ylabel(ax_b, 'Cp  [–]');
title(ax_b, 'Lower Surface Cp vs. Hinge x-Location');
legend(ax_b, 'Location', 'best', 'FontSize', 8);

% ── Panel C: Minimum deployment angle vs hinge x-location ───────────────────
ax_c = subplot(3, 1, 3, 'Parent', fig2);
hold(ax_c, 'on'); box(ax_c, 'on'); grid(ax_c, 'on');

plot(ax_c, x_lo_s, min_angle_sweep, 'b-', 'LineWidth', 2.5, ...
    'DisplayName', 'Min deployment angle');
yline(ax_c, theta_geo_deg, 'g--', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Geometric floor  (%.1f°)', theta_geo_deg));

% Mark best hinge
plot(ax_c, x_best, best_angle, 'g^', 'MarkerSize', 10, 'MarkerFaceColor', 'g', ...
    'LineWidth', 2, 'DisplayName', sprintf('Best hinge  x = %.2f m  →  θ_{min} = %.0f°', x_best, best_angle));

% Mark selected hinge
plot(ax_c, x_door_actual, min_angle_deg, 'ms', 'MarkerSize', 10, 'LineWidth', 2, ...
    'DisplayName', sprintf('Selected hinge  x = %.2f m  →  θ_{min} = %.0f°', x_door_actual, min_angle_deg));

xlabel(ax_c, 'Door hinge x [m]');
ylabel(ax_c, 'Min door angle for deployment  [deg]');
title(ax_c, 'Minimum Deployment Angle vs. Door Hinge Location — Pick the Minimum');
legend(ax_c, 'Location', 'best', 'FontSize', 8);

sgtitle(fig2, sprintf('Nimbus Door Placement Selection  (L_{door} = %.3f m,  pkg h = %.3f m)', ...
    door_L, pkg_h), 'FontSize', 12, 'FontWeight', 'bold');

deployOut.fig2 = fig2;
fprintf('Door placement sweep: best hinge at x = %.3f m  (x/c = %.2f)  → θ_min = %.1f°\n\n', ...
    x_best, x_best/Lf, best_angle);

end
