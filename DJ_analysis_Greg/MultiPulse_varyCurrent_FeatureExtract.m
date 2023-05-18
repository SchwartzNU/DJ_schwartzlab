function R = MultiPulse_varyCurrent_FeatureExtract(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('MultiPulse_varyCurrent_FeatureExtract',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.MultiPulseParams & ...
        datasets_struct(d),'*');
    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_1_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
    tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
    total_samples = pre_samples + stim_samples + tail_samples;
    ss_samples = 50E-3 * sample_rate;

    all_currents = [epochs_in_dataset.pulse_1_curr];
    
    currents  = sort(unique(all_currents));
    N_currents = length(currents);

    N_epochs_per_current = zeros(N_currents,1);
    vmax = zeros(N_currents,1);
    vmin = zeros(N_currents,1);
    vmax_rebound = zeros(N_currents,1);
    vmin_rebound = zeros(N_currents,1);
    vsteady= zeros(N_currents,1);
    tmax = zeros(N_currents,1);
    tmin = zeros(N_currents,1);
    tmax_rebound = zeros(N_currents,1);
    tmin_rebound = zeros(N_currents,1);
    vrest_vector = zeros(N_currents,1);
    mean_traces = zeros(N_currents, total_samples);
    example_traces = zeros(N_currents, total_samples);
    countstbl = countlabels(all_currents);
    number_of_trials = max(countstbl.Count);
    if sum(countstbl.Count ~= number_of_trials) > 0 | number_of_trials  ~= epochs_in_dataset(1).number_of_cycles
        warning('Numbers of epochs between trials are not the same')
        number_of_trials = min([epochs_in_dataset.number_of_cycles]);
    end
    all_traces = zeros(number_of_trials, N_currents, total_samples);
    

    for s=1:N_currents
        ind = find(all_currents == currents(s));
        N_epochs_per_current(s) = length(ind);
        trace = mean(reshape([epochs_in_dataset(ind).raw_data], [], length(ind)), 2)';
        mean_traces(s,:) = trace;
        example_traces(s,:) = epochs_in_dataset(ind(1)).raw_data;

        for j = 1:number_of_trials
            all_traces(j, s, :) = epochs_in_dataset(ind(j)).raw_data;
        end

        vrest_vector(s) = mean(trace(1:pre_samples));

        vsteady(s) = mean(trace(pre_samples+stim_samples-ss_samples:pre_samples+stim_samples));
        if currents(s)>0
            [vmax(s), t] = max(trace(pre_samples+1:pre_samples+stim_samples));
            vmax(s) = vmax(s) - vsteady(s); %overshoot
            tmax(s) = 1E3 * t / sample_rate;
        else
            [vmin(s), t] = min(trace(pre_samples+1:pre_samples+stim_samples) - vrest_vector(s));
            tmin(s) = 1E3 * t / sample_rate;
        end

        [vmax_rebound(s), t] = max(trace(pre_samples+stim_samples+1:end) - vrest_vector(s));
        tmax_rebound(s) = 1E3 * t / sample_rate;
        [vmin_rebound(s), t] = min(trace(pre_samples+stim_samples+1:end) - vrest_vector(s));
        tmin_rebound(s) = 1E3 * t / sample_rate;

        %% Feature Extraction Part
        %% Init
        start_time = pre_time_ms * 10^-3 * sample_rate;
        end_time = start_time + pre_stim_tail.stim_time * 10^-3 * sample_rate;
        hyper_current_epoch = find(currents' < 0);
        depol_current_epoch = find(currents' > 0);
        hyper_current_level_pA = currents'(hyper_current_epoch);
        depol_current_level_pA = currents'(depol_current_epoch);
        time_in_s = linspace(0, size(hyper_Vm,1), size(hyper_Vm,1)) / sample_rate;

        for trial = 1:number_of_trials
            hyper_Vm = all_traces(trial,currents' < 0 ,:);
            hyper_Vm = hyper_Vm'
            depol_Vm = example_traces(trial,currents' > 0,:);
            depol_Vm = depol_Vm'
         
        end
    
    end



    vrest = mean(vrest_vector);




    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.inj_current{d} = currents';
    R.pre_time_ms(d) = pre_stim_tail.pre_time;
    R.stim_time_ms(d) = pre_stim_tail.stim_time;
    R.n_epochs_per_current{d} = N_epochs_per_current;
    R.vrest(d) = vrest;
    R.vsteady{d} = vsteady;
    R.vmax{d} = vmax;
    R.vmax_norm{d} = vmax ./ max(vmax);
    R.vmin{d} = vmin;
    R.vmax_rebound{d} = vmax_rebound;
    R.vmin_rebound{d} = vmin_rebound;
    R.tmax{d} = tmax;
    R.tmin{d} = tmin;
    R.tmax_rebound{d} = tmax_rebound;
    R.tmin_rebound{d} = tmin_rebound;
    R.mean_traces{d} = mean_traces;
    R.example_traces{d} = example_traces;
    R.sample_rate(d) = sample_rate;

    R(d, :)
    feature_struct = FeatureExtract_new(R(d, :));
    R.features{d} = {feature_struct};

    fprintf('Elapsed time = %d seconds\n', round(toc));

end