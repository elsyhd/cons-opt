function Ctot = satCost(r_sat, ~, ~)

% total number of satellites
nSat = size(r_sat, 3);
nHostedGeo = 1;
mLeo = 50;


% number of LEO satellites
nLeo = max(nSat - nHostedGeo, 0);

% launch cost per LEO satellite based on spaceX
if mLeo <= 50
    C_launch = 350000;
else
    C_launch = 350000 + 7000 * (mLeo - 50);
end

% satellite cost
C_sat = 500000;
C_hostedGeo = 15000000;

% total cost per LEO satellite
C_LEO = C_sat + C_launch;

% total constellation cost
Ctot = nLeo * C_LEO + nHostedGeo * C_hostedGeo;

end
