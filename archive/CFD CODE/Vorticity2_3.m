clear; clc; close all

load cylinder_Re100.mat
% Loads: dt, u, v, x, y

% Mesh Size:
dx = x(2,1) - x(1,1);
dy = y(1,2) - y(1,1);

% sizes:
nt = size(u,1);
nx = size(u,2);
ny = size(u,3);

% preallocate vorticity:
omega = zeros(nt,nx,ny);

figure

for n = 1:nt
    
    % Velocity a given n:
    u_now = squeeze(u(n,:,:));
    v_now = squeeze(v(n,:,:));
    

    % dv/dx:
    dvdx = zeros(nx,ny);
    dvdx(1:nx-1,:) = (v_now(2:nx,:) - v_now(1:nx-1,:)) / dx;
    dvdx(nx,:)     = (v_now(nx,:) - v_now(nx-1,:)) / dx;
    
  
    % du/dy: 
    dudy = zeros(nx,ny);
    dudy(:,1:ny-1) = (u_now(:,2:ny) - u_now(:,1:ny-1)) / dy;
    dudy(:,ny)     = (u_now(:,ny) - u_now(:,ny-1)) / dy;
    
    % vorticity:
    omega(n,:,:) = dvdx - dudy;
    
    % ploting: 
    pcolor(x,y,squeeze(omega(n,:,:)))
    shading interp
    axis equal tight
    colorbar
    colormap(jet)
    maxval = max(abs(omega(:)));
    caxis([-maxval maxval])
    xlabel('x')
    ylabel('y')
    title(['Vorticity, t = ', num2str((n-1)*dt,'%.3f'), ' s'])
    caxis([-5 5])  
    
    hold on
    rectangle('Position',[-0.5 -0.5 1 1], ...
              'Curvature',[1 1], ...
              'LineStyle','none', ...
              'FaceColor',[1 1 1]);
    hold off
    
    drawnow
end