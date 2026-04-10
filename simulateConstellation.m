function varargout = simulateConstellation(varargin)

% Default command-line behavior now runs the NSGA-II study.
if nargin == 0 && nargout == 0
    optimizeConstellationNSGA2();
    return;
end

if nargin >= 1 && isstruct(varargin{1})
    config = mergeConfig(defaultConstellationConfig(), varargin{1});
else
    config = defaultConstellationConfig();
end

metrics = evaluateConstellationDesign(config);

if config.writeLog
    writeGDOPLog(metrics);
end

printConstellationSummary(metrics);

if config.enablePlots
    plotTargetMetrics( ...
        metrics.tspan, ...
        metrics.visibleCountAll, ...
        metrics.gdopAllVisible, ...
        metrics.siteNames, ...
        metrics.gdopAvailabilityThreshold);
end

if nargout >= 1
    varargout{1} = metrics.availabilityByTarget;
end
if nargout >= 2
    varargout{2} = metrics.cost;
end
if nargout >= 3
    varargout{3} = metrics.rAll;
end
if nargout >= 4
    varargout{4} = metrics;
end

end

function writeGDOPLog(metrics)

logFile = 'gdop_all_visible_log.txt';
fid = fopen(logFile, 'w');
if fid == -1
    error('Could not open GDOP log file: %s', logFile);
end

cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'GDOP all-visible summary by timestep\n');
fprintf(fid, 'Availability criterion: visible >= 4 and GDOP <= %.2f\n', metrics.gdopAvailabilityThreshold);
fprintf(fid, 'Elevation mask: %.2f deg\n', metrics.elevationMaskDeg);
fprintf(fid, 'Generated at %s\n\n', string(datetime('now', 'TimeZone', 'UTC')));

for idx = 1:numel(metrics.siteNames)
    fprintf(fid, '%s\n', metrics.siteNames{idx});
    for sample = 1:size(metrics.visibleCountAll, 1)
        if isnan(metrics.gdopAllVisible(sample, idx))
            fprintf(fid, '  t = %s | visible = %d | GDOP all visible = NaN | available = 0\n', ...
                string(metrics.tspan(sample)), round(metrics.visibleCountAll(sample, idx)));
        else
            fprintf(fid, '  t = %s | visible = %d | GDOP all visible = %.4f | available = %d\n', ...
                string(metrics.tspan(sample)), ...
                round(metrics.visibleCountAll(sample, idx)), ...
                metrics.gdopAllVisible(sample, idx), ...
                metrics.availabilityMask(sample, idx));
        end
    end
    fprintf(fid, '\n');
end

clear cleanupObj;
fprintf('GDOP log saved to %s\n', logFile);

end

function printConstellationSummary(metrics)

config = metrics.config;

fprintf('\nConstellation design summary\n');
fprintf('  Altitude          = %.0f km\n', config.altitudeKm);
fprintf('  Inclination       = %.2f deg\n', config.inclinationDeg);
fprintf('  Number of planes  = %d\n', round(config.numPlanes));
fprintf('  Number of sats    = %d\n', round(config.numSatellites));
fprintf('  Elevation mask    = %.2f deg\n', config.elevationMaskDeg);
fprintf('  GDOP max avail    = %.2f\n\n', config.gdopAvailabilityThreshold);

for idx = 1:numel(metrics.siteNames)
    fprintf('%s Availability           = %.3f\n', metrics.siteNames{idx}, metrics.availabilityByTarget(idx));
    fprintf('%s Mean Visible           = %.2f\n', metrics.siteNames{idx}, metrics.meanVisibleAll(idx));
    fprintf('%s Std Visible            = %.2f\n', metrics.siteNames{idx}, metrics.stdVisibleAll(idx));
    fprintf('%s Max Visible            = %d\n', metrics.siteNames{idx}, metrics.maxVisiblePerTarget(idx));
    fprintf('%s Mean GDOP (All Visible) = %.2f\n', metrics.siteNames{idx}, metrics.meanGDOPAllVisible(idx));
    fprintf('%s Std GDOP (All Visible)  = %.2f\n', metrics.siteNames{idx}, metrics.stdGDOPAllVisible(idx));
end

fprintf('Global Mean Availability        = %.3f\n', metrics.globalMeanAvailability);
fprintf('Global Mean Visible             = %.2f\n', metrics.globalMeanVisible);
fprintf('Global Mean GDOP (All Visible)  = %.2f\n', metrics.globalMeanGDOP);
fprintf('Global Mean GDOP Deviation      = %.2f\n', metrics.globalGDOPDeviation);
fprintf('Availability criterion          = visible >= 4 and GDOP <= %.2f\n', metrics.gdopAvailabilityThreshold);
fprintf('Total Cost                      = USD %.2f\n', metrics.cost);

end
