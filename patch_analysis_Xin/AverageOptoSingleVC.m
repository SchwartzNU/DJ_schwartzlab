function R = AverageOptoSingleVC(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
datasets_struct.channel_name = 'Amp1';

R = sln_results.table_definition_from_template('AverageOptoSingleVC',N_datasets);
fprintf('Processing %s _source_id%d:%s for average VC trace\n', datasets_struct.file_name, datasets_struct.source_id);

epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * sln_symphony.ExperimentChannel...
    *sln_symphony.ExperimentEpochChannel...
    *aka.EpochParams('OptoPulse') * aka.BlockParams('OptoPulse')...
    & datasets_struct, '*');

N_epochs = length(epochs_in_dataset);
if N_epochs == 0
    error('No epochs of opto pulse found in dataset: %s', datasets_struct(d).dataset_name);
end

sample_rate = epochs_in_dataset.sample_rate;

pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
    'stim_time', epochs_in_dataset(1).stim_time, ...
 'tail_time', epochs_in_dataset(1).tail_time);
pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
total_samples = pre_samples + stim_samples + tail_samples;

trace_all_vector = zeros(N_epochs, total_samples);
for i = 1:N_epochs
    %get the raw data
    single_trace = epochs_in_dataset(i).raw_data;
    single_bline = mean(single_trace);

    %TO DO put some filtering??

    %subtract the baseline
    trace_all_vector(i, :) = single_trace-single_bline;
end

%mean trace
R.average_trace = zeros([1, sample_rate * total_samples]);
R.average_trace = mean(trace_all_vector, 1);
%happily copy paste things into result table...
R.file_name = datasets_struct.file_name;
R.dataset_name = datasets_struct.dataset_name;
R.source_id = datasets_struct.source_id;
R.pre_time_ms = pre_stim_tail.pre_time;
R.stim_time_ms = pre_stim_tail.stim_time;
R.tail_time_ms = pre_stim_tail.tail_time;
R.sample_rate = sample_rate;
R.epoch_total = N_epochs;
fprintf('Average trace analyzed.\n');
end

% for d=1:N_datasets
%     tic;
%     fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);
% 
%     epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
%         sln_symphony.ExperimentChannel * ...
%         sln_symphony.ExperimentEpochChannel * ...
%         aka.EpochParams('SpotsMultiSize') * ...
%         aka.BlockParams('SpotsMultiSize') & ...
%         datasets_struct(d),'*');
%     N_epochs = length(epochs_in_dataset);
% 
%     if N_epochs == 0
%         error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
%     end
% 
%     %parameters to save for the whole dataset
%     sample_rate = epochs_in_dataset(1).sample_rate;
% 
%     %rstar_mean = epochs_in_dataset(1).rstar_mean;
%     pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
%         'stim_time', epochs_in_dataset(1).stim_time, ...
%         'tail_time', epochs_in_dataset(1).tail_time);
%     pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
%     stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
%     tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
%     total_samples = pre_samples + stim_samples + tail_samples;
% 
%     all_spot_sizes = round([epochs_in_dataset.cur_spot_size]);
%     spot_sizes = sort(unique(all_spot_sizes));
%     N_spot_sizes = length(spot_sizes);
% 
%     N_epochs_per_size = zeros(N_spot_sizes,1);
%     peak_stim_mean = zeros(N_spot_sizes,1);
%     peak_tail_mean = zeros(N_spot_sizes,1);
%     peak_stim_sem = zeros(N_spot_sizes,1);
%     peak_tail_sem = zeros(N_spot_sizes,1);
%     charge_stim_mean = zeros(N_spot_sizes,1);
%     charge_tail_mean = zeros(N_spot_sizes,1);
%     charge_stim_sem = zeros(N_spot_sizes,1);
%     charge_tail_sem = zeros(N_spot_sizes,1);
%     holding_current_vector = zeros(N_spot_sizes,1);
%     mean_traces = zeros(N_spot_sizes, total_samples);
% 
%     for s=1:N_spot_sizes
%         ind = find(all_spot_sizes == spot_sizes(s));
%         N_epochs_per_size(s) = length(ind);
%         mean_traces(s,:) = mean(reshape([epochs_in_dataset(ind).raw_data], [], length(ind)), 2)';
%         holding_current_vector(s) = mean(mean_traces(s,1:pre_samples));
% 
%         peak_stim = zeros(N_epochs_per_size(s),2);
%         peak_tail = zeros(N_epochs_per_size(s),2);
%         charge_stim = zeros(N_epochs_per_size(s),1);
%         charge_tail = zeros(N_epochs_per_size(s),1);
%         for i=1:N_epochs_per_size(s)
%             trace = epochs_in_dataset(ind(i)).raw_data;
%             baseline = mean(trace(1:pre_samples));
%             trace_baseline_subtraced = trace - baseline;
%             peak_stim(i,1) = min(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples));
%             peak_stim(i,2) = max(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples));
%             peak_tail(i,1) = min(trace_baseline_subtraced(pre_samples+stim_samples+1:total_samples));
%             peak_tail(i,2) = max(trace_baseline_subtraced(pre_samples+stim_samples+1:total_samples));            
%             charge_stim(i) = sum(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples))/sample_rate;
%             charge_tail(i) = sum(trace_baseline_subtraced(pre_samples+stim_samples+1:total_samples))/sample_rate;
%         end
%         if abs(mean(peak_stim(:,1))) > abs(mean(peak_stim(:,2)))
%             peak_stim_mean(s) = mean(peak_stim(:,1));
%             peak_stim_sem(s) = std(peak_stim(:,1)) ./ sqrt(N_epochs_per_size(s)-1);
%         else
%             peak_stim_mean(s) = mean(peak_stim(:,2));
%             peak_stim_sem(s) = std(peak_stim(:,2)) ./ sqrt(N_epochs_per_size(s)-1);
%         end
%         if abs(mean(peak_tail(:,1))) > abs(mean(peak_tail(:,2)))
%             peak_tail_mean(s) = mean(peak_tail(:,1));
%             peak_tail_sem(s) = std(peak_tail(:,1)) ./ sqrt(N_epochs_per_size(s)-1);
%         else
%             peak_tail_mean(s) = mean(peak_tail(:,2));
%             peak_tail_sem(s) = std(peak_tail(:,2)) ./ sqrt(N_epochs_per_size(s)-1);
%         end
% 
%         charge_stim_mean(s) = mean(charge_stim);
%         charge_stim_sem(s) = std(charge_stim) ./ sqrt(N_epochs_per_size(s)-1);
%         charge_tail_mean(s) = mean(charge_tail);
%         charge_tail_sem(s) = std(charge_tail) ./ sqrt(N_epochs_per_size(s)-1);
%     end
% 
%     holding_current_mean = mean(holding_current_vector);
% 
%     %set table variables
%     R.file_name{d} = datasets_struct(d).file_name;
%     R.dataset_name{d} = datasets_struct(d).dataset_name;
%     R.source_id(d) = datasets_struct(d).source_id;
%     R.spot_sizes{d} = spot_sizes';
%     R.sample_rate(d) = sample_rate;
%     R.pre_time_ms(d) = pre_stim_tail.pre_time;
%     R.stim_time_ms(d) = pre_stim_tail.stim_time;
%     R.tail_time_ms(d) = pre_stim_tail.tail_time;
%     R.n_epochs_per_size{d} = N_epochs_per_size;
%     R.peak_stim_mean{d} = peak_stim_mean;
%     R.peak_tail_mean{d} = peak_tail_mean;
%     R.peak_stim_sem{d} = peak_stim_sem;
%     R.peak_tail_sem{d} = peak_tail_sem;
%     R.charge_stim_mean{d} = charge_stim_mean;
%     R.charge_tail_mean{d} = charge_tail_mean;
%     R.charge_stim_sem{d} = charge_stim_sem;
%     R.charge_tail_sem{d} = charge_tail_sem;
%     R.mean_traces{d} = mean_traces;
%     R.holding_current_mean(d) = holding_current_mean;
% 
%     fprintf('Elapsed time = %d seconds\n', round(toc));
% end