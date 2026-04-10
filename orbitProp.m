function r_ECEF = orbitProp(h, i, RAAN, nSat, tspan, f)

% constant
Re = 6378e3;
mu = 3.986e14;

Nt = length(tspan);
nPlane = numel(RAAN);

if mod(nSat, nPlane) ~= 0
    error('Walker phasing requires nSat to be divisible by the number of planes.');
end

if isscalar(h)
    hPlane = repmat(h, 1, nPlane);
elseif numel(h) == nPlane
    hPlane = reshape(h, 1, []);
else
    error('Altitude input h must be a scalar or have one value per plane.');
end

if isscalar(i)
    iPlane = repmat(i, 1, nPlane);
elseif numel(i) == nPlane
    iPlane = reshape(i, 1, []);
else
    error('Inclination input i must be a scalar or have one value per plane.');
end

satsPerPlane = nSat / nPlane;
r_ECEF = zeros(3, Nt, nSat);

% loop for each orbital planet
satIdx = 1;
for p = 1:nPlane
    nThisPlane = satsPerPlane;
    rPlane = Re + hPlane(p);
    nPlaneMeanMotion = sqrt(mu / rPlane^3);
    
    % loop for each satellite inside the plane
    for s = 1:nThisPlane
        % Walker phasing from M_ij = 2*pi/S*(j-1) + 2*pi/N*F*(i-1)
        nu0 = 2*pi*(s-1)/nThisPlane + 2*pi*f*(p-1)/nSat;
        omega = 0;
        
        % loop for each timestep
        for k = 1:Nt
            t_sec = seconds(tspan(k) - tspan(1));

            % true anomaly
            nu = nu0 + nPlaneMeanMotion*t_sec;

            % PQW
            r_pqw = [rPlane*cos(nu);
                     rPlane*sin(nu);
                     0];

            % PQW -> ECI
            r_eci = rotz(RAAN(p)) * rotx(iPlane(p)) * rotz(omega) * r_pqw;

            % ECI -> ECEF
            r_ecef = eci2ecef(tspan(k), r_eci');

            r_ECEF(:,k,satIdx) = r_ecef';
        end

        satIdx = satIdx + 1;
    end
end

end


% rotation matrix
% R1
function R = rotx(a)
R = [1 0 0;
     0 cos(a) -sin(a);
     0 sin(a)  cos(a)];
end

% R3
function R = rotz(a)
R = [cos(a) -sin(a) 0;
     sin(a)  cos(a) 0;
     0       0      1];
end
