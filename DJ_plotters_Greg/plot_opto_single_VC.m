function required_fields= plot_opto_single_VC(R,ax)

if nargin < 1
    required_fields = {'pre_time_ms', 'stim_time_ms', 'tail_time_ms', 'average_trace'};
    return;
end

time_total = (R.pre_time_ms + R.stim_time_ms + R.tail_time_ms)/1E3;
%set(ax, 'XLim', [0, time_total + 0.2]);

datapoints = size(R.average_trace);
axis_x = linspace(0, time_total, datapoints(2));
hold (ax, 'on');
plot(ax, axis_x, R.average_trace, 'k');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xline(ax, R.pre_time_ms/1E3, '-', 'color', 'blue');
xline(ax, (R.pre_time_ms+R.stim_time_ms)/1E3, '--', 'color', 'blue');
ylabel(ax, 'Synpatic current (pA)');
xlabel(ax, 'Time(ms)');
hold (ax, 'off');

end