function required_fields = plot_Uncaging_CC_traces(R,ax)
if nargin < 1
    required_fields = {'example_traces', 'spot_sizes', 'sample_rate', 'pre_time_ms'};
    return;
end

set(ax, 'XLim',[-inf inf]);
traces = R.example_traces;
spot_sizes = R.spot_sizes;
cmap = colormap(ax,'parula');
Nspots = length(spot_sizes);
ind = round(linspace(1,256,Nspots));

Nsamples = size(traces,2);
time_axis = (0:Nsamples-1) / R.sample_rate - R.pre_time_ms / 1E3;
hold(ax,'on');
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');

for i=1:Nspots
    plot(ax, time_axis, traces(i,:),'Color',cmap(ind(i),:));
end
xlabel(ax, 'Time (s)')
ylabel(ax, 'mV');

lgd = legend(ax, num2str(spot_sizes));
title(lgd, 'Spot size (µm)');   
hold(ax,'off');