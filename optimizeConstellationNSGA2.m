function results = optimizeConstellationNSGA2(overrides)

problemConfig = struct( ...
    'startTime', datetime(2026, 4, 2, 0, 0, 0, 'TimeZone', 'UTC'), ...
    'durationHours', 24, ...
    'timeStepMinutes', 5, ...
    'walkerPhasing', 1, ...
    'geoLatDeg', 0, ...
    'geoLonDeg', 113, ...
    'elevationMaskDeg', 10, ...
    'gdopAvailabilityThreshold', 50, ...
    'includeGeoHostedPayload', true, ...
    'enablePlots', false, ...
    'writeLog', false, ...
    'verbose', false, ...
    'populationSize', 50, ...
    'maxGenerations', 30, ...
    'enableGaPlot', false, ...
    'enableParetoSummaryPlot', true);

if nargin >= 1 && isstruct(overrides)
    problemConfig = mergeConfig(problemConfig, overrides);
end

populationSize = problemConfig.populationSize;
maxGenerations = problemConfig.maxGenerations;
lb = [500, 0, 1, 6];
ub = [1200, 25, 12, 48];
intcon = [3, 4];

printProblemDefinition(lb, ub, problemConfig, populationSize, maxGenerations);

pool = gcp('nocreate');
if isempty(pool)
    pool = parpool('local', 4);
    fprintf('Started parallel pool with %d workers.\n', pool.NumWorkers);
else
    fprintf('Using existing parallel pool with %d workers.\n', pool.NumWorkers);
end

options = optimoptions('gamultiobj', ...
    'PopulationSize', populationSize, ...
    'MaxGenerations', maxGenerations, ...
    'FunctionTolerance', 1e-12, ...
    'Display', 'off', ...
    'UseVectorized', false, ...
    'UseParallel', true);

if problemConfig.enableGaPlot
    options = optimoptions(options, 'PlotFcn', {@gaplotpareto});
end

[x, fval, exitflag, output, population, scores] = gamultiobj( ...
    @(design) objectiveFunction(design, problemConfig), ...
    4, ...
    [], [], [], [], ...
    lb, ub, ...
    @(design) constraintFunction(design), ...
    intcon, ...
    options);

results = packageResults(x, fval, exitflag, output, population, scores, problemConfig);
writeParetoResults(results);
if problemConfig.enableParetoSummaryPlot
    plotParetoSummary(results);
end

fprintf('\nNSGA-II complete.\n');
fprintf('  Pareto solutions found = %d\n', size(results.designs, 1));
fprintf('  Population size        = %d\n', populationSize);
fprintf('  Max generations        = %d\n', maxGenerations);
fprintf('  Results table          = nsga2_pareto_results.xlsx\n');
fprintf('  Results data           = nsga2_pareto_results.mat\n');

end

function objectives = objectiveFunction(design, baseConfig)

config = decodeDesign(design, baseConfig);

if mod(config.numSatellites, config.numPlanes) ~= 0
    objectives = penaltyObjectives();
    return;
end

try
    metrics = evaluateConstellationDesign(config);
    objectives = [ ...
        metrics.globalMeanGDOP, ...
        metrics.globalGDOPDeviation, ...
        metrics.cost, ...
        -metrics.globalMeanAvailability];

    if any(~isfinite(objectives))
        objectives = penaltyObjectives();
    end
catch err
    warning('NSGA-II evaluation failed for [%g %g %g %g]: %s', ...
        design(1), design(2), design(3), design(4), err.message);
    objectives = penaltyObjectives();
end

end

function [c, ceq] = constraintFunction(design)

planeCount = round(design(3));
satelliteCount = round(design(4));

c = [ ...
    planeCount - satelliteCount; ...
    double(mod(satelliteCount, planeCount) ~= 0) - 0.5];
ceq = [];

end

function objectives = penaltyObjectives()

objectives = [1e6, 1e6, 1e12, 1];

end

function config = decodeDesign(design, baseConfig)

config = baseConfig;
config.altitudeKm = design(1);
config.inclinationDeg = design(2);
config.numPlanes = round(design(3));
config.numSatellites = round(design(4));

end

function results = packageResults(x, fval, exitflag, output, population, scores, baseConfig)

nSolutions = size(x, 1);

designs = table( ...
    x(:, 1), ...
    x(:, 2), ...
    round(x(:, 3)), ...
    round(x(:, 4)), ...
    fval(:, 1), ...
    fval(:, 2), ...
    fval(:, 3), ...
    -fval(:, 4), ...
    'VariableNames', { ...
        'Altitude_km', ...
        'Inclination_deg', ...
        'Planes', ...
        'Satellites', ...
        'MeanGDOP', ...
        'GDOPDeviation', ...
        'Cost_USD', ...
        'Availability'});

for idx = 1:nSolutions
    designs.SatsPerPlane(idx) = designs.Satellites(idx) / designs.Planes(idx);
end

results = struct( ...
    'designs', designs, ...
    'rawX', x, ...
    'rawFval', fval, ...
    'exitflag', exitflag, ...
    'output', output, ...
    'population', population, ...
    'scores', scores, ...
    'baseConfig', baseConfig);

end

function writeParetoResults(results)

writetable(results.designs, 'nsga2_pareto_results.xlsx', 'Sheet', 'ParetoFront');
save('nsga2_pareto_results.mat', 'results');

end

function plotParetoSummary(results)

if isempty(results.designs)
    return;
end

figure('Name', 'NSGA-II Pareto Summary', 'NumberTitle', 'off');
scatter3( ...
    results.designs.Cost_USD, ...
    results.designs.MeanGDOP, ...
    results.designs.Availability, ...
    70, ...
    results.designs.GDOPDeviation, ...
    'filled');
grid on;
xlabel('Cost (USD)');
ylabel('Mean GDOP');
zlabel('Availability');
title('NSGA-II Pareto Front Summary');
cb = colorbar;
cb.Label.String = 'GDOP Deviation';

end

function printProblemDefinition(lb, ub, config, populationSize, maxGenerations)

fprintf('NSGA-II optimization problem\n');
fprintf('Variation parameters\n');
fprintf('  Altitude (h)             : %.0f to %.0f km\n', lb(1), ub(1));
fprintf('  Inclination (i)          : %.0f to %.0f deg\n', lb(2), ub(2));
fprintf('  Number of planes         : %d to %d\n', round(lb(3)), round(ub(3)));
fprintf('  Number of satellites (n) : %d to %d\n', round(lb(4)), round(ub(4)));

fprintf('Objectives\n');
fprintf('  1. Minimize mean GDOP\n');
fprintf('  2. Minimize GDOP deviation\n');
fprintf('  3. Minimize cost\n');
fprintf('  4. Maximize availability\n');

fprintf('NSGA-II settings\n');
fprintf('  Population size = %d\n', populationSize);
fprintf('  Generations     = %d\n', maxGenerations);
fprintf('  Time step       = %d min per evaluation\n', config.timeStepMinutes);
fprintf('  Duration        = %d hr per evaluation\n\n', config.durationHours);

end
