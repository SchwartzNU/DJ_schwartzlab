function R = AverageOptoSingleVC(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
R = sln_results.table_definition_from_template('AverageOptoSingleVC',N_datasets);

for d = 1:N_datasets
    datasets_struct(d).channel_name = 'Amp1';
    fprintf('Processing %s _source_id%d:%s for average VC trace\n', datasets_struct(d).file_name, datasets_struct(d).source_id);
    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * sln_symphony.ExperimentChannel...
        *sln_symphony.ExperimentEpochChannel...
        *aka.EpochParams('OptoPulse') * aka.BlockParams('OptoPulse')...
        & datasets_struct(d), '*');
    N_epochs = length(epochs_in_dataset);
    if N_epochs == 0
        error('No epochs of opto pulse found in dataset: %s', datasets_struct(d).dataset_name);
    end
    sample_rate = epochs_in_dataset.sample_rate;

    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(d).stim_time, ...
        'tail_time', epochs_in_dataset(d).tail_time);
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
    mean_trace = mean(trace_all_vector, 1);
    R.average_trace(d) ={mean_trace};

    %happily copy paste things into result table...
    R.file_name(d) = datasets_struct.file_name;
    R.dataset_name(d) = datasets_struct.dataset_name;
    R.source_id(d) = datasets_struct.source_id;
    R.pre_time_ms(d) = pre_stim_tail.pre_time;
    R.stim_time_ms(d) = pre_stim_tail.stim_time;
    R.tail_time_ms(d) = pre_stim_tail.tail_time;
    R.sample_rate(d) = sample_rate;
    R.epoch_total(d) = N_epochs;
    fprintf('Average trace analyzed.\n');
end


end

