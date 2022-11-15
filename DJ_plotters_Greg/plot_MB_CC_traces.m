function plot_MB_CC_traces(R,ax)
set(ax, 'XLim',[-inf inf]);
traces = R.example_traces_by_angle;
bar_angles = round(R.bar_angles);
cmap = colormap(ax,'parula');
Nangles= length(bar_angles);
ind = round(linspace(1,256,Nangles));

Nsamples = size(traces,2);
time_axis = (0:Nsamples-1) / R.sample_rate - R.pre_time_ms / 1E3;
hold(ax,'on');
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');

for i=1:Nangles
    plot(ax, time_axis, traces(i,:),'Color',cmap(ind(i),:));
end
xlabel(ax, 'Time (s)')
ylabel(ax, 'mV');

lgd = legend(ax, num2str(bar_angles));
title(lgd, 'Angle (degrees)');   
hold(ax,'off');