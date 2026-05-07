%% Test scripts for d2dy2

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
dfdy_analytical     = -cos(xx).*sin(yy);
d2fdy2_analytical   = -cos(xx).*cos(yy);

%% Second derivative and error
figure
subplot(1,4,1)
pcolor(xx,yy,f)
caxis([-1 1])
axis equal tight
title('f (analytical)')

subplot(1,4,2)
pcolor(xx,yy,d2fdy2_analytical)
caxis([-1 1])
axis equal tight
title('d^2f/dy^2 (analytical)')

subplot(1,4,3)
d2fdy2 = d2dy2(f,dy);
pcolor(xx,yy,d2fdy2)
caxis([-1 1])
axis equal tight
title('d^2f/dy^2 (central second difference)')

subplot(1,4,4)
pcolor(xx,yy,abs(d2fdy2-d2fdy2_analytical))
caxis([-0.1 0.1])
axis equal tight
title('Error - d^2f/dy^2 (central second difference)')







