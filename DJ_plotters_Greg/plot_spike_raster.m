function required_fields = plot_spike_raster(R,ax)
if nargin < 1
    required_fields = {'psth_x', 'pre_time_ms', 'stim_time_ms', 'tail_time_ms'}; %don't really use psth_x, but here so we don't include stuff without spikes
    return;
end

spike_train_query = sln_symphony.ExperimentChannel * sln_symphony.DatasetEpoch * sln_symphony.SpikeTrain & ...
    sprintf('file_name="%s"', R.file_name) & ...
    sprintf('dataset_name="%s"', R.dataset_name) & ...
    sprintf('source_id=%d',R.source_id);

if ~spike_train_query.exists
    disp('No spike trains found');
    return
end

sample_rate = unique(fetchn(spike_train_query,'sample_rate'));
if length(sample_rate)>1
    disp('Error: multiple sample rates in dataset');
end

end_time = R.stim_time_ms + R.tail_time_ms;

all_spikes = fetchn(spike_train_query,'spike_indices');

N_trials = length(all_spikes);

hold(ax,'on');
for i=1:N_trials
    y_vals = ones(length(all_spikes{i}),1) * i;
    x_vals = double(all_spikes{i}) / sample_rate - R.pre_time_ms / 1E3;
    plot(ax,x_vals,y_vals,'k|');
end

xlabel(ax, 'Time (s)')
ylabel(ax, 'Trial');
set(ax,'XtickMode','auto');
set(ax,'YtickMode','auto');
xlim(ax, [-R.pre_time_ms / 1E3, end_time / 1E3]);
%axis(ax,'tight');
hold(ax,'off');

