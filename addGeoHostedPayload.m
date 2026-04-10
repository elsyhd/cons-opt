function r_all = addGeoHostedPayload(r_sat, tspan, latGeo, lonGeo)

% constant
Re = 6378e3;
hGeo = 35786e3;
rGeo = Re + hGeo;

Nt = length(tspan);
nSat = size(r_sat, 3);
r_all = zeros(3, Nt, nSat + 1);

r_all(:,:,1:nSat) = r_sat;

% GEO is stationary in ECEF
r_geo = [rGeo*cos(latGeo)*cos(lonGeo);
         rGeo*cos(latGeo)*sin(lonGeo);
         rGeo*sin(latGeo)];

    for k = 1:Nt
        r_all(:,k,nSat + 1) = r_geo;
    end
end
