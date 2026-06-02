% propCompare.m
% Compares thrust and current predictions for prop candidates.
% Run after: run_project.m
%
% Bench correction factor k_corr = 0.65 is applied to all surrogate outputs:
%   T_actual  ≈ k_corr * T_surrogate
%   I_actual  ≈ k_corr * (I_surrogate - I0) + I0   [I0 does not scale]
%
% Corrected pass criteria become:
%   T_surr(V_climb, Rm_hi) >= T_req / k_corr   (= 6.46 N for T_req=4.2 N)
%   I_surr_peak(Rm_lo)     <= (I_max - I0)/k_corr + I0  (≈ 51.9 A)
%
% Rm is bracketed: Rm_lo = motor winding only, Rm_hi = motor + ESC/wiring (bench).
% V_climb = 1.2 * V_stall (actual stall speed from main output).

close all;

%% ── Atmosphere ────────────────────────────────────────────────────────────
rho = 1.19;   % [kg/m³]

%% ── Bench correction factor ───────────────────────────────────────────────
k_corr = 0.65;   % actual/surrogate ratio from bench tests (thrust ~35% over-predicted)

%% ── Rm bracket (SunnySky 2212 1100KV circuit) ─────────────────────────────
Rm_lo = 0.073;   % [Ω] motor winding only — upper current bound
Rm_hi = 0.148;   % [Ω] motor + ESC + wiring (bench back-calc) — lower current bound

%% ── Common motor parameters ───────────────────────────────────────────────
base.KV             = 1100;
base.I0             = 0.8;
base.Vbat           = 11.1;
base.I_max          = 34;
base.rho            = rho;
base.V_vec_mps      = linspace(0, 35, 300);
base.usePrelimModel = false;

%% ── Aircraft aero parameters (from main_output.txt) ──────────────────────
W     = 28.4441;   % [N]    loaded gross weight
S     = 0.3087;    % [m²]   wing reference area
CD0   = 0.01831;   % [-]    total parasite drag (wing + fuse + fin)
AR    = 8.0;       % [-]    aspect ratio
e_osw = 0.8;       % [-]    Oswald efficiency

%% ── Requirements ──────────────────────────────────────────────────────────
V_stall  = 13.0;            % [m/s] actual stall speed from main output
V_climb  = 1.2 * V_stall;  % [m/s] = 15.6 m/s
T_req    = 4.2;             % [N]   required corrected thrust at V_climb (5 deg climb at 15 m/s)
I_max_corr = base.I_max;   % [A]   physical ESC limit on corrected current

% Equivalent surrogate thresholds (what the surrogate must show to pass after correction)
T_req_surr = T_req / k_corr;                              % = 12.15 N
I_max_surr = (I_max_corr - base.I0) / k_corr + base.I0;  % ≈ 51.9 A

% Drag at V_climb (level flight, no climb component in aero drag)
q_climb = 0.5 * rho * V_climb^2;
CL_climb = W / (q_climb * S);
CD_climb = CD0 + CL_climb^2 / (pi * AR * e_osw);
D_climb  = q_climb * S * CD_climb;   % [N]

% Climb angle implied by T_req
gamma_req_deg = asind((T_req - D_climb) / W);  % [deg]

%% ── Prop data directory ───────────────────────────────────────────────────
repoRoot = fileparts(mfilename('fullpath'));
if isempty(repoRoot)
    repoRoot = fileparts(which('propCompare'));
end
propDataDir = fullfile(repoRoot, 'resources', ...
    'propeller_surrogate_model', 'propeller_performance_data_files');

%% ── Prop candidates ───────────────────────────────────────────────────────
% { filename,  display name,  D [in],  pitch [in],  clearance_flag }
% clearance_flag: 0 = fits, 1 = verify clearance before flying
candidates = {
    'PER3_11x47SF.dat', '11x4.7 SF',       11,  4.7, 0;  % baseline
    'PER3_12x47SF.dat', '12x4.7 SF',       12,  4.7, 1;  % ── 12" sweep ──
    'PER3_12x6.dat',    '12x6',            12,  6.0, 1;
    'PER3_12x8.dat',    '12x8',            12,  8.0, 1;
    'PER3_12x10.dat',   '12x10',           12, 10.0, 1;
    'PER3_13x47SF.dat', '13x4.7 SF ⚠',    13,  4.7, 1;  % ── 13" sweep — check clearance ──
    'PER3_13x6.dat',    '13x6 ⚠',         13,  6.0, 1;
    'PER3_13x8.dat',    '13x8 ⚠',         13,  8.0, 1;
    'PER3_13x10.dat',   '13x10 ⚠',        13, 10.0, 1;
    'PER3_10x7-3.dat',  '10x7 (3-bl)',     10,  7.0, 0;  % only 3-blade in range
};

N      = size(candidates, 1);
cmap   = lines(N);
colors = mat2cell(cmap, ones(1,N), 3);

%% ── Run surrogate for each prop × both Rm values ─────────────────────────
res_lo = cell(N, 1);
res_hi = cell(N, 1);

for k = 1:N
    pIn          = base;
    pIn.apcFile  = fullfile(propDataDir, candidates{k,1});
    pIn.propName = candidates{k,2};
    pIn.D_in     = candidates{k,3};
    pIn.pitch_in = candidates{k,4};

    fBefore = findall(0,'Type','figure');

    pIn.Rm    = Rm_lo;
    res_lo{k} = propulsionAnalysis(pIn);

    pIn.Rm    = Rm_hi;
    res_hi{k} = propulsionAnalysis(pIn);

    fAfter = findall(0,'Type','figure');
    close(setdiff(fAfter, fBefore));
end

%% ── Apply bench correction factor ─────────────────────────────────────────
% T_corr = k_corr * T_surr
% I_corr = k_corr * (I_surr - I0) + I0
I0 = base.I0;
for k = 1:N
    res_lo{k}.T_corr = k_corr * res_lo{k}.T_vec_N;
    res_hi{k}.T_corr = k_corr * res_hi{k}.T_vec_N;
    res_lo{k}.I_corr = k_corr * (res_lo{k}.I_vec_A - I0) + I0;
    res_hi{k}.I_corr = k_corr * (res_hi{k}.I_vec_A - I0) + I0;
    res_lo{k}.T_corr_static = k_corr * res_lo{k}.T_static_N;
    res_hi{k}.T_corr_static = k_corr * res_hi{k}.T_static_N;
    res_lo{k}.I_corr_peak   = k_corr * (res_lo{k}.I_peak_A - I0) + I0;
    res_hi{k}.I_corr_peak   = k_corr * (res_hi{k}.I_peak_A - I0) + I0;
end

%% ── Plot 1: Corrected Thrust vs V ─────────────────────────────────────────
figure('Name','Thrust Comparison (Corrected)','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    plot(res_hi{k}.V_vec_mps, res_hi{k}.T_corr, ...
         'Color', colors{k}, 'LineWidth', 2, 'DisplayName', candidates{k,2});
end
yline(T_req,   'k--', 'LineWidth', 1.5, 'DisplayName', sprintf('T_{req} = %.1f N', T_req));
xline(V_climb, 'k:',  'LineWidth', 1.5, ...
      'DisplayName', sprintf('V_{climb} = %.1f m/s  (1.2\\timesV_s)', V_climb));
grid on; box on;
xlabel('Flight Speed  V_{\infty}  [m/s]');
ylabel('Corrected Thrust  T  [N]  (×0.65)');
title(sprintf('Corrected Thrust vs Speed  —  k_{corr}=0.65, R_{m,hi}=%.3f\\Omega', Rm_hi));
legend('Location','northeast','FontSize',7);

%% ── Plot 2: Corrected Current vs V — shaded Rm band ──────────────────────
figure('Name','Current Comparison (Corrected)','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    c    = colors{k};
    V    = res_lo{k}.V_vec_mps;
    I_up = res_lo{k}.I_corr;   % upper bound (Rm_lo → more current)
    I_dn = res_hi{k}.I_corr;   % lower bound (Rm_hi → less current)
    fill([V; flipud(V)], [I_up; flipud(I_dn)], c, ...
         'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(V, I_up, '--', 'Color', c, 'LineWidth', 1.2, 'HandleVisibility', 'off');
    plot(V, I_dn, '-',  'Color', c, 'LineWidth', 2,   'DisplayName', candidates{k,2});
end
yline(I_max_corr, 'k--', 'LineWidth', 1.5, 'DisplayName', sprintf('I_{max} = %d A', I_max_corr));
xline(V_climb,    'k:',  'LineWidth', 1.5, ...
      'DisplayName', sprintf('V_{climb} = %.1f m/s', V_climb));
grid on; box on;
xlabel('Flight Speed  V_{\infty}  [m/s]');
ylabel('Corrected Current  I  [A]  (×0.65 adjusted)');
title('Corrected Current vs Speed  —  band = [R_{m,lo}, R_{m,hi}]');
legend('Location','northeast','FontSize',7);
annotation('textbox',[0.13 0.82 0.35 0.05],'String', ...
    'Solid = R_{m,hi} (conservative)  |  Dashed = R_{m,lo} (optimistic)', ...
    'FitBoxToText','on','EdgeColor','none','FontSize',8);

%% ── Plot 3: CT vs J ───────────────────────────────────────────────────────
figure('Name','CT vs J Comparison','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    valid = isfinite(res_hi{k}.J_vec) & isfinite(res_hi{k}.CT_vec);
    if any(valid)
        plot(res_hi{k}.J_vec(valid), res_hi{k}.CT_vec(valid), ...
             'Color', colors{k}, 'LineWidth', 2, 'DisplayName', candidates{k,2});
    end
end
grid on; box on;
xlabel('Advance Ratio  J  [-]');
ylabel('C_T  [-]');
title('Thrust Coefficient vs Advance Ratio');
legend('Location','northeast','FontSize',7);

%% ── Summary table ─────────────────────────────────────────────────────────
fprintf('\n');
fprintf('================================================================================\n');
fprintf('PROP COMPARISON — BENCH-CORRECTED SURROGATE RESULTS\n');
fprintf('Motor: SunnySky 2212 1100KV | 3S 11.1V | k_corr = %.2f\n', k_corr);
fprintf('V_climb = %.1f m/s  (1.2 × V_stall = 1.2 × %.1f m/s)\n', V_climb, V_stall);
fprintf('D_climb = %.2f N at V_climb  |  W = %.2f N\n', D_climb, W);
fprintf('T_req = %.1f N  →  gamma_req = %.1f deg\n', T_req, gamma_req_deg);
fprintf('Rm band: %.3f Ω (motor only) to %.3f Ω (bench circuit)\n', Rm_lo, Rm_hi);
fprintf('================================================================================\n');
fprintf('%-14s  %10s  %10s  %11s  %11s  %10s  %5s\n', ...
    'Prop', 'T_static', 'T@Vclimb', 'I_pk(lo)', 'I_pk(hi)', 'gamma_max', 'ESC?');
fprintf('%-14s  %10s  %10s  %11s  %11s  %10s\n', ...
    '(corrected)', '[N]', '[N]', 'Rm_lo [A]', 'Rm_hi [A]', '[deg]');
fprintf('%s\n', repmat('-', 1, 80));

for k = 1:N
    T_at_V   = interp1(res_hi{k}.V_vec_mps, res_hi{k}.T_corr, V_climb, 'linear', 'extrap');
    I_lo_pk  = res_lo{k}.I_corr_peak;
    I_hi_pk  = res_hi{k}.I_corr_peak;
    % Achievable climb angle from corrected thrust (conservative Rm_hi)
    sin_g = (T_at_V - D_climb) / W;
    if sin_g > 0
        gamma_deg = asind(sin_g);
    else
        gamma_deg = 0;   % cannot climb — level flight only
    end
    clearance = candidates{k,5};
    esc_ok = I_lo_pk <= I_max_corr;
    if ~esc_ok,     esc_tag = 'OVER';
    elseif clearance, esc_tag = 'OK⚠';
    else,             esc_tag = 'OK';
    end
    meets_req = gamma_deg >= gamma_req_deg;
    marker = '';
    if meets_req, marker = ' ✓'; end
    fprintf('%-14s  %10.1f  %10.1f  %11.1f  %11.1f  %9.1f°  %5s%s\n', ...
        candidates{k,2}, res_hi{k}.T_corr_static, T_at_V, ...
        I_lo_pk, I_hi_pk, gamma_deg, esc_tag, marker);
end

fprintf('%s\n', repmat('-', 1, 80));
fprintf('gamma_req = %.1f deg  (from T_req=%.1f N, D_climb=%.2f N, W=%.2f N)\n', ...
    gamma_req_deg, T_req, D_climb, W);
fprintf('ESC OK: corrected I_peak(Rm_lo) <= %d A  |  ⚠ = verify 13" clearance\n', I_max_corr);
fprintf('================================================================================\n\n');
