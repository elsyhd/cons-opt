function [A, visibleSat, visibleCountAll, meanVisibleAll, maxVisiblePerTarget] = satAvailability(r_sat, users, elevationMaskDeg)

% constant
Re = 6378e3;

if nargin < 3
    elevationMaskDeg = 10;
end

Nt = size(r_sat, 2);
nSat = size(r_sat, 3);
nUser = size(users, 1);

visibleSat = zeros(Nt, nSat, nUser);
visibleCountAll = zeros(Nt, nUser);
A = zeros(nUser, 1);
meanVisibleAll = zeros(nUser, 1);
maxVisiblePerTarget = zeros(nUser, 1);

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

    delta = zeros(Nt, 1);
    visibleCount = zeros(Nt, 1);
    
    % loop for each timestep
    for k = 1:Nt
        count = 0;
        
        % loop for each satellite
        for s = 1:nSat
            rs = r_sat(:, k, s);
            rho = rs - ru;
            
            % ECEF -> ENU
            R = [-sin(lon)           cos(lon)            0;
                 -sin(lat)*cos(lon) -sin(lat)*sin(lon)  cos(lat);
                  cos(lat)*cos(lon)  cos(lat)*sin(lon)  sin(lat)];

            enu = R * rho;

            E = enu(1);
            N = enu(2);
            U = enu(3);
            
            % calculate elevation angle
            elev = atan2(U, sqrt(E^2 + N^2));

            % check whether elevation is above the configured mask
            if elev >= deg2rad(elevationMaskDeg)
                visibleSat(k, s, u) = 1;
                count = count + 1;
            end
        end
        
        visibleCount(k) = count;

        % check if minimum 4 satellite visible
        if count >= 4
            delta(k) = 1;
        end
    end

    A(u) = mean(delta);
    visibleCountAll(:, u) = visibleCount;
    meanVisibleAll(u) = mean(visibleCount);
    maxVisiblePerTarget(u) = max(visibleCount);
end

end
