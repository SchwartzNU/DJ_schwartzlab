function R = Ramp_analysis(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('Ramp_analysis',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * sln_symphony.SpikeTrain * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.BlockParams('Ramp') * aka.EpochParams('Ramp') ...
        & datasets_struct(d), '*');

    sample_rate = epochs_in_dataset(1).sample_rate;
    raw_data = vertcat(epochs_in_dataset.raw_data);
    slope = epochs_in_dataset(1).ramp_slope;
    increase_per_datapoint = slope / sample_rate;

    pre_time = epochs_in_dataset(1).pre_time / 1000;
    stim_time = epochs_in_dataset(1).stim_time / 1000;
    tail_time = epochs_in_dataset(1).tail_time / 1000;


    stimulus = zeros(size(raw_data,2), 1);
    stim_temp = [0 : (stim_time * sample_rate) - 1] * increase_per_datapoint;
    stimulus(pre_time * sample_rate : (pre_time + stim_time) * sample_rate - 1) = stim_temp;

    resting_vm = mean(raw_data(:, 1:pre_time * sample_rate), 2);

    mean_trace = mean(raw_data, 1);
    % figure;
    % subplot(2,1,1);
    % plot(raw_data');
    % subplot(2,1,2);
    % plot(stimulus);

    %% Tail time analysis
    tau_1 = nan(size(raw_data,1), 1);
    tau_2 = nan(size(raw_data,1), 1);
    max_ahp = nan(size(raw_data, 1), 1);
    rheobase = nan(size(raw_data, 1), 1);
    max_spike_freq = nan(size(raw_data, 1), 1);
    block_current = nan(size(raw_data, 1), 1);


    if tail_time > 1
        fit_time = 1;
    else
        fit_time = tail_time - 0.2;

    end
    for i = 1 : size(raw_data,1)
        %post_stim_AHP
        post_stim_data = raw_data(i, ((pre_time + stim_time) * sample_rate) : ((pre_time + stim_time + 0.2) * sample_rate));
        [max_ahp(i), idx] = min(post_stim_data);
        idx = idx + (pre_time + stim_time) * sample_rate;
        y = raw_data(i, idx : (idx + (fit_time * sample_rate)));
        t = [0:length(y)-1] / sample_rate;

        ft = fittype( 'exp2' );
        opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
        opts.Algorithm = 'Levenberg-Marquardt';
        opts.Display = 'Off';
        opts.StartPoint = [-45.6079302262768 -0.000184482499308884 -19.8845504137804 0.000168607590000871];

        [xData, yData] = prepareCurveData(t, y);
        try
            [fitresult, gof] = fit( xData, yData, ft, opts );
            tau_1(i) = -1/fitresult.b;
            tau_2(i) = -1/fitresult.d;
        catch ME
            disp(ME.identifier)
            warning('Cannot fit');
        end
        %find current for first peak
        pre_time_point = pre_time * sample_rate;
        stim_end_point = (pre_time + stim_time) * sample_rate;

        spike_idx = [epochs_in_dataset(i).spike_indices];
        if isempty(spike_idx)
            rheobase(i) = 9999;
            block_current(i) =  9999;
        elseif spike_idx(1) < pre_time_point
            rheobase(i) = 0;
        else
            first_spike = spike_idx(1);
            rheobase(i) = stimulus(first_spike);
        end

        if isempty(spike_idx)
            max_spike_freq(i) = 0;
        else
            spikes_idx_stim = find((spike_idx > pre_time_point) & (spike_idx < stim_end_point));
            spikes_stim = spike_idx(spikes_idx_stim);
            if length(spikes_stim) > 1
                spike_instantaneous_freq = 1 ./ (double((spikes_stim(2:end) - spikes_stim(1:end-1))) ./ sample_rate);
                max_spike_freq(i) = max(spike_instantaneous_freq);
                
            else
                max_spike_freq(i) = 1 / stim_time;
            
            end
                
        end




    end
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.mean_trace{d} = mean_trace;
    R.stimulus{d} = stimulus;
    R.tau_1_mean(d) = mean(tau_1);
    R.tau_2_mean(d) = mean(tau_2);
    R.tau_1_sd(d) = std(tau_1);
    R.tau_2_sd(d) = std(tau_2);
    R.ahp_max_mean(d) = mean(max_ahp);
    R.ahp_max_std(d) = std(max_ahp);
    R.n_trial(d) = size(raw_data,1);
    R.resting_vm(d) = mean(resting_vm, 'omitmissing');
    R.rheobase{d} = [rheobase];
    R.rheobase_mean(d) = mean(rheobase, "omitmissing");
    R.rheobase_std(d) = std(rheobase, 'omitmissing');
    R.max_spike_frequency_mean(d) = mean(max_spike_freq);
    R.block_current(d) = mean(block_current);
end
end