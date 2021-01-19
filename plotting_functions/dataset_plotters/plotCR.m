function tableData = plotCR(R,entry,ax)
tableData = [];
errorbar(ax, R.contrast, R.spikeRateStim_baselineSubtraced_mean, R.spikeRateStim_baselineSubtraced_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
hold(ax,'on');
xlabel(ax, 'Contrast')
ylabel(ax, 'Spike count from baseline');
hold(ax,'off');
