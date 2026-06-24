% Artery Diameter Measurement from Image
% This script:
% 1. Prompts you to open an image
% 2. Lets you click two points that are 1 cm apart to calibrate scale
% 3. Lets you click two points across the artery diameter
% 4. Computes the artery diameter in pixels and cm

clear; clc; close all;

% Prompt user to select image
[file, path] = uigetfile({'*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.bmp', ...
    'Image Files (*.jpg, *.jpeg, *.png, *.tif, *.tiff, *.bmp)'}, ...
    'Select an image');

if isequal(file,0)
    disp('No image selected. Script terminated.');
    return;
end

img = imread(fullfile(path, file));

% Display image
figure;
imshow(img);
title('Select TWO points that are exactly 1 cm apart');
hold on;

% Select two calibration points
[x_cal, y_cal] = ginput(2);

% Plot calibration points and line
plot(x_cal, y_cal, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
plot(x_cal, y_cal, 'r-', 'LineWidth', 2);

% Compute pixel distance for 1 cm
pixel_dist_1cm = sqrt((x_cal(2)-x_cal(1))^2 + (y_cal(2)-y_cal(1))^2);

% Scale factors
cm_per_pixel = 1 / pixel_dist_1cm;
pixel_per_cm = pixel_dist_1cm / 1;

% Prompt for artery diameter points
title('Select TWO points across the artery diameter');
[x_art, y_art] = ginput(2);

% Plot artery points and line
plot(x_art, y_art, 'go', 'MarkerSize', 10, 'LineWidth', 2);
plot(x_art, y_art, 'g-', 'LineWidth', 2);

% Compute artery diameter in pixels
artery_diameter_pixels = sqrt((x_art(2)-x_art(1))^2 + (y_art(2)-y_art(1))^2);

% Convert to cm
artery_diameter_cm = artery_diameter_pixels * cm_per_pixel;

% Display results
fprintf('Calibration distance: %.2f pixels = 1.00 cm\n', pixel_dist_1cm);
fprintf('Scale: %.4f cm/pixel\n', cm_per_pixel);
fprintf('Artery diameter: %.2f pixels\n', artery_diameter_pixels);
fprintf('Artery diameter: %.4f cm\n', artery_diameter_cm);

% Add text to image
mid_x = mean(x_art);
mid_y = mean(y_art);
text(mid_x, mid_y, sprintf('%.4f cm', artery_diameter_cm), ...
    'Color', 'y', 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

title('Measurement complete');
hold off;