# Diffusion Model of Controlled Drug Release

A MATLAB simulation of solute diffusion from alginate beads into surrounding water, based on Fick's first law. Also includes an implementation of the Ritger-Peppas equation for modeling non-Fickian drug release kinetics.

Built for BME 303L at UT Austin.

## What it models

Simulates how a dye or drug diffuses out of spherical alginate beads into a water phase over 90 minutes. At each timestep, the model calculates the concentration gradient between the bead interior and surrounding water, computes diffusive flux, and updates the mole counts in each compartment accordingly.

The Ritger-Peppas equation is included separately to characterize the release mechanism — the exponent `n` distinguishes Fickian diffusion from anomalous or case-II transport.

## Files

- `diffusionModel.m` — core diffusion simulation using Fick's first law
- `callRitger.m` — example call to the Ritger-Peppas equation
- `ritgerPeppasEquation.m` — computes cumulative release fraction Mt/M∞ = kt^n
- `functionCall.m` — runs the diffusion model with 14-gauge bead parameters and plots concentration vs. time

## How to run

Open `functionCall.m` in MATLAB and run it. Adjust bead radius, count, initial concentration, or diffusion coefficient at the top of the file to explore different conditions.

Default parameters:
- Bead radius: 0.1 cm
- Number of beads: 100
- Initial dye concentration: 0.39 mM
- Diffusion coefficient: 9.5 × 10⁻⁶ cm²/s

## Dependencies

MATLAB (no additional toolboxes required)
