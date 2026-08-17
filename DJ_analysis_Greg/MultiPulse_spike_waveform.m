function R = MultiPulse_spike_waveform(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
R = sln_results.table_definition_from_template('MultiPulse_spike_waveform',N_datasets);

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
    raw_data = vertcat(epochs_in_dataset.raw_data);
    PADDING_SIZE = 5 * 1E-3; %5ms total
    PADDING = PADDING_SIZE / 2 * sample_rate;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_1_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);

    pre_stim_samples = pre_samples + stim_samples;


    spike_indices = {epochs_in_dataset.spike_indices};

    all_currents = [epochs_in_dataset.pulse_1_curr];
    [currents, currents_idx]  = sort(all_currents);


    countstbl = countlabels(all_currents);
    number_of_trials = min([epochs_in_dataset(1).number_of_cycles, min(countstbl.Count)]);


    single_spike = zeros(number_of_trials, PADDING_SIZE * sample_rate + 1);
    time_vector = ([0 : PADDING_SIZE * sample_rate] - (PADDING_SIZE/2 * sample_rate)) ./ sample_rate * 1000; %ms
    rheobase = nan(number_of_trials, 1);

    idx = find(currents > 0, 1);
    spike_idx = 1;
    if isempty(spike_indices)
        warning('No Spike Detected')
    else
        while spike_idx < 4 & idx <= length(currents_idx)
            c = currents(idx);
            i = currents_idx(idx);
            spike_indice = spike_indices{i};
            background_spike = find(spike_indice < pre_samples, 3);

            if length(background_spike) < 3
                stim_spike_idx = find(spike_indice > pre_samples & spike_indice < pre_stim_samples, 1);
                if ~isempty(stim_spike_idx)
                    single_spike(spike_idx, :) = raw_data(i, spike_indice(stim_spike_idx)-PADDING : spike_indice(stim_spike_idx) + PADDING);
                    rheobase(spike_idx, 1) = c;
                    spike_idx = spike_idx + 1;
                else
                    idx = idx + 1;
                    
                end
            else

                rheobase(spike_idx, 1) = 0;
                single_spike(spike_idx, :) = raw_data(i, spike_indice(3)-PADDING :spike_indice(3) + PADDING);
                spike_idx = spike_idx + 1;
            end
            idx = idx + 1;
        end
    end

    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.average_spike{d} = mean(single_spike);
    R.rheobase_mean(d) = mean(rheobase);
    R.time_vector{d} = time_vector;
    R.spike_diff{d} = diff(mean(single_spike)) * (sample_rate/1000); %mV/ms

    fprintf('Elapsed time = %d seconds\n', round(toc));
end

end