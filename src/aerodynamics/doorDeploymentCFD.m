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

%% ── 8. Find Cp at door hinge location (symmetric clamshell — both surfaces) ──
x_door_hinge = door_xfrac * Lf;

% Identify surfaces by panel midpoint y-coordinate — robust regardless of
% whether the airfoil data is CW (Selig format) or CCW.
is_upper = ym > median(ym);   % higher y = top of fuselage
is_lower = ym <= median(ym);  % lower y  = bottom of fuselage

x_lower  = xm(is_lower);    Cp_lower = Cp(is_lower);
x_upper  = xm(is_upper);    Cp_upper = Cp(is_upper);

if isempty(x_lower)
    error('doorDeploymentCFD: no lower-surface panels found. Check panel orientation.');
end

% Both doors (upper and lower) open symmetrically. Use the maximum Cp from
% either surface at the hinge x — this is the worst-case back-pressure estimate.
[~, idx_lo]   = min(abs(x_lower - x_door_hinge));
[~, idx_up]   = min(abs(x_upper - x_door_hinge));
Cp_at_door    = max(Cp_lower(idx_lo), Cp_upper(idx_up));
x_door_actual = x_lower(idx_lo);

%% ── 8a. Cp_base: flat-back truncated panel method ───────────────────────────
% Run the source panel method on the MH95 profile truncated at x_door_hinge
% with a vertical flat-back closing segment.  This represents the fuselage
% with the clamshell fully open (θ = 90°) and gives an inviscid estimate of
% the base pressure.
%
% Inviscid panel methods yield Cp > 0 at the base (stagnation region) because
% flow separation is not modelled.  This is CONSERVATIVE for deployment:
% higher Cp_base → more back-pressure → larger required door angle.
% The empirical value (Hoerner) is Cp_base_emp = -0.15 (accounts for viscous
% wake and separation).  We use max(inviscid, empirical) as the design bound.

Cp_base_emp = -0.15;

% ── Find the two arc-length crossings of x_pan = x_door_hinge ───────────
x_res = x_pan - x_door_hinge;
cross_k = find(x_res(1:end-1) .* x_res(2:end) < 0);

% Initialise forward-profile variables used by the streamline figure below.
% Overwritten inside the else-branch when crossings are found.
y_hi_fb   = NaN;   y_lo_fb   = NaN;
x_fwd_fb  = [];    y_fwd_fb  = [];

if numel(cross_k) < 2
    warning('doorDeploymentCFD: < 2 crossings at x_door_hinge — using empirical Cp_base.');
    Cp_base = Cp_base_emp;
else
    n_cr = numel(cross_k);
    sc_all = zeros(n_cr,1);   yc_all = zeros(n_cr,1);
    for kci = 1:n_cr
        k1 = cross_k(kci);
        t  = (x_door_hinge - x_pan(k1)) / (x_pan(k1+1) - x_pan(k1));
        sc_all(kci) = s_new(k1) + t*(s_new(k1+1) - s_new(k1));
        yc_all(kci) = y_pan(k1) + t*(y_pan(k1+1)  - y_pan(k1));
    end
    [~, ic] = sort(yc_all, 'descend');
    s_hi = sc_all(ic(1));   y_hi_fb = yc_all(ic(1));   % upper-surface crossing
    s_lo = sc_all(ic(end)); y_lo_fb = yc_all(ic(end));  % lower-surface crossing

    % Check which arc-length interval spans the LE (x ≈ 0)
    s_chk = linspace(min(s_hi,s_lo), max(s_hi,s_lo), 31)';
    x_chk = interp1(s_new, x_pan, s_chk, 'linear');
    if min(x_chk) < 0.1*Lf
        s_fwd = linspace(s_hi, s_lo, Npanels-1)';
    else
        n1 = max(2, round((s_new(end)-s_lo)/s_new(end) * (Npanels-1)));
        n2 = max(2, (Npanels-1) - n1);
        s_fwd = [linspace(s_lo, s_new(end), n1)'; linspace(0, s_hi, n2)'];
    end

    x_fwd_fb = interp1(s_new, x_pan, s_fwd, 'pchip');
    y_fwd_fb = interp1(s_new, y_pan, s_fwd, 'pchip');

    % Closed profile: flat-back at x_door_hinge, then forward section
    x_fb = [x_door_hinge; x_fwd_fb; x_door_hinge];
    y_fb = [y_hi_fb;      y_fwd_fb; y_lo_fb     ];

    s_fb_r = [0; cumsum(sqrt(diff(x_fb).^2 + diff(y_fb).^2))];
    s_fb_u = linspace(0, s_fb_r(end), Npanels+1)';
    xpb = interp1(s_fb_r, x_fb, s_fb_u, 'pchip');
    ypb = interp1(s_fb_r, y_fb, s_fb_u, 'pchip');

    % Panel geometry
    dx_b = diff(xpb);   dy_b = diff(ypb);
    len_b = sqrt(dx_b.^2 + dy_b.^2);
    phi_b = atan2(dy_b, dx_b);
    nx_b  = -sin(phi_b);   ny_b = cos(phi_b);
    xmb   = 0.5*(xpb(1:Npanels) + xpb(2:Npanels+1));
    ymb   = 0.5*(ypb(1:Npanels) + ypb(2:Npanels+1));

    % Influence matrix
    Ab = zeros(Npanels);   Bb = zeros(Npanels);
    for ii = 1:Npanels
        for jj = 1:Npanels
            dpxb  = xmb(ii) - xpb(jj);
            dpyb  = ymb(ii) - ypb(jj);
            cpjb  = cos(phi_b(jj));   spjb = sin(phi_b(jj));
            Xlb   =  dpxb*cpjb + dpyb*spjb;
            Ylb   = -dpxb*spjb + dpyb*cpjb;
            ljb   = len_b(jj);
            r1b   = max(Xlb^2 + Ylb^2, 1e-30);
            r2b   = max((Xlb-ljb)^2 + Ylb^2, 1e-30);
            if ii == jj
                ulb = 0;   vlb = 0.5;
            else
                ulb = (1/(4*pi)) * log(r1b/r2b);
                vlb = (1/(2*pi)) * (atan2(Ylb,Xlb-ljb) - atan2(Ylb,Xlb));
            end
            Vxb = ulb*cpjb - vlb*spjb;
            Vyb = ulb*spjb + vlb*cpjb;
            Ab(ii,jj) = Vxb*nx_b(ii) + Vyb*ny_b(ii);
            Bb(ii,jj) = Vxb*cos(phi_b(ii)) + Vyb*sin(phi_b(ii));
        end
    end

    Vn_b  = V_inf*cos(alpha_rad)*nx_b + V_inf*sin(alpha_rad)*ny_b;
    sig_b = Ab \ (-Vn_b);
    Vtb   = Bb*sig_b + V_inf*(cos(alpha_rad)*cos(phi_b) + sin(alpha_rad)*sin(phi_b));
    Cp_fb_sol = 1 - (Vtb/V_inf).^2;

    % Identify flat-back panels (at x ≈ x_door_hinge)
    fb_tol  = 3 * mean(len_b);
    fb_mask = abs(xmb - x_door_hinge) < fb_tol;
    if any(fb_mask)
        Cp_base_panel = mean(Cp_fb_sol(fb_mask));
    else
        Cp_base_panel = NaN;
    end

    % Conservative design choice: use the higher Cp_base
    if isnan(Cp_base_panel)
        Cp_base = Cp_base_emp;
    else
        Cp_base = max(Cp_base_emp, Cp_base_panel);
    end
    fprintf('Cp_base  inviscid flat-back panel method = %+.4f  [conservative, no separation]\n', Cp_base_panel);
    fprintf('Cp_base  empirical viscous (Hoerner)     = %+.4f\n', Cp_base_emp);
    fprintf('Cp_base  used in force model (max)       = %+.4f\n', Cp_base);
end

%% ── 9. Door angle sweep — force balance ────────────────────────────────────
% Package bottom face area (fore-aft length × fuselage width) — the face that
% sees back-pressure as the package drops through the clamshell opening.
A_door = door_L * Wf;                  % [m^2]

% Aerodynamic model:
%   Closed fuselage: Cp at door = Cp_at_door (panel method, from section 8)
%   Fully open (θ = 90°): base pressure Cp_base (from flat-back panel, section 8a)
%   Interpolation: Cp_eff(θ) = Cp_door*(1 - sin(θ)) + Cp_base*sin(θ)

theta_rad  = deg2rad(angles_deg);
Cp_eff     = Cp_at_door .* (1 - sin(theta_rad)) + Cp_base .* sin(theta_rad);

% Back-pressure force on package (acts to push package BACK into bay)
F_back_N   = Cp_eff .* q_inf .* A_door;  % [N]  positive = resists deployment

% Deployment condition: weight > back pressure force
deploys_aero = W_pkg > F_back_N;

%% ── 10. Geometric deployment condition ──────────────────────────────────────
% Symmetric clamshell: lower door swings down door_L·sin(θ), upper door swings
% up door_L·sin(θ), giving total gap = 2·door_L·sin(θ).
% Minimum angle: 2·door_L·sin(θ_geo) ≥ pkg_h  →  θ_geo = arcsin(pkg_h / (2·door_L))
if pkg_h >= 2 * door_L
    warning('doorDeploymentCFD: package height (%.3f m) >= 2 × door length (%.3f m). Check geometry.', ...
        pkg_h, 2*door_L);
    theta_geo_deg = 90;
else
    theta_geo_deg = rad2deg(asin(pkg_h / (2 * door_L)));
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
fprintf('Door:     clamshell hinge at x/c = %.2f (x = %.3f m),  L_door = %.3f m\n', ...
    door_xfrac, x_door_actual, door_L);
fprintf('          pkg bottom face = %.5f m² (%.4f m × %.4f m)\n', A_door, door_L, Wf);
fprintf('-----------------------------------------------------------------\n');
fprintf('Cp at door (closed fuselage, max both surfaces) = %+.4f\n', Cp_at_door);
fprintf('Back-pressure force (closed)               = %+.3f N\n', Cp_at_door * q_inf * A_door);
fprintf('Package weight                             =  %.3f N\n', W_pkg);
fprintf('-----------------------------------------------------------------\n');
fprintf('Geometric min angle (clamshell gap ≥ pkg_h) = %.1f°\n', theta_geo_deg);
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

% Split into upper and lower surface (is_upper/is_lower defined in section 8)
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

% Overlay clamshell door region on BOTH surfaces
mask_door_lo = is_lower & xm >= x_door_actual & xm <= (x_door_actual + door_L);
mask_door_up = is_upper & xm >= x_door_actual & xm <= (x_door_actual + door_L);
if any(mask_door_lo)
    xd = xm(mask_door_lo); yd = ym(mask_door_lo);
    [xd_s, id] = sort(xd); yd_s = yd(id);
    plot(ax2, xd_s, yd_s, 'r-', 'LineWidth', 4, 'DisplayName', 'Clamshell door panels');
end
if any(mask_door_up)
    xd = xm(mask_door_up); yd = ym(mask_door_up);
    [xd_s, id] = sort(xd); yd_s = yd(id);
    plot(ax2, xd_s, yd_s, 'r-', 'LineWidth', 4, 'HandleVisibility', 'off');
end

% Draw both clamshell panels at minimum deployment angle
theta_draw  = deg2rad(min_angle_deg);
x_hinge_pt  = x_door_actual;
x_tip       = x_hinge_pt + door_L * cos(theta_draw);

% Lower door: hinge on lower surface, tip swings downward
y_lo_all = ym(is_lower);
[~, ih_lo] = min(abs(x_lo - x_door_actual));
y_lo_hinge = y_lo_all(ih_lo);
y_lo_tip   = y_lo_hinge - door_L * sin(theta_draw);
plot(ax2, [x_hinge_pt, x_tip], [y_lo_hinge, y_lo_tip], ...
    'm-', 'LineWidth', 3, 'DisplayName', sprintf('Clamshell at θ = %.0f° (min deploy)', min_angle_deg));

% Upper door: hinge on upper surface, tip swings upward
y_up_all = ym(is_upper);
[~, ih_up] = min(abs(x_up - x_door_actual));
y_up_hinge = y_up_all(ih_up);
y_up_tip   = y_up_hinge + door_L * sin(theta_draw);
plot(ax2, [x_hinge_pt, x_tip], [y_up_hinge, y_up_tip], ...
    'm-', 'LineWidth', 3, 'HandleVisibility', 'off');

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

% Sorted Cp data for both surfaces
[x_lo_s, idx_sort_lo] = sort(x_lower);
Cp_lo_s = Cp_lower(idx_sort_lo);

[x_up_s_sw, idx_sort_up] = sort(x_upper);
Cp_up_s_sw = Cp_upper(idx_sort_up);

% Clamshell back-pressure Cp = max from either surface at each hinge x
Cp_clam_s = zeros(size(x_lo_s));
for k = 1:length(x_lo_s)
    [~, ku] = min(abs(x_up_s_sw - x_lo_s(k)));
    Cp_clam_s(k) = max(Cp_lo_s(k), Cp_up_s_sw(ku));
end

% Sweep over hinge x-locations
min_angle_sweep = zeros(size(x_lo_s));
for k = 1:length(x_lo_s)
    Cp_k     = Cp_clam_s(k);
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

plot(ax_b, x_lo_s, Cp_lo_s, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Lower surface Cp');
plot(ax_b, x_up_s_sw, Cp_up_s_sw, 'b--', 'LineWidth', 1.8, 'DisplayName', 'Upper surface Cp');
plot(ax_b, x_lo_s, Cp_clam_s, 'k-', 'LineWidth', 1.2, 'DisplayName', 'Clamshell Cp (max, used for force)');
yline(ax_b, 0, 'k--', 'LineWidth', 1);

% Mark selected and best hinge
xline(ax_b, x_door_actual, 'm-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Selected hinge x = %.2f m', x_door_actual));
xline(ax_b, x_best, 'g-', 'LineWidth', 2, ...
    'DisplayName', sprintf('Best hinge x = %.2f m', x_best));

set(ax_b, 'YDir', 'reverse');
xlabel(ax_b, 'x [m]');  ylabel(ax_b, 'Cp  [–]');
title(ax_b, 'Surface Cp vs. Hinge x-Location (red=lower, blue=upper, black=clamshell max)');
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

sgtitle(fig2, sprintf('Nimbus Clamshell Door Placement  (L_{door} = %.3f m,  pkg h = %.3f m,  gap = 2·L·sin θ)', ...
    door_L, pkg_h), 'FontSize', 12, 'FontWeight', 'bold');

deployOut.fig2 = fig2;
fprintf('Door placement sweep: best hinge at x = %.3f m  (x/c = %.2f)  → θ_min = %.1f°\n\n', ...
    x_best, x_best/Lf, best_angle);

%% ── Figure 3: Streamlines & Vorticity — t0 → Steady State ──────────────────
% Shows the velocity field (speed |V|/V∞ + streamlines) and the numerical
% vorticity (ω = ∂v/∂x − ∂u/∂y) at three door angles:
%   t0  : door just closed  (θ = 0°)
%   mid : half-open          (θ = θ_min / 2)
%   t_ss: steady-state open  (θ = θ_min)
%
% NOTE: This is an inviscid (potential-flow) analysis — theoretical ω = 0.
% Numerical ω plotted here shows the irrotational nature and any small
% discretisation artefacts near the panel boundaries.

if ~isnan(y_hi_fb) && ~isempty(x_fwd_fb)

    theta_vis_deg = unique(max(0, [0, min_angle_deg/2, min_angle_deg]));
    n_vis = numel(theta_vis_deg);

    % Velocity grid
    xg_v = linspace(-0.05*Lf, 1.15*Lf, 80)';
    yg_v = linspace(-0.40*Lf, 0.40*Lf, 55)';
    [XG, YG] = meshgrid(xg_v, yg_v);

    Npsl = 120;   % reduced panel count for speed

    % Blue-white-red diverging colourmap for vorticity
    nc_d = 256;
    r_c = [linspace(0,1,nc_d/2)'; ones(nc_d/2,1)];
    g_c = [linspace(0,1,nc_d/2)'; linspace(1,0,nc_d/2)'];
    b_c = [ones(nc_d/2,1); linspace(1,0,nc_d/2)'];
    cmap_bwr = [r_c, g_c, b_c];

    fig3 = figure('Name','Streamlines & Vorticity — Door Opening (t0 to SS)', ...
                  'Color','w','NumberTitle','off');

    for kv = 1:n_vis
        theta_v    = deg2rad(theta_vis_deg(kv));
        x_tip_v    = x_door_hinge + door_L * cos(theta_v);
        y_lo_tip_v = y_lo_fb - door_L * sin(theta_v);
        y_up_tip_v = y_hi_fb + door_L * sin(theta_v);

        % Closing segment (vertical, between door tips)
        n_cl = max(2, round(abs(y_up_tip_v - y_lo_tip_v) * 20 / Lf));
        y_cl = linspace(y_lo_tip_v, y_up_tip_v, n_cl)';

        % Closed profile: forward section → lower door → closing → upper door
        x_pr = [x_fwd_fb;              x_tip_v*ones(n_cl,1); x_fwd_fb(1)];
        y_pr = [y_fwd_fb;              y_cl;                  y_fwd_fb(1)];

        % Redistribute to Npsl panels
        s_pr = [0; cumsum(sqrt(diff(x_pr).^2 + diff(y_pr).^2))];
        s_u  = linspace(0, s_pr(end), Npsl+1)';
        xpp  = interp1(s_pr, x_pr, s_u, 'pchip');
        ypp  = interp1(s_pr, y_pr, s_u, 'pchip');

        % Velocity field
        [UG, VG] = panelVelocityField(XG, YG, xpp, ypp, Npsl, V_inf, alpha_rad);

        % Mask interior
        in_b  = inpolygon(XG, YG, x_pr, y_pr);
        UG(in_b) = NaN;   VG(in_b) = NaN;

        % Derived quantities
        speed_norm = sqrt(UG.^2 + VG.^2) / V_inf;

        [dV_dx, ~    ] = gradient(VG, xg_v, yg_v);
        [~,     dU_dy] = gradient(UG, xg_v, yg_v);
        omega = dV_dx - dU_dy;
        omega(in_b) = NaN;

        % Subplot labels
        if theta_vis_deg(kv) < 0.5
            lbl = 't_0  (θ = 0°  —  closed)';
        elseif kv == n_vis
            lbl = sprintf('t_{ss}  θ = %.0f°  (deploy)', min_angle_deg);
        else
            lbl = sprintf('θ = %.0f°  (opening)', theta_vis_deg(kv));
        end

        % ── Row 1: Speed |V|/V∞ + streamlines ─────────────────────────────
        ax_sp = subplot(2, n_vis, kv, 'Parent', fig3);
        hold(ax_sp,'on');  box(ax_sp,'on');
        contourf(ax_sp, XG, YG, speed_norm, 24, 'LineColor','none');
        colormap(ax_sp, turbo(256));
        clim(ax_sp, [0, 2.5]);
        streamslice(ax_sp, XG, YG, UG, VG, 1.5);
        fill(ax_sp, x_pr, y_pr, [0.45 0.45 0.45], 'EdgeColor','k','LineWidth',0.8);
        axis(ax_sp,'equal');
        axis(ax_sp, [-0.05*Lf, 1.15*Lf, -0.38*Lf, 0.38*Lf]);
        title(ax_sp, lbl, 'FontSize', 8, 'FontWeight','bold');
        if kv == 1
            ylabel(ax_sp, 'y  [m]', 'FontSize', 8);
            cb = colorbar(ax_sp, 'Location','eastoutside');
            cb.Label.String = '|V|/V_∞  [-]';
            cb.FontSize = 7;
        end
        xlabel(ax_sp, 'x  [m]', 'FontSize', 8);

        % ── Row 2: Vorticity ω + streamlines ──────────────────────────────
        ax_vt = subplot(2, n_vis, kv + n_vis, 'Parent', fig3);
        hold(ax_vt,'on');  box(ax_vt,'on');
        omega_lim = max(1e-4, prctile(abs(omega(~in_b & isfinite(omega))), 98));
        contourf(ax_vt, XG, YG, omega, 24, 'LineColor','none');
        colormap(ax_vt, cmap_bwr);
        clim(ax_vt, [-omega_lim, omega_lim]);
        streamslice(ax_vt, XG, YG, UG, VG, 1.5);
        fill(ax_vt, x_pr, y_pr, [0.45 0.45 0.45], 'EdgeColor','k','LineWidth',0.8);
        axis(ax_vt,'equal');
        axis(ax_vt, [-0.05*Lf, 1.15*Lf, -0.38*Lf, 0.38*Lf]);
        title(ax_vt, sprintf('ω  (θ = %.0f°)', theta_vis_deg(kv)), 'FontSize', 8);
        if kv == 1
            ylabel(ax_vt, 'y  [m]', 'FontSize', 8);
            cb2 = colorbar(ax_vt, 'Location','eastoutside');
            cb2.Label.String = 'ω  [rad/s]';
            cb2.FontSize = 7;
        end
        xlabel(ax_vt, 'x  [m]', 'FontSize', 8);
    end

    sgtitle(fig3, ...
        sprintf(['Nimbus Cargo Door — Velocity Streamlines & Vorticity\n' ...
                 '(Source panel method, MH95, V_∞ = %.0f m/s,  θ_{min} = %.0f°  |  ' ...
                 'Inviscid: ω = 0 theoretically)'], V_inf, min_angle_deg), ...
        'FontSize', 11, 'FontWeight', 'bold');

    deployOut.fig3 = fig3;
end

end

%% ── Local helper: source-panel velocity field on a 2-D grid ─────────────────
function [UG, VG] = panelVelocityField(XG, YG, x_pan_p, y_pan_p, N, V_inf, alpha_rad)
%panelVelocityField  Hess-Smith panel solve + velocity field on meshgrid.
%
%   [UG, VG] = panelVelocityField(XG, YG, x_pan_p, y_pan_p, N, V_inf, alpha_rad)
%
%   Inputs:
%     XG, YG      meshgrid of field points  [m]
%     x_pan_p, y_pan_p   panel node coordinates (N+1 nodes)  [m]
%     N           number of panels  [-]
%     V_inf       freestream speed  [m/s]
%     alpha_rad   angle of attack  [rad]
%   Outputs:
%     UG, VG      x- and y-velocity components on the grid  [m/s]

dx_p  = diff(x_pan_p);    dy_p  = diff(y_pan_p);
len_p = sqrt(dx_p.^2 + dy_p.^2);
phi_p = atan2(dy_p, dx_p);
nx_p  = -sin(phi_p);      ny_p  =  cos(phi_p);
xm_p  = 0.5*(x_pan_p(1:N) + x_pan_p(2:N+1));
ym_p  = 0.5*(y_pan_p(1:N) + y_pan_p(2:N+1));

% Build influence matrix
A_p = zeros(N);
for i = 1:N
    for j = 1:N
        dpx = xm_p(i) - x_pan_p(j);
        dpy = ym_p(i) - y_pan_p(j);
        cpj = cos(phi_p(j));   spj = sin(phi_p(j));
        X   =  dpx*cpj + dpy*spj;
        Y   = -dpx*spj + dpy*cpj;
        lj  = len_p(j);
        r1  = max(X^2  + Y^2,        1e-30);
        r2  = max((X-lj)^2 + Y^2,    1e-30);
        if i == j
            u_l = 0;   v_l = 0.5;
        else
            u_l = (1/(4*pi)) * log(r1/r2);
            v_l = (1/(2*pi)) * (atan2(Y,X-lj) - atan2(Y,X));
        end
        Vx = u_l*cpj - v_l*spj;
        Vy = u_l*spj + v_l*cpj;
        A_p(i,j) = Vx*nx_p(i) + Vy*ny_p(i);
    end
end
Vn_p    = V_inf*cos(alpha_rad)*nx_p + V_inf*sin(alpha_rad)*ny_p;
sigma_p = A_p \ (-Vn_p);

% Velocity at grid points (loop over panels, vectorised over grid)
UG = V_inf * cos(alpha_rad) * ones(size(XG));
VG = V_inf * sin(alpha_rad) * ones(size(YG));
for j = 1:N
    cpj = cos(phi_p(j));   spj = sin(phi_p(j));
    lj  = len_p(j);
    Xg  =  (XG - x_pan_p(j))*cpj + (YG - y_pan_p(j))*spj;
    Yg  = -(XG - x_pan_p(j))*spj + (YG - y_pan_p(j))*cpj;
    r1g = max(Xg.^2 + Yg.^2,        1e-30);
    r2g = max((Xg-lj).^2 + Yg.^2,   1e-30);
    u_lg = (1/(4*pi)) * log(r1g ./ r2g);
    v_lg = (1/(2*pi)) * (atan2(Yg, Xg-lj) - atan2(Yg, Xg));
    UG   = UG + sigma_p(j) * (u_lg*cpj - v_lg*spj);
    VG   = VG + sigma_p(j) * (u_lg*spj + v_lg*cpj);
end
end
