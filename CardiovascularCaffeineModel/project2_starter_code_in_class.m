%{
% Pulse Wave Velocity and Venous Distension
% BME 311 
% Starter Code CCreated by Adam Bush

%% Determine Your Carotid Femoral Pulse Wave Velocity 
%% Select and Load Data Textfile
    
clear;clc
[fileName, pathName] = uigetfile('*.txt');
data = readmatrix(fullfile(pathName,fileName)); 
%data = readtable(fullfile(pathName,fileName)); 

%DELETE FIRST ROW 
data(1,:) = [];
%%
%data=table2array(data);
%%
time = data(:,1);
ecg = data(:,2);
mic = data(:,3);
pleth = data(:,4);
pressure = data(:,5);

%% Plot Single Variables
plot(time,pleth)

%% Select S1 Peak, Pressure Foot and ECG R Wave
subplot(3,1,1)
plot(time, ecg)
title('ECG')
xlim([581 584])

subplot(3,1,2)
plot(time, mic)
title('Microphone')
xlim([581 584])

subplot(3,1,3)
plot(time, pressure)
title('Femoral Pressure')
xlim([581 584])

[xs ys]=getpts;

%% Find Delta Time between S1 and Pressure Foot
dt1 = xs(2) - xs(1);
fprintf('Delta t = %.4f s\n', dt1);
%}

%Determine Carotid Compliance (Distensbility):Play video and Find Frame
% Carotid Compliance Analysis
% BME 311 Project 2

clear; clc; close all

%% Load carotid video
[fileName, pathName] = uigetfile('*.mp4', 'Select carotid.mp4');
if isequal(fileName,0)
    error('No video selected.')
end

fullFileName = fullfile(pathName, fileName);
videoObject = VideoReader(fullFileName);

% Total number of frames
numFrames = floor(videoObject.Duration * videoObject.FrameRate);
fprintf('Total number of frames: %d\n', numFrames);

%% Play video so user can choose frames
implay(fullFileName)

disp('After viewing the video, enter your chosen frame numbers below.')

%% Enter chosen frames
diaFrameNum = input('Enter END-DIASTOLIC frame number: ');
sysFrameNum = input('Enter PEAK-SYSTOLIC frame number: ');

%% Read chosen frames
diaFrame = read(videoObject, diaFrameNum);
sysFrame = read(videoObject, sysFrameNum);

%% Show chosen frames for screenshots
figure
imshow(diaFrame)
title(['Diastolic Frame: ', num2str(diaFrameNum)])

figure
imshow(sysFrame)
title(['Systolic Frame: ', num2str(sysFrameNum)])

%% Use roipoly to trace lumen in diastolic frame
figure
imshow(diaFrame)
title(['Trace lumen for DIASTOLIC frame ', num2str(diaFrameNum)])
disp('Trace the INSIDE of the carotid lumen, then double click to finish.')
diaMask = roipoly;
diaPixels = sum(diaMask(:));
fprintf('Diastolic pixel count = %d pixels\n', diaPixels);

%% Use roipoly to trace lumen in systolic frame
figure
imshow(sysFrame)
title(['Trace lumen for SYSTOLIC frame ', num2str(sysFrameNum)])
disp('Trace the INSIDE of the carotid lumen, then double click to finish.')
sysMask = roipoly;
sysPixels = sum(sysMask(:));
fprintf('Systolic pixel count = %d pixels\n', sysPixels);

%% Select 2 points on the legend that are exactly 1 cm apart
figure
imshow(diaFrame)
title('Click TWO points on the legend that are exactly 1 cm apart')
disp('Click the two endpoints of the 1 cm scale bar.')

[xs, ys] = getpts;

if length(xs) < 2
    error('You must click exactly two points for the 1 cm scale bar.')
end

% Use first two selected points
x1 = xs(1);
y1 = ys(1);
x2 = xs(2);
y2 = ys(2);

% Distance in pixels
pixel_dist = sqrt((x2 - x1)^2 + (y2 - y1)^2);
fprintf('1 cm corresponds to %.4f pixels\n', pixel_dist);

%% Conversion factors
cm_per_pixel = 1 / pixel_dist;
cm2_per_pixel = cm_per_pixel^2;

fprintf('Conversion = %.8f cm^2/pixel\n', cm2_per_pixel);

%% Convert pixel counts to area
diaArea_cm2 = diaPixels * cm2_per_pixel;
sysArea_cm2 = sysPixels * cm2_per_pixel;

fprintf('Diastolic area = %.6f cm^2\n', diaArea_cm2);
fprintf('Systolic area = %.6f cm^2\n', sysArea_cm2);

%% Percent change in carotid area
percentChange = ((sysArea_cm2 - diaArea_cm2) / diaArea_cm2) * 100;
fprintf('Percent change in carotid area = %.4f %%\n', percentChange);

%% Blood pressures
avgSysPressure = 114;   % mmHg
avgDiaPressure = 51;    % mmHg
pulsePressure = avgSysPressure - avgDiaPressure;

fprintf('Average systolic pressure = %.2f mmHg\n', avgSysPressure);
fprintf('Average diastolic pressure = %.2f mmHg\n', avgDiaPressure);
fprintf('Pulse pressure = %.2f mmHg\n', pulsePressure);

%% Arterial compliance
compliance = percentChange / pulsePressure;
fprintf('Arterial compliance = %.6f %% per mmHg\n', compliance);

%% Summary output
fprintf('\n----- FINAL RESULTS -----\n');
fprintf('End-Diastolic Frame: %d\n', diaFrameNum);
fprintf('Peak-Systolic Frame: %d\n', sysFrameNum);
fprintf('Diastolic Pixels: %d\n', diaPixels);
fprintf('Systolic Pixels: %d\n', sysPixels);
fprintf('Conversion: %.8f cm^2/pixel\n', cm2_per_pixel);
fprintf('Diastolic Area: %.6f cm^2\n', diaArea_cm2);
fprintf('Systolic Area: %.6f cm^2\n', sysArea_cm2);
fprintf('Percent Area Change: %.4f %%\n', percentChange);
fprintf('Average Systolic Pressure: %.2f mmHg\n', avgSysPressure);
fprintf('Average Diastolic Pressure: %.2f mmHg\n', avgDiaPressure);
fprintf('Pulse Pressure: %.2f mmHg\n', pulsePressure);
fprintf('Arterial Compliance: %.6f %% per mmHg\n', compliance);