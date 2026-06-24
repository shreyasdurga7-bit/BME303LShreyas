% Diffusion Model of Controlled Release Experiment
% Ported from Excel Diffusion Model
%
% This function simulates the diffusion of a solute (e.g., dye or drug)
% from alginate beads into surrounding water over time using a simplified
% version of Fick's first law of diffusion. The model assumes spherical
% beads of uniform radius and constant diffusion coefficient.

function [time_min, conc_in_water] = diffusionModel(r_beads, n_beads, c0_beads, diff_coeff)
    % INPUTS:
    %   r_beads   - radius of each bead (cm)
    %   n_beads   - number of beads
    %   c0_beads  - initial concentration of dye in beads (mM)
    %   diff_coeff - diffusion coefficient of dye (cm^2/s)
    %
    % OUTPUTS:
    %   time_min        - time vector (minutes)
    %   conc_in_water   - concentration of dye in water phase (mM)
    %
    % The model uses a discrete time-step approach to estimate dye transfer
    % between the beads and the water via diffusive flux based on Fick's law.

    % Define constants and initial parameters
    DT = 60.0;              % Time step (sec)
    C0_BEADS = 0.39;        % Default initial dye concentration in beads (mM)
    R_BEADS = 0.1;          % Default bead radius (cm)
    N_BEADS = 100;          % Default number of beads
    C0_WATER = 0;           % Initial concentration of dye in water (mM)
    VOL_WATER = 8;          % Volume of water (mL)
    D = 9.5E-6;             % Default diffusion coefficient (cm^2/s)
    MM2MOL = 1000000;       % Conversion factor from mM to mol/mL

    START_TIME = 0.0;       % Start time (s)
    END_TIME = 90.0 * 60;   % End time (s), representing 90 minutes
    DT = 1.0;               % Time step resolution (s)
    
    % Calculate geometry of all beads
    vol_beads = (4/3) * pi * (r_beads^3) * n_beads;    % Total bead volume (cm^3 ≈ mL)
    sa_beads = (4) * pi * (r_beads^2) * n_beads;       % Total bead surface area (cm^2)

    % Define time vector in seconds and convert to minutes
    time_sec = START_TIME:DT:END_TIME;
    time_min = time_sec / 60.0;

    % Initialize concentrations and moles in both phases
    conc_in_beads = c0_beads;                                % Initial solute concentration in beads (mM)
    conc_in_beads_mol_per_ml = conc_in_beads / MM2MOL;       % Convert to mol/mL
    moles_of_dye_in_beads = conc_in_beads_mol_per_ml * vol_beads;  % Total moles in beads

    conc_in_water = C0_WATER;                                % Initial solute concentration in water (mM)
    conc_in_water_mol_per_ml = conc_in_water / MM2MOL;       % Convert to mol/mL
    moles_of_dye_in_water = conc_in_water_mol_per_ml * VOL_WATER;  % Total moles in water

    % Compute initial diffusive flux at t = 0 using Fick's first law
    % J = -D * (dC/dx)
    dcdx = (conc_in_water_mol_per_ml - conc_in_beads_mol_per_ml) / r_beads;
    flux = -diff_coeff * dcdx;                     % Diffusive flux (mol/cm^2/s)
    moles_diffused = flux * DT * sa_beads;         % Moles diffused during first time step

    % Iteratively simulate diffusion process over time
    for i = 2:length(time_min)
        % Update dye amounts in each compartment
        moles_of_dye_in_water(i) = moles_of_dye_in_water(i-1) + moles_diffused(i-1);
        moles_of_dye_in_beads(i) = moles_of_dye_in_beads(i-1) - moles_diffused(i-1);
        
        % Update concentrations based on new amounts
        conc_in_beads_mol_per_ml(i) = moles_of_dye_in_beads(i) / vol_beads;
        conc_in_beads(i) = conc_in_beads_mol_per_ml(i) * MM2MOL;
        conc_in_water_mol_per_ml(i) = moles_of_dye_in_water(i) / VOL_WATER;
        conc_in_water(i) = conc_in_water_mol_per_ml(i) * MM2MOL;

        % Recalculate concentration gradient and diffusive flux
        dcdx(i) = (conc_in_water_mol_per_ml(i) - conc_in_beads_mol_per_ml(i)) / r_beads;
        flux(i) = -diff_coeff * dcdx(i);
        moles_diffused(i) = flux(i) * DT * sa_beads;
    end
end
