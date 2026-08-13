function R = MultiPulse_spike_waveform(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
R = struct();
%R = sln_results.table_definition_from_template('MultiPulse_varyCurrent_FeatureExtract',N_datasets);

for d = 1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);
    
    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.MultiPulseParams * sln_symphony.SpikeTrain & ...
        datasets_struct(d) & 'channel_name LIKE "Amp_"','*');
    N_epochs = length(epochs_in_dataset);
    
    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    sample_rate = epochs_in_dataset(1).sample_rate;
    PADDING_SIZE = 2 * 1E-3; %4ms total
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_1_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
    tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
    total_samples = pre_samples + stim_samples + tail_samples;

    all_currents = [epochs_in_dataset.pulse_1_curr];
    currents  = sort(unique(all_currents));
    pos_current = find(currents > 0);

    countstbl = countlabels(all_currents);
    number_of_trials = min([epochs_in_dataset(1).number_of_cycles, min(countstbl.Count)]);
    fprintf('Elapsed time = %d seconds\n', round(toc));
end

end 