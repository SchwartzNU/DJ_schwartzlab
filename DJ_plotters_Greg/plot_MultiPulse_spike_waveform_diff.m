function required_fields = plot_MultiPulse_spike_waveform_diff(R,ax)
if nargin < 1
    required_fields = {'average_spike', ...
     'spike_diff'};
    return;
end


average_spike = R.average_spike;
spike_diff = R.spike_diff;


set(ax, 'XLim',[-inf inf]);
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');

plot(ax, average_spike(2:end), spike_diff);
xlabel(ax, 'mV')
ylabel(ax, 'mV/ms');

hold(ax,'off');