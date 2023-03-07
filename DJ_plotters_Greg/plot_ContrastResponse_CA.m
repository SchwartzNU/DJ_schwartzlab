function required_fields = plot_ContrastResponse_CA(R,ax)
if nargin < 1
    required_fields = {'spikes_stim_mean', 'contrasts', 'spikes_stim_sem', ...
        'spikes_tail_mean', 'spikes_tail_sem'};
    return;
end

set(ax, 'XLim',[-1 1]);
errorbar(ax, R.contrasts, R.spikes_stim_mean, R.spikes_stim_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
baseline_rate = interp1(R.contrasts, R.spikes_stim_mean, 0);
hold(ax,'on');
line(ax, [-1, 1], [baseline_rate, baseline_rate], 'LineStyle', '--', 'Color', 'k');
line(ax, [0 0], [min(R.spikes_stim_mean), max(R.spikes_stim_mean)], 'LineStyle', '--', 'Color', 'k');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xlabel(ax, 'Contrast')
ylabel(ax, 'Spike count');
hold(ax,'off');
