function required_fields = plot_IV_traces(R,ax)
if nargin < 1
    required_fields = {'mean_traces', 'hold_voltages', 'sample_rate', 'pre_time_ms'};
    return;
end

set(ax, 'XLim',[-inf inf]);
traces = R.mean_traces;
hold_voltages = R.hold_voltages;
cmap = colormap(ax,'parula');
Nholds = length(hold_voltages);
ind = round(linspace(1,256,Nholds));

Nsamples = size(traces,2);
time_axis = (0:Nsamples-1) / R.sample_rate - R.pre_time_ms / 1E3;
hold(ax,'on');
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');

for i=1:Nholds
    plot(ax, time_axis, traces(i,:),'Color',cmap(ind(i),:));
end
xlabel(ax, 'Time (s)')
ylabel(ax, 'mV');

lgd = legend(ax, num2str(hold_voltages));
title(lgd, 'Hold voltage (mV)');   
hold(ax,'off');