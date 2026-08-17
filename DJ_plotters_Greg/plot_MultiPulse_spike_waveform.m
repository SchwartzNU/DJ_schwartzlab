function required_fields = plot_MultiPulse_spike_waveform(R,ax)
if nargin < 1
    required_fields = {'average_spike', ...
     'time_vector', ...
     'rheobase_mean'};
    return;
end

time_vector = R.time_vector;
average_spike = R.average_spike;
rheobase = R.rheobase_mean;


set(ax, 'XLim',[-inf inf]);
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');

plot(ax, time_vector, average_spike);
xlabel(ax, 'Time (ms)')
ylabel(ax, 'mV');
t = sprintf('Rheobase %.3f pA', rheobase);
subtitle(ax, t);
hold(ax,'off');