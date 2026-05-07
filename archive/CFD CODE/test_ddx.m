%% Test scripts for finite difference functions

clear all
close all
clc

% make sure to copy your *.m-files into the 'functions' directory  
addpath('functions')

% 1-D coordinates 
nx          = 50;
ny          = 30;
x           = linspace(0,10,nx);
y           = linspace(0,7, ny);
dx          = x(2)-x(1);
dy          = y(2)-y(1);

% 2-D coordinates
[xx,yy]     = ndgrid(x,y);

% surrogate data
f                   =  cos(xx).*cos(yy);
dfdx_analytical     = -sin(xx).*cos(yy);
d2fdx2_analytical   = -cos(xx).*cos(yy);

%% First derivative and error
figure
subplot(2,5,[1 6])
pcolor(xx,yy,f)
caxis([-1 1])
axis equal tight
title('f')

subplot(2,5,[2 7])
pcolor(xx,yy,dfdx_analytical)
caxis([-1 1])
axis equal tight
title('df/dx (analytical)')

subplot(2,5,3)
dfdx = ddx_fwd(f,dx);
pcolor(xx,yy,dfdx)
caxis([-1 1])
axis equal tight
title('df/dx (forward difference)')

subplot(2,5,3+5)
pcolor(xx,yy,abs(dfdx-dfdx_analytical))
caxis([-0.1 0.1])
axis equal tight
title('Error - df/dx (forward difference)')

subplot(2,5,4)
dfdx = ddx_bwd(f,dx);
pcolor(xx,yy,dfdx)
caxis([-1 1])
axis equal tight
title('df/dx (backward difference)')

subplot(2,5,4+5)
pcolor(xx,yy,abs(dfdx-dfdx_analytical))
caxis([-0.1 0.1])
axis equal tight
title('Error - df/dx (backward difference)')


subplot(2,5,5)
dfdx = ddx_central(f,dx);
pcolor(xx,yy,dfdx)
caxis([-1 1])
axis equal tight
title('df/dx (central difference)')

subplot(2,5,5+5)
pcolor(xx,yy,abs(dfdx-dfdx_analytical))
caxis([-0.1 0.1])
axis equal tight
title('Error - df/dx (central difference)')

