function required_fields = plot_Uncaging_CC_traces(R,ax)
if nargin < 1
    required_fields = {'time_axis', 'traces_mean', 'number_of_stim_groups', 'drug_condition'};
    return;
end

set(ax, 'XLim',[-inf inf]);
traces = R.traces_mean;
t = R.time_axis;
cmap = colormap(ax,'parula');
N_loc = R.number_of_stim_groups;
ind = round(linspace(1,256,N_loc));

hold(ax,'on');
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');
title(ax,R.drug_condition);

for i=1:N_loc
    plot(ax, t{i}, traces{i},'Color',cmap(ind(i),:));
end
xlabel(ax, 'Time (s)')
ylabel(ax, 'mV');

lgd = legend(ax, num2str([1:N_loc]'));
title(lgd, 'Location');   
hold(ax,'off');