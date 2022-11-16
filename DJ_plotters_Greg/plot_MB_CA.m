function plot_MB_CA(R,ax)
%set(ax, 'XLimM',[0 inf]);
hold(ax,'on');
errorbar(ax, R.bar_angles, R.spikes_leading_mean, R.spikes_leading_sem,...
    'Color',[0 1 1],...
    'LineWidth',2);
errorbar(ax, R.bar_angles, R.spikes_trailing_mean, R.spikes_trailing_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
errorbar(ax, R.bar_angles, R.spikes_full_mean, R.spikes_full_sem,...
    'Color',[.5 .5 .5],...
    'LineWidth',1);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax,'on');
xlabel(ax, 'Bar angle (degrees)')
ylabel(ax, 'Spike count');
title(ax,sprintf('DSI: leading = %0.2f, trailing = %0.2f, full = %0.2f', R.dsi_leading, R.dsi_trailing, R.dsi));
legend(ax,{'Leading', 'Trailing', 'Full'});
hold(ax,'off');
