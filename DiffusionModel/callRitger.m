t = [1 2 3 4 5];
release_expo = 0.5;        % n
kinetic_constant = 0.1;    % k
conc_fraction = ritgerPeppasEquation(release_expo, kinetic_constant, t)
