%Vascular Resistance
% BME 311: Project 1

%% First determine the brachial artery diameter 
%% Select Pulsed Doppler file
clear;close all
[file folder]=uigetfile('*');
fullFileName = fullfile(folder, file);
img=dicomread([folder file]);
%%
imagesc(img)

%% Determine the vessel diameter
imagesc(img);colormap gray
[xs ys]=getpts % select one cm of axis
pixel_per_cm=(ys(2)-ys(1)) %pixels per centimeter


%% Measure Diameter
[xs_length ys_length]=getpts;
diameter=(ys_length(1)-ys_length(2))/pixel_per_cm

%% Determine the Average "Maximum" Velocity across the Cardiac Cycle
%% Determine Velocity scaling
imagesc(img)
[xs ys]=getpts % select one cm of axis
pixel_per_cms=(ys(2)-ys(1))/100 %pixels per 100 cm/s

%% Select and average at least ten velocity values

[xs ys]=getpts; % select velocity tracing second of x axis

% determine average Maximum velocity across the cardiac cycle

%%

%% Assuming parabolic flow.  What is the vessels average velocity

%% Using part 1a and 1b what is the average flow during baseline.

