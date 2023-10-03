function required_fields = plot_FlashedBar_CA(R,ax)
if nargin < 1
    required_fields = {'spikes_stim_mean', 'bar_angles', 'spikes_stim_sem', ...
        'spikes_tail_mean', 'spikes_tail_sem'};
    return;
end

set(ax, 'XLim',[0 inf]);
errorbar(ax, R.bar_angles, R.spikes_stim_mean, R.spikes_stim_sem,...
    'Color',[0 1 1],...
    'LineWidth',2);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
hold(ax,'on');
xlabel(ax, 'Bar angle (degrees)')
ylabel(ax, 'Spike count');
errorbar(ax, R.bar_angles, R.spikes_tail_mean, R.spikes_tail_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
legend(ax,{'ON', 'OFF'});
hold(ax,'off');
