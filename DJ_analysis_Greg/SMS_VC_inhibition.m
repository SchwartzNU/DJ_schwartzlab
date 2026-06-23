function R = SMS_VC_inhibition(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('SMSVC_inhibition',N_datasets);

for d = 1:N_datasets
    try
        tic;
        fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

        epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
            sln_symphony.ExperimentChannel * ...
            sln_symphony.ExperimentEpochChannel * ...
            aka.EpochParams('SpotsMultiSize') * ...
            aka.BlockParams('SpotsMultiSize') * ...
            sln_symphony.ExperimentElectrode & ...
            datasets_struct(d) ...
            & 'channel_name = "Amp1" or channel_name = "Amp2"','*');
        N_epochs = length(epochs_in_dataset);

        if N_epochs == 0
            error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
        end

        sample_rate = epochs_in_dataset(1).sample_rate;

        pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
            'stim_time', epochs_in_dataset(1).stim_time, ...
            'tail_time', epochs_in_dataset(1).tail_time);
        pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
        stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
        tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
        total_samples = pre_samples + stim_samples + tail_samples;

        stim_stop_idx = pre_samples + stim_samples;

        all_spot_sizes = round([epochs_in_dataset.cur_spot_size]);
        spot_sizes = sort(unique(all_spot_sizes));
        N_spot_sizes = length(spot_sizes);

        Fs = sample_rate;  % Sampling Frequency

        Fpass = 2500;       % Passband Frequency
        Fstop = 5000;       % Stopband Frequency
        Apass = 1;           % Passband Ripple (dB)
        Astop = 80;          % Stopband Attenuation (dB)
        match = 'stopband';  % Band to match exactly

        % Construct an FDESIGN object and call its BUTTER method.
        h  = fdesign.lowpass(Fpass, Fstop, Apass, Astop, Fs);
        Hd = design(h, 'butter', 'MatchExactly', match);

        N_epochs_per_size = zeros(N_spot_sizes,1);
        peak_stim_mean = zeros(N_spot_sizes,1);
        peak_tail_mean = zeros(N_spot_sizes,1);
        peak_stim_sem = zeros(N_spot_sizes,1);
        peak_tail_sem = zeros(N_spot_sizes,1);
        charge_stim_mean = zeros(N_spot_sizes,1);
        charge_tail_mean = zeros(N_spot_sizes,1);
        charge_stim_sem = zeros(N_spot_sizes,1);
        charge_tail_sem = zeros(N_spot_sizes,1);
        holding_current_vector = zeros(N_spot_sizes,1);
        mean_traces = zeros(N_spot_sizes, total_samples);
        mean_zeroed_traces = zeros(N_spot_sizes, total_samples);
        holding_voltage = epochs_in_dataset(1).hold;

        if holding_voltage < 0
            warning('Holding voltage %f < 0 mV', holding_voltage)
        end

        raw_data = vertcat(epochs_in_dataset.raw_data);
        filtered_data = nan(size(raw_data));
        baseline_substracted_data = nan(size(raw_data));

        peak_stim = nan(size(raw_data,1));
        peak_tail = nan(size(raw_data,1));
        charge_stim = nan(size(raw_data,1));
        charge_tail = nan(size(raw_data,1));

        for r = 1 : size(raw_data, 1)
            filtered_row = filtfilt(Hd.sosMatrix, Hd.ScaleValues, raw_data(r,:));
            filtered_data(r, :) = filtered_row;
            baseline = mean(filtered_row(1 : pre_samples));
            holding_current_vector(r, 1) = baseline;
            baseline_substracted_data(r, :) = filtered_row - baseline;

            peak_stim(r, 1) = max(baseline_substracted_data(pre_samples : stim_stop_idx));
            peak_tail(r, 1) = max(baseline_substracted_data(stim_stop_idx + 1 : total_samples));

            charge_stim(r,1) = sum(baseline_substracted_data(pre_samples : stim_stop_idx)) / sample_rate;
            charge_tail(r,1) = sum(baseline_substracted_data(stim_stop_idx + 1 : total_samples)) / sample_rate;
        end

        for s = 1 : N_spot_sizes
            ind = find(all_spot_sizes == spot_sizes(s));
            N_epochs_per_size(s) = length(ind);

            traces = filtered_data(ind, :);
            mean_traces(s, :) = mean(traces, 1);

            zeroed_traces = baseline_substracted_data(ind, :);
            mean_zeroed_traces(s, :) = mean(zeroed_traces, 1);

            peak_stim_mean(s) = mean(peak_stim(ind));
            peak_tail_mean(s) = mean(peak_tail(ind));

            peak_stim_sem(s) = std(peak_stim(ind))./ sqrt(N_epochs_per_size(s) - 1);
            peak_tail_sem(s) = std(peak_tail(ind))./ sqrt(N_epochs_per_size(s) - 1);

            charge_stim_mean(s) = mean(charge_stim(ind));
            charge_tail_mean(s) = mean(charge_tail(ind));

            charge_stim_sem(s) = std(charge_stim(ind))./ sqrt(N_epochs_per_size(s) - 1);
            charge_tail_sem(s) = std(charge_tail(ind))./ sqrt(N_epochs_per_size(s) - 1);

        end

        holding_current_mean = mean(holding_current_vector);

        R.file_name{d} = datasets_struct(d).file_name;
        R.dataset_name{d} = datasets_struct(d).dataset_name;
        R.source_id(d) = datasets_struct(d).source_id;
        R.spot_sizes{d} = spot_sizes';
        R.sample_rate(d) = sample_rate;
        R.pre_time_ms(d) = pre_stim_tail.pre_time;
        R.stim_time_ms(d) = pre_stim_tail.stim_time;
        R.tail_time_ms(d) = pre_stim_tail.tail_time;
        R.n_epochs_per_size{d} = N_epochs_per_size;
        R.peak_stim_mean{d} = peak_stim_mean;
        R.peak_tail_mean{d} = peak_tail_mean;
        R.peak_stim_sem{d} = peak_stim_sem;
        R.peak_tail_sem{d} = peak_tail_sem;
        R.charge_stim_mean{d} = charge_stim_mean;
        R.charge_tail_mean{d} = charge_tail_mean;
        R.charge_stim_sem{d} = charge_stim_sem;
        R.charge_tail_sem{d} = charge_tail_sem;
        R.mean_traces{d} = mean_traces;
        R.mean_zeroed_traces{d} = mean_zeroed_traces;
        R.holding_current_mean(d) = holding_current_mean;
        R.holding_voltage(d) = holding_voltage;

        fprintf('Elapsed time = %d seconds\n', round(toc));
    catch ME
        warning('error')
        disp(ME)

    end



end
