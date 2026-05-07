%% 3.1: Euler Explicit Diffusion


clear; clc; close all

% Load data:
load('gotritons-1.mat','T','xx','yy')
T = double(T);

% Constants:
alpha = 2;
t_final = 0.001;
SF = 2;

% Grid spacing:
dx = xx(2,1) - xx(1,1);
dy = yy(1,2) - yy(1,1);

fprintf('dx      = %.6e\n', dx)
fprintf('dy      = %.6e\n', dy)

% Stability condition:


dt_max = (1/4) / (alpha/dx^2 + alpha/dy^2);
dt = dt_max / SF;

fprintf('dt_max  = %.6e\n', dt_max)
fprintf('dt_safe = %.6e\n', dt)

% Time initialization:
t = 0;
n = 0;

% Plot control:
plotEvery = 50;

figure

while t < t_final

    if t + dt > t_final
        dt = t_final - t;
    end

    % Second derivatives using periodic finite differences:
    d2Tdx2 = d2dx2_periodic(T, dx);
    d2Tdy2 = d2dy2_periodic(T, dy);

    % Euler explicit update:
    T = T + alpha*dt*(d2Tdx2 + d2Tdy2);

    % Advance time:
    t = t + dt;
    n = n + 1;

    % Plot every few steps:
    if mod(n, plotEvery) == 0 || t >= t_final
        pcolor(xx, yy, T)
        shading interp
        axis equal tight
        colorbar
        clim([0 1]);
        xlabel('x')
        ylabel('y')
        title(sprintf('Euler Explicit Diffusion, t = %.6f s', t))
        drawnow
    end

end

fprintf('Final time reached: %.6e\n', t)
fprintf('Number of time steps: %d\n', n)

%% ---------------------------------------------------------
% Periodic second derivative in x
%% ---------------------------------------------------------

function d2fdx2 = d2dx2_periodic(f, dx)

    [nx, ny] = size(f);
    d2fdx2 = zeros(nx, ny);

    for i = 1:nx

        ip = i + 1;
        im = i - 1;

        % Periodic wrap in x-direction:
        if i == nx
            ip = 1;
        end

        if i == 1
            im = nx;
        end

        for j = 1:ny
            d2fdx2(i,j) = (f(ip,j) - 2*f(i,j) + f(im,j)) / dx^2;
        end

    end

end

%% ---------------------------------------------------------
% Periodic second derivative in y
%% ---------------------------------------------------------

function d2fdy2 = d2dy2_periodic(f, dy)

    [nx, ny] = size(f);
    d2fdy2 = zeros(nx, ny);

    for i = 1:nx

        for j = 1:ny

            jp = j + 1;
            jm = j - 1;

            % Periodic wrap in y-direction:
            if j == ny
                jp = 1;
            end

            if j == 1
                jm = ny;
            end

            d2fdy2(i,j) = (f(i,jp) - 2*f(i,j) + f(i,jm)) / dy^2;

        end

    end

end
