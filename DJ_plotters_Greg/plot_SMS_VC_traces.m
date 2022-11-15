function plot_SMS_VC_traces(R,ax)
set(ax, 'XLim',[-inf inf]);
traces = R.mean_traces;
spot_sizes = R.spot_sizes;
cmap = colormap('parula');
Nspots = length(spot_sizes);
ind = round(linspace(1,256,Nspots));

Nsamples = size(traces,2);
time_axis = (0:Nsamples-1) / R.sample_rate - R.pre_time_ms / 1E3;
hold(ax,'on');

for i=1:Nspots
    plot(ax, time_axis, traces(i,:),'Color',cmap(ind(i),:));
end
xlabel(ax, 'Time (s)')
ylabel(ax, 'pA');

lgd = legend(ax, num2str(spot_sizes));
title(lgd, 'Spot size (µm)');   
hold(ax,'off');