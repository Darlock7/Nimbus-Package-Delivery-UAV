%% Programming 3.2: Euler Explicit Advection


clear; clc; close all

% Load data:
load('gotritons-1.mat','T','xx','yy')
T0 = double(T);

% Constants:
cx = 1;
cy = 1;

SF = 2;
t_final_back = 2;
t_final_cent = 0.25;

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

% Plot control:
plotEvery = 20;

%% =========================================================
% BACKWARD DIFFERENCE (STABLE)
%% =========================================================

T = T0;
t = 0;
n = 0;

figure

while t < t_final_back

    if t + dt > t_final_back
        dt_step = t_final_back - t;
    else
        dt_step = dt;
    end

    dTdx = ddx_backward_periodic(T, dx);
    dTdy = ddy_backward_periodic(T, dy);

    T = T - dt_step*(cx*dTdx + cy*dTdy);

    t = t + dt_step;
    n = n + 1;

    if mod(n, plotEvery) == 0 || t >= t_final_back
        pcolor(xx, yy, T)
        shading interp
        axis equal tight
        colorbar
        clim([0 1])   
        xlabel('x')
        ylabel('y')
        title(sprintf('Backward Difference, t = %.4f', t))
        drawnow
    end

end

fprintf('\nBackward difference complete.\n')

%% =========================================================
% CENTRAL DIFFERENCE (UNSTABLE)
%% =========================================================

T = T0;
t = 0;
n = 0;

figure

while t < t_final_cent

    if t + dt > t_final_cent
        dt_step = t_final_cent - t;
    else
        dt_step = dt;
    end

    dTdx = ddx_central_periodic(T, dx);
    dTdy = ddy_central_periodic(T, dy);

    T = T - dt_step*(cx*dTdx + cy*dTdy);

    t = t + dt_step;
    n = n + 1;

    if mod(n, plotEvery) == 0 || t >= t_final_cent
        pcolor(xx, yy, T)
        shading interp
        axis equal tight
        colorbar
        clim([0 1])  
        xlabel('x')
        ylabel('y')
        title(sprintf('Central Difference (Unstable), t = %.4f', t))
        drawnow
    end

end

fprintf('\nCentral difference complete.\n')

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

%% ---------------------------------------------------------
% CENTRAL DIFFERENCE X
%% ---------------------------------------------------------
function dfdx = ddx_central_periodic(f, dx)

    [nx, ny] = size(f);
    dfdx = zeros(nx, ny);

    for i = 1:nx

        ip = i + 1;
        im = i - 1;

        if i == nx
            ip = 1;
        end
        if i == 1
            im = nx;
        end

        for j = 1:ny
            dfdx(i,j) = (f(ip,j) - f(im,j)) / (2*dx);
        end

    end

end

%% ---------------------------------------------------------
% CENTRAL DIFFERENCE Y
%% ---------------------------------------------------------
function dfdy = ddy_central_periodic(f, dy)

    [nx, ny] = size(f);
    dfdy = zeros(nx, ny);

    for i = 1:nx
        for j = 1:ny

            jp = j + 1;
            jm = j - 1;

            if j == ny
                jp = 1;
            end
            if j == 1
                jm = ny;
            end

            dfdy(i,j) = (f(i,jp) - f(i,jm)) / (2*dy);

        end
    end

end