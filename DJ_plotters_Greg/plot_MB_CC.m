function plot_MB_CC(R,ax)
%set(ax, 'XLimM',[0 inf]);
hold(ax,'on');
errorbar(ax, R.bar_angles, R.peak_leading_mean, R.peak_leading_sem,...
    'Color',[0 1 1],...
    'LineWidth',2);
errorbar(ax, R.bar_angles, R.peak_trailing_mean, R.peak_trailing_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
errorbar(ax, R.bar_angles, R.peak_full_mean, R.peak_full_sem,...
    'Color',[.5 .5 .5],...
    'LineWidth',1);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax,'on');
xlabel(ax, 'Bar angle (degrees)')
ylabel(ax, 'Peak response (mV)');
title(ax,sprintf('DSI: leading = %0.2f, trailing = %0.2f, full = %0.2f', R.dsi_leading_peak, R.dsi_trailing_peak, R.dsi_peak));
legend(ax,{'Leading', 'Trailing', 'Full'});
hold(ax,'off');
