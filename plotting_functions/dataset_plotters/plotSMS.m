function tableData = plotSMS(R,entry,ax)
set(ax, 'XLim',[0 inf]);
errorbar(ax, R.spotSize, R.spikeRateStim_baselineSubtraced_mean, R.spikeRateStim_baselineSubtraced_sem,...
    'Color',[0 1 1],...
    'LineWidth',2);
hold(ax,'on');
xlabel(ax, 'Spot size (microns)')
ylabel(ax, 'Spike count from baseline');
errorbar(ax, R.spotSize, R.spikeRatePost_baselineSubtraced_mean, R.spikeRatePost_baselineSubtraced_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
hold(ax,'off');

% hold(ax2,'on');
% xlabel(ax2, 'Spot size (microns)')
% ylabel(ax2, 'Spike count from baseline');
% hold(ax2,'off');

tableData.RstarMean = R.RstarMean;
tableData.Intensity = R.RstarIntensity1;
tableData.bestSize_ON = R.bestSize_ON;
tableData.SuppIndexON = R.SI_ON;
tableData.bestSize_OFF = R.bestSize_OFF;
tableData.SuppIndexOFF = R.SI_OFF;
