% Assignment 1 FIXED
% John Sigafoos
% A18544700
% Due Wednesday April 8th 2026 @2359

clear; clc; close all;
%% Problem 1.1.
% Write a Matlab script that opens the file and animates 
% the flow field, u and v, in time.

% loading given workspace
load('cylinder_Re100-1.mat');
% given: dt, u, v, x, y

% Solving for number of 'snapshots':
nt = size(u,1); % should return 301

% Plotting the Flow Field
figure

% animation loop:
for n = 1:nt
    % building subplot u:
    u_n = squeeze(u(n,:,:)); % collects xy field at a given time instance
    subplot(2,1,1)
    pcolor(x,y,u_n)
    shading interp
    xlabel('x')
    ylabel('y')
    title(['u (' num2str(n) '/' num2str(nt) ')'])
    axis equal tight
    caxis([-0.5 2])
    hold on
    rectangle('Position',[-0.5 -0.5 1 1], ...
          'Curvature',[1 1], ...
          'LineStyle','none', ...
          'FaceColor',[1 1 1]);
    hold off

    % building subplot v:
    v_n = squeeze(v(n,:,:)); % collects xy field at a given time instance
    subplot(2,1,2)
    pcolor(x,y,v_n)
    shading interp
    xlabel('x')
    ylabel('y')
    title(['v (' num2str(n) '/' num2str(nt) ')'])
    axis equal tight
    caxis([-1 1])
    hold on
    rectangle('Position',[-0.5 -0.5 1 1], ...
          'Curvature',[1 1], ...
          'LineStyle','none', ...
          'FaceColor',[1 1 1]);
    hold off
    
    % Annotate overall title with time
    sgtitle(['t = ', num2str((n-1)*dt)])
    
    drawnow
end