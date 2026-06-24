# Cardiovascular Caffeine Model — BME 311

A collection of MATLAB scripts for analyzing cardiovascular physiology from clinical imaging and physiological signal data. Built around a lab series measuring the effect of caffeine on hemodynamic parameters.

Built for BME 311 at UT Austin.

## Scripts

**windkesselModel.m** — Simulates arterial blood pressure dynamics using a two-element Windkessel model. Compares baseline vs. caffeine conditions by modeling changes in heart rate, peripheral resistance, and arterial compliance. Outputs systolic, diastolic, and pulse pressure for both cases.

**arteryDiameter.m** — Loads an ultrasound image and lets you click to calibrate scale (1 cm reference) and measure vessel diameter. Outputs diameter in both pixels and cm.

**carotidCompliance.m** — Loads a carotid ultrasound video and walks you through selecting end-diastolic and peak-systolic frames, tracing the lumen with `roipoly`, and computing percent area change and arterial compliance from blood pressure inputs.

**vascularResistance.m** — Loads a pulsed Doppler DICOM image of the brachial artery, calibrates pixel scale, measures vessel diameter, and estimates average flow velocity across the cardiac cycle for vascular resistance calculations.

## How to run

Each script is standalone — open and run individually in MATLAB. Scripts that require image or video input will prompt you to select a file. Follow the on-screen instructions for clicking calibration points and tracing regions of interest.

## Dependencies

MATLAB with Image Processing Toolbox
