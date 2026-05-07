% Explicit Euler for 2-D heat equations with constant bulk velocity
% OTS, 2020

clear variables
close all
clc
addpath('functions_periodic')

load('gotritons.mat','T','xx','yy');

% Solver parameters
c           = [1 1];        % bulk velocity
t_end       = 2;            % final time

% Grid parameters
[nx,ny]     = size(xx);
dx          = xx(2,1)-xx(1,1);
dy          = yy(1,2)-yy(1,1);

% determine number of timesteps
safety_fac  = 1.1;                                % safety factor
dt_max      = 1/(abs(c(1))/dx + abs(c(2))/dy);    % maximum time step
nt          = ceil(t_end/(dt_max/safety_fac));    % number of time steps
dt          = t_end/nt;                           % timestep               


%%
figure
for ti = 1:nt
   
    %%%%%%%%%%%%%%%%%%
    % EXPLICIT EULER % (1st-order forward difference in time)
    %%%%%%%%%%%%%%%%%%
    
    dTdx    = ddx_bwd(T,dx,'periodic');
    dTdy    = ddy_bwd(T,dy,'periodic');
    
    T       = T - c(1)*dt*dTdx - c(2)*dt*dTdy;
        
    % Plot temperature at time t
    pcolor(xx,yy,T); shading interp, caxis([0 1]); axis equal tight;
    title(['T @ t=' num2str(dt*ti)])
    xlabel('x');
    ylabel('y');
    colorbar;
    
    drawnow    
end




%%%%%%%%%%%%%%%%%%
%    FUNCTIONS   %
%%%%%%%%%%%%%%%%%%

% First-order backward difference difference function in x
function dfdx = ddx_bwd(f,dx,bc)

    % set default value for 'bc'
    if nargin<3, bc = 'one-sided'; end

    % determine field size
    [nx,ny]     = size(f);

    % allocate return field
    dfdx        = zeros(nx,ny);

    % backward difference
    for i=2:nx
        for j=1:ny
            dfdx(i,j) = (f(i,j)-f(i-1,j))/dx;
        end
    end

    switch bc
        case 'periodic'

            % assuming periodicity (left boundary)
            i = 1;
            for j=1:ny
                dfdx(i,j) = (f(i,j)-f(end,j))/dx;
            end

        otherwise

            % forward difference for first point
            i = 1;
            for j=1:ny
                dfdx(i,j) = (f(i+1,j)-f(i,j))/dx;
            end      
    end
end

% First-order backward difference difference function in y
function dfdy = ddy_bwd(f,dy,bc)

    % set default value for 'bc'
    if nargin<3, bc = 'one-sided'; end

    % determine field size
    [nx,ny]     = size(f);

    % allocate return field
    dfdy        = zeros(nx,ny);

    % backward difference
    for i=1:nx
        for j=2:ny
            dfdy(i,j) = (f(i,j)-f(i,j-1))/dy;
        end
    end

    switch bc
        case 'periodic'

            % assuming periodicity (bottom boundary)
            j = 1;
            for i=1:nx
                dfdy(i,j) = (f(i,j)-f(i,ny))/dy;
            end

        otherwise

            % forward difference for first point
            j = 1;
            for i=1:nx
                dfdy(i,j) = (f(i,j+1)-f(i,j))/dy;
            end
    end
end