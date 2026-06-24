function [conc_fraction] = ritgerPeppasEquation(release_expo, kinetic_constant, t)
for i = 1:length(t)
    conc_fraction(i) = kinetic_constant * (t(i)^release_expo);
end
end
