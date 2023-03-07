function required_fields = plot_ContrastResponse_CA(R,ax)
if nargin < 1
    required_fields = {'spikes_stim_mean', 'contrasts', 'spikes_stim_sem', ...
        'spikes_tail_mean', 'spikes_tail_sem'};
    return;
end

set(ax, 'XLim',[0 inf]);
errorbar(ax, R.contrasts, R.spikes_stim_mean, R.spikes_stim_sem,...
    'Color',[0 0 0],...
    'LineWidth',2);
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xlabel(ax, 'Contrast')
ylabel(ax, 'Spike count');
