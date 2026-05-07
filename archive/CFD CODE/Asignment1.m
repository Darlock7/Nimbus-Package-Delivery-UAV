% Assignment 1
% John Sigafoos
% A18544700
% Due Wednesday April 8th 2026 @2359

clear; clc; close all;

%% Problem 1.1.
% Write a Matlab script that opens the file and animates 
% the flow field, u and v, in time.

%loading given workspace
load('cylinder_Re100-1.mat');
% given: dt, u, v, x, y

% Solving for number of 'snapshots':
nt = size(u,1); % should return 301 (as stated in canvas)

% Plotting the Flow Field
figure

%  animation loop:
for n = 1:nt
      % building subplot u:
    u_n = squeeze(u(n,:,:)); %collects xy field at a given time instance
    subplot(2,1,1);
    pcolor(x,y,u_n);
    shading interp;
    xlabel('x')
    ylabel('y')
    title('u')
    axis equal tight
    hold on
    rectangle('Position',[-0.5 -0.5 1 1], ...
          'Curvature',[1 1], ...
          'LineStyle','none', ...
          'FaceColor',[1 1 1]);
    hold off
     % building subplot v:
     v_n = squeeze(v(n,:,:)); % collects xy field at a given time instance
    subplot(2,1,2);
    pcolor(x,y,v_n);
    shading interp;
    xlabel('x')
    ylabel('y')
    title('v')
    axis equal tight
    hold on
    rectangle('Position',[-0.5 -0.5 1 1], ...
          'Curvature',[1 1], ...
          'LineStyle','none', ...
          'FaceColor',[1 1 1]);
    hold off
    
    % Annotate Overall title with time
    sgtitle(['t = ', num2str((n-1)*dt)])
    
    drawnow
end

%% Problem 1.2 
% Problem 1.2.: Write a Matlab script that computes and visualizes the mean
%  flow fields, and When computing the mean flow, discard the initial 
% transient, i.e., the first 150 time instances. 
% visualize the mean flow fields in a single figure with two subplots with 
% titles axis labels (and do whatever else you want to make the figure look 
% nice)
% you may either add code to your existing m-file, or make a new one
% if you don't know it already, familiarize yourself with the following 
% command: mean

% Compute mean flow (discarding transient)
u_mean = squeeze(mean(u(151:end,:,:),1)); % mean of u after transient
v_mean = squeeze(mean(v(151:end,:,:),1)); % mean of v after transient

% Plot mean flow fields
figure

% Subplot for mean u
subplot(2,1,1)
pcolor(x,y,u_mean)
shading interp
xlabel('x')
ylabel('y')
title('Mean u')
axis equal tight
colorbar
hold on
rectangle('Position',[-0.5 -0.5 1 1], ...
      'Curvature',[1 1], ...
      'LineStyle','none', ...
      'FaceColor',[1 1 1]);
hold off

% Subplot for mean v
subplot(2,1,2)
pcolor(x,y,v_mean)
shading interp
xlabel('x')
ylabel('y')
title('Mean v')
axis equal tight
colorbar
hold on
rectangle('Position',[-0.5 -0.5 1 1], ...
      'Curvature',[1 1], ...
      'LineStyle','none', ...
      'FaceColor',[1 1 1]);
hold off

% Overall title
sgtitle('Mean Flow Fields (Transient Removed)')

%% Problem 1.3
% Write a Matlab script that visualizes the streamlines of the 
% mean flow in addition to the mean flow field, 
% Use a single figure to plot the flow field, 
% , and the streamlines (i.e: overlay the streamlines on the plot for 
% ). Don't forget the title and axis labels!

%% Problem 1.3.
% Write a Matlab script that visualizes the streamlines of the mean flow
% in addition to the mean flow field, u.

figure
pcolor(x,y,u_mean)
shading interp
xlabel('x')
ylabel('y')
title('Mean u with Streamlines')
axis equal tight
colorbar
hold on

% Plot cylinder
rectangle('Position',[-0.5 -0.5 1 1], ...
      'Curvature',[1 1], ...
      'LineStyle','none', ...
      'FaceColor',[1 1 1]);

% Define streamline starting points
startx = -4*ones(10,1);
starty = [-4 -3 -2 -1 -0.01 0.01 1 2 3 4];

% Plot streamlines
streamline(x',y',u_mean',v_mean',startx,starty)

hold off
%% Problem 1.4
%  Using the decomposition above, write a Matlab script that computes
%  and animates the fluctuations 
%  and use the mean flow, 
%  and 
% , from Problem 1.2 to compute the fluctuations 
%  and 
% visualize the fluctuations in a single figure with two subplots with titles axis labels (and do whatever else you want to make the figure look nice)
% you may either add code to your existing m-file, or make a new one

% Plotting the fluctuating flow field
figure

% animation loop:
for n = 1:nt
    % Compute fluctuations at a given time instance
    u_prime = squeeze(u(n,:,:)) - u_mean;
    v_prime = squeeze(v(n,:,:)) - v_mean;
    
    % building subplot u'
    subplot(2,1,1)
    pcolor(x,y,u_prime)
    shading interp
    xlabel('x')
    ylabel('y')
    title('u''')
    axis equal tight
    colorbar
    caxis([-0.5 0.5])
    hold on
    rectangle('Position',[-0.5 -0.5 1 1], ...
          'Curvature',[1 1], ...
          'LineStyle','none', ...
          'FaceColor',[1 1 1]);
    hold off
    
    % building subplot v'
    subplot(2,1,2)
    pcolor(x,y,v_prime)
    shading interp
    xlabel('x')
    ylabel('y')
    title('v''')
    axis equal tight
    colorbar
    caxis([-0.5 0.5])
    hold on
    rectangle('Position',[-0.5 -0.5 1 1], ...
          'Curvature',[1 1], ...
          'LineStyle','none', ...
          'FaceColor',[1 1 1]);
    hold off
    
    % Annotate overall title with time
    sgtitle(['Velocity Fluctuations at t = ', num2str((n-1)*dt)])
    
    drawnow
end

%% Problem 1.5.
% Write a Matlab script that computes and plots the turbulence kinetic
% energy (TKE), discarding the first 150 time instances.

% Number of snapshots after transient
nt_fluc = size(u(151:end,:,:),1);

% Expand mean fields to match time dimension
u_mean_expanded = repmat(u_mean, [1 1 nt_fluc]);
v_mean_expanded = repmat(v_mean, [1 1 nt_fluc]);

% Permute to match u's dimension order
u_mean_expanded = permute(u_mean_expanded, [3 1 2]);
v_mean_expanded = permute(v_mean_expanded, [3 1 2]);

% Compute fluctuations
u_fluc = u(151:end,:,:) - u_mean_expanded;
v_fluc = v(151:end,:,:) - v_mean_expanded;

% Compute TKE
TKE = 0.5 * squeeze(mean(u_fluc.^2 + v_fluc.^2, 1));

% Plot TKE
figure
pcolor(x,y,TKE)
shading interp
xlabel('x')
ylabel('y')
title('Turbulence Kinetic Energy')
axis equal tight
colorbar
hold on
rectangle('Position',[-0.5 -0.5 1 1], ...
      'Curvature',[1 1], ...
      'LineStyle','none', ...
      'FaceColor',[1 1 1]);
hold off