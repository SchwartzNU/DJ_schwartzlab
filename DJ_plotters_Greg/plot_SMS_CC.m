function plot_SMS_CC(R,ax)
set(ax, 'XLim',[0 inf]);
errorbar(ax, R.spot_sizes, R.peak_stim_mean, R.peak_stim_sem,...
    'Color',[0 1 1],...
    'LineWidth',2);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax,'on');
xlabel(ax, 'Spot size (microns)')
ylabel(ax, 'Peak response (mV)');
errorbar(ax, R.spot_sizes, R.peak_tail_mean, R.peak_tail_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
legend(ax,{'ON', 'OFF'});
hold(ax,'off');
