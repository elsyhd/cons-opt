function [users, siteNames, gridInfo] = generateIndonesiaGridTargets()

% use 5x5 degree cell
% each target lies at the midpoint of each ell
latMidDeg = 3.5:-5:-11.5;
lonMidDeg = 97.5:5:137.5;

[lonGridDeg, latGridDeg] = meshgrid(lonMidDeg, latMidDeg);
nTarget = numel(latGridDeg);

users = [deg2rad(latGridDeg(:)), deg2rad(lonGridDeg(:)), zeros(nTarget, 1)];
siteNames = arrayfun(@(idx) sprintf('Grid %03d', idx), 1:nTarget, 'UniformOutput', false);

gridInfo = struct( ...
    'latMidDeg', latMidDeg, ...
    'lonMidDeg', lonMidDeg, ...
    'latEdgeNorthDeg', 6, ...
    'latEdgeSouthDeg', -12, ...
    'lonEdgeWestDeg', 95, ...
    'lonEdgeEastDeg', 142.5);

end
