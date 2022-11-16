function plot_DriftingGratings_MultiCondition_CC_cycleAvg(R,condition_struct,ax)

trace_set = R.cycle_avg_trace_by_condition;

if strcmp(condition_struct.speed,'plot all')
    legend_vals = R.speeds;
    legend_title = 'Speed (µm/s)';
    N_traces = length(R.speeds);
    for i=1:N_traces
        condition_name = sprintf('speed_%d_direction_%s_halfwidth_%s_contrast_%s',...
            R.speeds(i), condition_struct.direction, condition_struct.halfwidth, condition_struct.contrast);
        traces{i} = trace_set.(condition_name);
    end


elseif strcmp(condition_struct.direction,'plot all')
    legend_vals = R.directions;
    legend_title = 'Movement dir. (°)';
    N_traces = length(R.directions);
    for i=1:N_traces
        condition_name = sprintf('speed_%s_direction_%d_halfwidth_%s_contrast_%s',...
            condition_struct.speed, R.directions(i), condition_struct.halfwidth, condition_struct.contrast);
        traces{i} = trace_set.(condition_name);
    end

elseif strcmp(condition_struct.halfwidth,'plot all')
    legend_vals = R.halfwidths;
    legend_title = 'Half width (µm)';
        N_traces = length(R.halfwidths);
    for i=1:N_traces
        condition_name = sprintf('speed_%s_direction_%s_halfwidth_%d_contrast_%s',...
            condition_struct.speed, condition_struct.direction, R.halfwidths(i), condition_struct.contrast);
        traces{i} = trace_set.(condition_name);
    end


elseif strcmp(condition_struct.contrast,'plot all')
    N_traces = length(R.contrasts);
    legend_vals = R.contrasts;
    legend_title = 'Contrast';
    for i=1:N_traces
        condition_name = sprintf('speed_%s_direction_%s_halfwidth_%s_contrast_%d',...
            condition_struct.speed, condition_struct.direction, condition_struct.halfwidth, R.contrasts(i));
        traces{i} = trace_set.(condition_name);
    end

else
    disp('plotting a single trace');
    N_traces = 1;
    condition_name = sprintf('speed_%s_direction_%s_halfwidth_%s_contrast_%s',...
            condition_struct.speed, condition_struct.direction, condition_struct.halfwidth,  condition_struct.contrast);
    traces{1} = trace_set.(condition_name);
end

set(ax, 'XLim',[-inf inf]);
cmap = colormap(ax,'parula');
ind = round(linspace(1,256,N_traces));

hold(ax,'on');
set(ax, 'XtickMode','auto');
set(ax, 'YtickMode','auto');

if N_traces==1
    Nsamples = length(traces{1});
    time_axis = (0:Nsamples-1) / R.sample_rate - R.pre_time_ms / 1E3;
    plot(ax, time_axis, traces{1},'Color','k');
else
    for i=1:N_traces
        Nsamples = length(traces{i});
        time_axis = (0:Nsamples-1) / R.sample_rate - R.pre_time_ms / 1E3;
        plot(ax, time_axis, traces{i},'Color',cmap(ind(i),:));
    end
end
xlabel(ax, 'Time (s)')
ylabel(ax, 'mV');

if N_traces > 1
    lgd = legend(ax, cellstr(num2str(legend_vals)));
    title(lgd, legend_title);   
end

hold(ax,'off');