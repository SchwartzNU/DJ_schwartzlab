function required_fields = plot_SMS_CA(R,ax)
if nargin < 1
    required_fields = {'spikes_stim_mean', 'spot_sizes', 'spikes_stim_sem', ...
        'spikes_tail_mean', 'spikes_tail_sem'};
    return;
end

set(ax, 'XLim',[0 inf]);
errorbar(ax, R.spot_sizes, R.spikes_stim_mean, R.spikes_stim_sem,...
    'Color',[0 1 1],...
    'LineWidth',2);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax,'on');
xlabel(ax, 'Spot size (microns)')
ylabel(ax, 'Spike count');
errorbar(ax, R.spot_sizes, R.spikes_tail_mean, R.spikes_tail_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
legend(ax,{'ON', 'OFF'});
hold(ax,'off');
