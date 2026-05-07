%% Programming 3.3: MacCormack Advection


clear; clc; close all

% Load data:
load('gotritons-1.mat','T','xx','yy')
T = double(T);

% Constants:
cx = 1;
cy = 1;

SF = 2;
t_final = 2;

% Grid spacing:
dx = xx(2,1) - xx(1,1);
dy = yy(1,2) - yy(1,1);

fprintf('dx = %.6e\n', dx)
fprintf('dy = %.6e\n', dy)

% Stability condition:

dt_max = 1 / (cx/dx + cy/dy);
dt = dt_max / SF;

fprintf('dt_max = %.6e\n', dt_max)
fprintf('dt     = %.6e\n', dt)

% Time initialization:
t = 0;
n = 0;

% Plot control:
plotEvery = 20;

figure

while t < t_final

    if t + dt > t_final
        dt_step = t_final - t;
    else
        dt_step = dt;
    end

    % Predictor step: forward differences
    dTdx_forward = ddx_forward_periodic(T, dx);
    dTdy_forward = ddy_forward_periodic(T, dy);

    Tbar = T - dt_step*(cx*dTdx_forward + cy*dTdy_forward);

    % Corrector step: backward differences on predicted field
    dTbardx_backward = ddx_backward_periodic(Tbar, dx);
    dTbardy_backward = ddy_backward_periodic(Tbar, dy);

    T = 0.5*(T + Tbar - dt_step*(cx*dTbardx_backward + cy*dTbardy_backward));

    % Advance time
    t = t + dt_step;
    n = n + 1;

    % Plot
    if mod(n, plotEvery) == 0 || t >= t_final
        pcolor(xx, yy, T)
        shading interp
        axis equal tight
        colorbar
        clim([0 1])
        xlabel('x')
        ylabel('y')
        title(sprintf('MacCormack Advection, t = %.4f', t))
        drawnow
    end

end

fprintf('\nMacCormack complete.\n')
fprintf('Final time = %.6e\n', t)
fprintf('Number of steps = %d\n', n)

%% ---------------------------------------------------------
% FORWARD DIFFERENCE X
%% ---------------------------------------------------------
function dfdx = ddx_forward_periodic(f, dx)

    [nx, ny] = size(f);
    dfdx = zeros(nx, ny);

    for i = 1:nx

        ip = i + 1;

        if i == nx
            ip = 1;
        end

        for j = 1:ny
            dfdx(i,j) = (f(ip,j) - f(i,j)) / dx;
        end

    end

end

%% ---------------------------------------------------------
% FORWARD DIFFERENCE Y
%% ---------------------------------------------------------
function dfdy = ddy_forward_periodic(f, dy)

    [nx, ny] = size(f);
    dfdy = zeros(nx, ny);

    for i = 1:nx
        for j = 1:ny

            jp = j + 1;

            if j == ny
                jp = 1;
            end

            dfdy(i,j) = (f(i,jp) - f(i,j)) / dy;

        end
    end

end

%% ---------------------------------------------------------
% BACKWARD DIFFERENCE X
%% ---------------------------------------------------------
function dfdx = ddx_backward_periodic(f, dx)

    [nx, ny] = size(f);
    dfdx = zeros(nx, ny);

    for i = 1:nx

        im = i - 1;

        if i == 1
            im = nx;
        end

        for j = 1:ny
            dfdx(i,j) = (f(i,j) - f(im,j)) / dx;
        end

    end

end

%% ---------------------------------------------------------
% BACKWARD DIFFERENCE Y
%% ---------------------------------------------------------
function dfdy = ddy_backward_periodic(f, dy)

    [nx, ny] = size(f);
    dfdy = zeros(nx, ny);

    for i = 1:nx
        for j = 1:ny

            jm = j - 1;

            if j == 1
                jm = ny;
            end

            dfdy(i,j) = (f(i,j) - f(i,jm)) / dy;

        end
    end

end