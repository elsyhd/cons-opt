function [gdopAllVisible, meanGDOPAllVisible] = satGDOP(r_sat, users, visibleSat)

% constant
Re = 6378e3;

Nt = size(r_sat, 2);
nUser = size(users, 1);

gdopAllVisible = nan(Nt, nUser);
meanGDOPAllVisible = nan(nUser, 1);

% loop for each user/ target point
for u = 1:nUser
    lat = users(u, 1);
    lon = users(u, 2);
    h = users(u, 3);

    % Geo -> ECEF
    xu = (Re + h)*cos(lat)*cos(lon);
    yu = (Re + h)*cos(lat)*sin(lon);
    zu = (Re + h)*sin(lat);
    ru = [xu; yu; zu];

    % loop for each timestep
    for k = 1:Nt
        visIdx = find(squeeze(visibleSat(k, :, u)) == 1);

        if numel(visIdx) < 4
            continue;
        end

        gdopAllVisible(k, u) = computeGDOPForVisibleSatellites(r_sat, ru, k, visIdx);
    end

    validAll = ~isnan(gdopAllVisible(:, u));
    if any(validAll)
        meanGDOPAllVisible(u) = mean(gdopAllVisible(validAll, u));
    end
end

end

function gdopValue = computeGDOPForVisibleSatellites(r_sat, ru, k, satIdx)

H = zeros(numel(satIdx), 4);

for j = 1:numel(satIdx)
    s = satIdx(j);
    rhoVec = r_sat(:, k, s) - ru;
    rho = norm(rhoVec);

    if rho < 1e-12
        gdopValue = NaN;
        return;
    end

    los = rhoVec / rho;
    H(j, :) = [los.', 1];
end

normalMatrix = H.' * H;
if rcond(normalMatrix) < 1e-12
    gdopValue = NaN;
    return;
end

Q = inv(normalMatrix);
gdopValue = sqrt(trace(Q));
end
