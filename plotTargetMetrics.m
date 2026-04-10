function plotTargetMetrics(tspan, visibleCountAll, gdopAllVisible, siteNames, gdopMaxForPlot)

if nargin < 5
    gdopMaxForPlot = inf;
end

tHours = hours(tspan - tspan(1));
nUser = size(gdopAllVisible, 2);
gdopPlotData = gdopAllVisible;
gdopPlotData(gdopPlotData > gdopMaxForPlot) = NaN;

if nUser > 20
    figure('Name', 'Visible Satellites Heatmap', 'NumberTitle', 'off');
    imagesc(tHours, 1:nUser, visibleCountAll.');
    axis xy;
    colorbar;
    xlabel('Time (hr)');
    ylabel('Target Index');
    title('Visible Satellites per Grid Target');

    figure('Name', 'GDOP All Visible Heatmap', 'NumberTitle', 'off');
    imagesc(tHours, 1:nUser, gdopPlotData.');
    axis xy;
    colorbar;
    clim([0 gdopMaxForPlot]);
    xlabel('Time (hr)');
    ylabel('Target Index');
    title(sprintf('GDOP All Visible per Grid Target (<= %.0f)', gdopMaxForPlot));
    return;
end

figure('Name', 'Visible Satellites by Site', 'NumberTitle', 'off');
for u = 1:nUser
    subplot(nUser, 1, u);
    plot(tHours, visibleCountAll(:, u), 'LineWidth', 1.5);
    grid on;
    xlim([0, 24]);
    ylabel('Visible Sats');
    title(['Visible Satellites vs Time - ' siteNames{u}]);
    if u == nUser
        xlabel('Time (hr)');
    end
end

figure('Name', 'GDOP All Visible', 'NumberTitle', 'off');

for u = 1:nUser
    subplot(nUser, 1, u);
    plot(tHours, gdopPlotData(:, u), 'LineWidth', 1.5);
    grid on;
    xlim([0, 24]);
    ylim([0 gdopMaxForPlot]);
    ylabel('GDOP');
    title(sprintf('GDOP All Visible - %s (<= %.0f)', siteNames{u}, gdopMaxForPlot));
    if u == nUser
        xlabel('Time (hr)');
    end
end

end
