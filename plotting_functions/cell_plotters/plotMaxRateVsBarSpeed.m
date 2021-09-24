function tableData = plotMaxRateVsBarSpeed(R,entry,ax)
tableData = struct;
set(ax, 'XLim',[0 inf]);
errorbar(ax, R.barSpeed, R.maxFR_mean, R.maxFR_sem, ...
    'Color',[0 1 1], ...
    'LineWidth',2);
xlabel(ax, 'Spot size (microns)')
ylabel(ax, 'Max. spike rate from baseline');

