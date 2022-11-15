function plot_MultiPulse_traces(R,ax)
set(ax, 'XLim',[-inf inf]);
traces = R.example_traces;
inj_current = round(R.inj_current);
cmap = colormap(ax,'parula');
Ncurrents= length(inj_current);
ind = round(linspace(1,256,Ncurrents));

Nsamples = size(traces,2);
time_axis = (0:Nsamples-1) / R.sample_rate - R.pre_time_ms / 1E3;
hold(ax,'on');
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');

for i=1:Ncurrents
    plot(ax, time_axis, traces(i,:),'Color',cmap(ind(i),:));
end
xlabel(ax, 'Time (s)')
ylabel(ax, 'mV');

lgd = legend(ax, num2str(inj_current));
title(lgd, 'Current (pA)');   
hold(ax,'off');