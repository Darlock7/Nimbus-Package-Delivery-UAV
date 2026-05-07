function plotSpanwiseAeroEstimate(spanOut)
% plotSpanwiseAeroEstimate
%
% Plots key first-pass spanwise aerodynamic quantities.

    %% -------- Local chord --------
    figure('Name','Spanwise Chord Distribution','NumberTitle','off');
    plot(spanOut.eta, spanOut.c_m, 'LineWidth', 2);
    grid on;
    xlabel('\eta = y / (b/2)');
    ylabel('Local chord c(y) [m]');
    title('Spanwise Chord Distribution');

    %% -------- Effective alpha --------
    figure('Name','Spanwise Effective Angle of Attack','NumberTitle','off');
    plot(spanOut.eta, spanOut.alpha_eff_deg, 'LineWidth', 2);
    grid on;
    xlabel('\eta = y / (b/2)');
    ylabel('\alpha_{eff}(y) [deg]');
    title('Spanwise Effective Angle of Attack');

    %% -------- Local section cl --------
    figure('Name','Spanwise Section Lift Coefficient','NumberTitle','off');
    plot(spanOut.eta, spanOut.cl_local, 'LineWidth', 2);
    grid on;
    xlabel('\eta = y / (b/2)');
    ylabel('Local section c_l(y)');
    title('Spanwise Section Lift Coefficient');

    %% -------- Lift per unit span --------
    figure('Name','Spanwise Lift per Unit Span','NumberTitle','off');
    plot(spanOut.eta, spanOut.Lprime_N_per_m, 'LineWidth', 2);
    grid on;
    xlabel('\eta = y / (b/2)');
    ylabel('L''(y) [N/m]');
    title('Spanwise Lift per Unit Span');

    %% -------- Local Cm0 --------
    figure('Name','Spanwise Zero-Lift Pitching Moment','NumberTitle','off');
    plot(spanOut.eta, spanOut.cm0_local, 'LineWidth', 2);
    grid on;
    xlabel('\eta = y / (b/2)');
    ylabel('Local C_{m0}(y)');
    title('Spanwise Zero-Lift Pitching Moment Trend');
end