%Run diffusion model for 14 gauge beads
C0_BEADS = 0.39;        % mM 
R_BEADS = 0.1;          % cm
N_BEADS = 100;
D = 9.5E-6;             % cm^2/sec
% call function
[t,c]=diffusionModel(R_BEADS, N_BEADS, C0_BEADS, D);
% plot graph
plot(t, c);
xlabel('Time (min)');
ylabel('Conc (mM)');
title('Diffusion Model');
