% plotPropTests.m
% Overlays bench test data (static, throttle sweep) against surrogate
% predictions for 10x4.7 and 11x4.7 propellers.
%
% Run after:  run('run_project.m')
%
% Figures produced:
%   1 — Bench: Thrust vs Throttle %  (both props)
%   2 — Bench: Current vs Throttle % (both props)
%   3 — Bench: RPM vs Throttle %     (both props)
%   4 — Overlay: T vs V  (surrogate curves + bench static points at V=0)
%   5 — Overlay: I vs V  (surrogate curves + bench static points at V=0)

close all;

%% ── Paths ─────────────────────────────────────────────────────────────────
repoRoot = fileparts(mfilename('fullpath'));
if isempty(repoRoot), repoRoot = fileparts(which('plotPropTests')); end
propDataDir = fullfile(repoRoot, 'resources', 'propeller_surrogate_model', ...
                       'propeller_performance_data_files');
testDataDir = fullfile(repoRoot, 'Prop Tests');

%% ── Prop definitions ──────────────────────────────────────────────────────
% { csv file,  display label,  PER3 filename,  D_in,  pitch_in }
props = {
    '10x4.7.csv', '10×4.7',  'PER3_10x47SF.dat',  10,  4.7;
    '11x4.7.csv', '11×4.7',  'PER3_11x47SF.dat',  11,  4.7;
};
N      = size(props, 1);
colors = {'b', 'r'};

%% ── Motor / surrogate settings ────────────────────────────────────────────
motorBase.KV           = 1100;
motorBase.Rm           = 0.148;   % effective circuit Rm (bench back-calc: motor 54mΩ + ESC/wiring ~94mΩ)
motorBase.I0           = 0.8;
motorBase.Vbat         = 11.1;
motorBase.I_max        = 34;
motorBase.rho          = 1.19;
motorBase.V_vec_mps    = linspace(0, 30, 300);
motorBase.usePrelimModel = false;

T_req   = 4.2;    % [N]  5 deg climb at V_climb = 15 m/s
V_climb = 15.0;   % [m/s]

%% ── Load bench data and run surrogate for each prop ───────────────────────
bench = struct();
surr  = cell(N, 1);

for k = 1:N
    %% --- Bench CSV ---
    csvPath = fullfile(testDataDir, props{k,1});
    opts    = detectImportOptions(csvPath, 'Encoding', 'UTF-8');
    opts.VariableNamingRule = 'preserve';
    tbl     = readtable(csvPath, opts);

    % Column indices (header uses µ / · which MATLAB may mangle — use index)
    % 1=Time  2=ESC  9=Torque  10=Thrust  11=Voltage  12=Current  13=Elec RPM
    esc_us  = tbl{:, 2};
    thrust  = tbl{:,10};
    current = tbl{:,12};
    rpm_e   = tbl{:,13};

    valid = isfinite(esc_us) & isfinite(thrust) & isfinite(current);
    throttle_pct = (esc_us(valid) - 1000) / 10;   % 0–100 %

    % Sort by throttle for clean plots
    [throttle_s, idx] = sort(throttle_pct);
    thrust_s  = thrust(valid);  thrust_s  = thrust_s(idx);
    current_s = current(valid); current_s = current_s(idx);
    rpm_s     = rpm_e(valid);   rpm_s     = rpm_s(idx);

    % Smooth (5-point moving average to reduce test-stand noise)
    thrust_sm  = movmean(thrust_s,  5);
    current_sm = movmean(current_s, 5);
    rpm_sm     = movmean(rpm_s,     5);

    % Full-throttle static values
    ft = esc_us == 2000 & valid;
    bench(k).T_static   = mean(thrust(ft),  'omitnan');
    bench(k).I_static   = mean(current(ft), 'omitnan');
    bench(k).RPM_static = mean(rpm_e(ft),   'omitnan');

    % Store for plotting
    bench(k).label      = props{k,2};
    bench(k).throttle   = throttle_s;
    bench(k).thrust_sm  = thrust_sm;
    bench(k).current_sm = current_sm;
    bench(k).rpm_sm     = rpm_sm;

    %% --- Surrogate ---
    pIn          = motorBase;
    pIn.apcFile  = fullfile(propDataDir, props{k,3});
    pIn.propName = props{k,2};
    pIn.D_in     = props{k,4};
    pIn.pitch_in = props{k,5};

    fBefore = findall(0,'Type','figure');
    surr{k} = propulsionAnalysis(pIn);
    fAfter  = findall(0,'Type','figure');
    close(setdiff(fAfter, fBefore));
end

%% ── Figure 1: Thrust vs Throttle (bench) ─────────────────────────────────
figure('Name','Bench — Thrust vs Throttle','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    plot(bench(k).throttle, bench(k).thrust_sm, ...
         'Color', colors{k}, 'LineWidth', 2, 'DisplayName', bench(k).label);
end
grid on; box on;
xlabel('Throttle  [%]');
ylabel('Static Thrust  T  [N]');
title('Bench Test — Thrust vs Throttle');
legend('Location','northwest');

%% ── Figure 2: Current vs Throttle (bench) ────────────────────────────────
figure('Name','Bench — Current vs Throttle','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    plot(bench(k).throttle, bench(k).current_sm, ...
         'Color', colors{k}, 'LineWidth', 2, 'DisplayName', bench(k).label);
end
yline(motorBase.I_max, 'k--', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('I_{max} = %d A', motorBase.I_max));
grid on; box on;
xlabel('Throttle  [%]');
ylabel('Current  I  [A]');
title('Bench Test — Current vs Throttle');
legend('Location','northwest');

%% ── Figure 3: RPM vs Throttle (bench) ────────────────────────────────────
figure('Name','Bench — RPM vs Throttle','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    plot(bench(k).throttle, bench(k).rpm_sm, ...
         'Color', colors{k}, 'LineWidth', 2, 'DisplayName', bench(k).label);
end
grid on; box on;
xlabel('Throttle  [%]');
ylabel('Motor Speed  [RPM]');
title('Bench Test — RPM vs Throttle');
legend('Location','northwest');

%% ── Build bench-derived T(V) and I(V) curves using measured RPM ───────────
% Uses bench RPM (not surrogate) to compute J at each flight speed,
% then looks up CT(J)/CT(0) directly from the APC data file.
% T(V) = T_bench × CT(J(V)) / CT(0)   — no surrogate RPM used at all.
% I(V) = motor model at fixed n_bench: I = (Vbat - Ke×n_bench×2π) / Rm_eff
%         This is a lower bound since RPM rises slightly with V in reality.
V_plot = linspace(0, 30, 300);
Ke     = 60 / (2*pi*motorBase.KV);

for k = 1:N
    D_m      = props{k,4} * 0.0254;
    n_bench  = bench(k).RPM_static / 60;   % rev/s — from bench measurement
    rho      = motorBase.rho;

    % Read CT vs J from APC file at the bench RPM level
    apcPath = fullfile(propDataDir, props{k,3});
    [n_apc, J_apc, CT_apc] = readAPC(apcPath);

    % Find nearest RPM block in the file to bench RPM
    n_unique = unique(n_apc);
    [~, idx_n] = min(abs(n_unique - n_bench));
    n_near  = n_unique(idx_n);
    mask    = n_apc == n_near;
    J_block = J_apc(mask);
    CT_block = CT_apc(mask);
    [J_block, si] = sort(J_block);
    CT_block = CT_block(si);

    CT0 = interp1(J_block, CT_block, 0, 'linear', 'extrap');
    CT0 = max(CT0, 1e-6);

    % Thrust and current at each V using bench RPM
    T_bench_curve = zeros(size(V_plot));
    I_bench_curve = zeros(size(V_plot));
    omega_bench   = n_bench * 2*pi;
    I_at_bench_rpm = (motorBase.Vbat - Ke * omega_bench) / motorBase.Rm;

    for vi = 1:numel(V_plot)
        J_v  = V_plot(vi) / (n_bench * D_m);
        CT_v = max(0, interp1(J_block, CT_block, J_v, 'linear', 'extrap'));
        T_bench_curve(vi) = bench(k).T_static * (CT_v / CT0);
        % Current: motor model at fixed bench RPM (RPM slightly rises in flight
        % so this is a slight over-estimate; use bench I_static to anchor)
        I_bench_curve(vi) = bench(k).I_static * (CT_v / CT0);
    end

    bench(k).V_plot       = V_plot;
    bench(k).T_from_bench = T_bench_curve;
    bench(k).I_from_bench = I_bench_curve;
end

%% ── Figure 4: Thrust vs Flight Speed ─────────────────────────────────────
figure('Name','Thrust vs V — Surrogate vs Bench','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    % Surrogate (dashed)
    plot(surr{k}.V_vec_mps, surr{k}.T_vec_N, ...
         '--', 'Color', colors{k}, 'LineWidth', 1.5, ...
         'DisplayName', sprintf('%s surrogate', bench(k).label));
    % Bench-derived curve: measured T_static + measured RPM + APC CT(J)/CT(0)
    plot(bench(k).V_plot, bench(k).T_from_bench, ...
         '-', 'Color', colors{k}, 'LineWidth', 2.5, ...
         'DisplayName', sprintf('%s bench-derived', bench(k).label));
    % Measured static point
    plot(0, bench(k).T_static, 'o', ...
         'Color', colors{k}, 'MarkerFaceColor', colors{k}, 'MarkerSize', 9, ...
         'HandleVisibility','off');
end
yline(T_req,   'k--', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('T_{req} = %.1f N', T_req));
xline(V_climb, 'k:',  'LineWidth', 1.5, ...
      'DisplayName', sprintf('V_{climb} = %.0f m/s', V_climb));
grid on; box on;
xlabel('Flight Speed  V_{\infty}  [m/s]');
ylabel('Thrust  T  [N]');
title('Thrust vs Flight Speed — Surrogate (dashed) vs Bench-Derived (solid)');
legend('Location','northeast');

%% ── Figure 5: Current vs Flight Speed ────────────────────────────────────
figure('Name','Current vs V — Surrogate vs Bench','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    plot(surr{k}.V_vec_mps, surr{k}.I_vec_A, ...
         '--', 'Color', colors{k}, 'LineWidth', 1.5, ...
         'DisplayName', sprintf('%s surrogate', bench(k).label));
    plot(bench(k).V_plot, bench(k).I_from_bench, ...
         '-', 'Color', colors{k}, 'LineWidth', 2.5, ...
         'DisplayName', sprintf('%s bench-derived', bench(k).label));
    plot(0, bench(k).I_static, 'o', ...
         'Color', colors{k}, 'MarkerFaceColor', colors{k}, 'MarkerSize', 9, ...
         'HandleVisibility','off');
end
yline(motorBase.I_max, 'k--', 'LineWidth', 1.5, ...
      'DisplayName', sprintf('I_{max} = %d A', motorBase.I_max));
grid on; box on;
xlabel('Flight Speed  V_{\infty}  [m/s]');
ylabel('Current  I  [A]');
title('Current vs Flight Speed — Surrogate (dashed) vs Bench-Derived (solid)');
legend('Location','northeast');

%% ── Console summary ───────────────────────────────────────────────────────
fprintf('\n============================================================\n');
fprintf('BENCH vs SURROGATE — STATIC (V=0) COMPARISON\n');
fprintf('Motor: SunnySky 2212 1100KV | 3S 11.1V | Rm=54mΩ\n');
fprintf('============================================================\n');
fprintf('%-10s  %12s  %12s  %8s\n', 'Prop', 'T_surr(N)', 'T_bench(N)', 'Error %');
fprintf('%s\n', repmat('-',1,50));
for k = 1:N
    T_s = surr{k}.T_static_N;
    T_b = bench(k).T_static;
    err = (T_s - T_b) / T_b * 100;
    fprintf('%-10s  %12.2f  %12.2f  %8.1f%%\n', bench(k).label, T_s, T_b, err);
end
fprintf('%s\n', repmat('-',1,50));
fprintf('\n%-10s  %12s  %12s  %8s\n', 'Prop', 'I_surr(A)', 'I_bench(A)', 'Error %');
fprintf('%s\n', repmat('-',1,50));
for k = 1:N
    I_s = surr{k}.I_static_A;
    I_b = bench(k).I_static;
    err = (I_s - I_b) / I_b * 100;
    fprintf('%-10s  %12.2f  %12.2f  %8.1f%%\n', bench(k).label, I_s, I_b, err);
end
fprintf('============================================================\n\n');

%% ── Figure 6: Actuator Disk T(V) — independent of APC data ──────────────
% Uses only measured T_static and propeller diameter.
% Physics: constant mechanical power + momentum equation solved iteratively.
%   T*(V + vi) = P_mech  (power balance, constant throttle approximation)
%   T = 2*rho*A*vi*(V + vi)   (momentum theory)
% Combining: 2*rho*A*vi*(V+vi)^2 = P_mech, solved via Newton iteration.

rho_ad = motorBase.rho;

for k = 1:N
    D_m  = props{k,4} * 0.0254;
    A_d  = pi * (D_m/2)^2;
    T0   = bench(k).T_static;
    vi0  = sqrt(T0 / (2 * rho_ad * A_d));
    P0   = T0 * vi0;

    T_disk = zeros(size(V_plot));
    for vi = 1:numel(V_plot)
        V_inf  = V_plot(vi);
        vi_est = vi0;
        for iter = 1:50
            f      = 2*rho_ad*A_d*vi_est*(V_inf + vi_est)^2 - P0;
            df     = 2*rho_ad*A_d*((V_inf + vi_est)^2 + 2*vi_est*(V_inf + vi_est));
            vi_est = vi_est - f/df;
            if abs(f/P0) < 1e-6, break; end
        end
        T_disk(vi) = 2 * rho_ad * A_d * vi_est * (V_inf + vi_est);
    end
    bench(k).T_disk = T_disk;
end

figure('Name','Thrust vs V — Actuator Disk vs Bench-Derived','NumberTitle','off','Color','w');
hold on;
for k = 1:N
    plot(V_plot, bench(k).T_disk, '-.', 'Color', colors{k}, 'LineWidth', 2, ...
         'DisplayName', sprintf('%s actuator disk', bench(k).label));
    plot(bench(k).V_plot, bench(k).T_from_bench, '-', 'Color', colors{k}, ...
         'LineWidth', 2, 'DisplayName', sprintf('%s bench-derived', bench(k).label));
    plot(0, bench(k).T_static, 'o', 'Color', colors{k}, ...
         'MarkerFaceColor', colors{k}, 'MarkerSize', 9, 'HandleVisibility','off');
end
yline(T_req,   'k--', 'LineWidth', 1.5, 'DisplayName', sprintf('T_{req} = %.1f N', T_req));
xline(V_climb, 'k:',  'LineWidth', 1.5, 'DisplayName', sprintf('V_{climb} = %.0f m/s', V_climb));
grid on; box on;
xlabel('Flight Speed  V_{\infty}  [m/s]');
ylabel('Thrust  T  [N]');
title('Thrust vs Flight Speed — Actuator Disk (dash-dot) vs Bench-Derived (solid)');
legend('Location','northeast');

%% ── Print actuator disk T_climb comparison ───────────────────────────────
fprintf('ACTUATOR DISK vs BENCH-DERIVED T at V=%.0f m/s\n', V_climb);
fprintf('%-10s  %12s  %12s  %8s\n', 'Prop', 'T_disk(N)', 'T_bench(N)', 'Diff %');
fprintf('%s\n', repmat('-',1,50));
for k = 1:N
    T_d  = interp1(V_plot, bench(k).T_disk,       V_climb, 'linear');
    T_b  = interp1(bench(k).V_plot, bench(k).T_from_bench, V_climb, 'linear');
    diff = (T_d - T_b) / T_b * 100;
    fprintf('%-10s  %12.2f  %12.2f  %8.1f%%\n', bench(k).label, T_d, T_b, diff);
end
fprintf('%s\n', repmat('-',1,50));

%% ── Print bench-derived T_climb ───────────────────────────────────────────
fprintf('BENCH-DERIVED T at V=%.0f m/s (using measured RPM + APC CT ratio)\n', V_climb);
fprintf('%-10s  %12s  %8s\n', 'Prop', 'T_climb(N)', 'Pass?');
fprintf('%s\n', repmat('-',1,35));
for k = 1:N
    T_cl = interp1(bench(k).V_plot, bench(k).T_from_bench, V_climb, 'linear');
    tag  = 'YES';  if T_cl < T_req, tag = 'NO'; end
    fprintf('%-10s  %12.2f  %8s\n', bench(k).label, T_cl, tag);
end
fprintf('%s\n', repmat('-',1,35));
fprintf('Requirement: T >= %.1f N at V = %.0f m/s\n\n', T_req, V_climb);

%% ══════════════════════════════════════════════════════════════════════════
%  LOCAL FUNCTIONS
%% ══════════════════════════════════════════════════════════════════════════

function [n_out, J_out, CT_out] = readAPC(filename)
% Parse a PER3 .dat file and return (n [rev/s], J, CT) vectors.
    n_out = []; J_out = []; CT_out = [];
    txt   = fileread(filename);
    lines = splitlines(string(txt));
    currentRPM = NaN;
    for i = 1:numel(lines)
        line = strtrim(lines(i));
        tok  = regexp(line, 'PROP RPM\s*=\s*([0-9]+)', 'tokens');
        if ~isempty(tok)
            currentRPM = str2double(tok{1}{1});
            continue;
        end
        if isnan(currentRPM), continue; end
        nums = sscanf(line, '%f');
        if numel(nums) >= 5
            J_v  = nums(2);
            CT_v = nums(4);
            if isfinite(J_v) && J_v >= 0 && isfinite(CT_v) && CT_v >= 0
                n_out(end+1,1)  = currentRPM / 60; %#ok<AGROW>
                J_out(end+1,1)  = J_v;             %#ok<AGROW>
                CT_out(end+1,1) = CT_v;            %#ok<AGROW>
            end
        end
    end
end
