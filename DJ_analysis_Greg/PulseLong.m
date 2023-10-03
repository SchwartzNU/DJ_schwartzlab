function R = PulseLong(data_group, params)

datasets = aka.Dataset * sln_symphony.ExperimentCell & proj(data_group);
datasets_struct = fetch(datasets,'cell_number');
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('PulseLong',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %sc%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).cell_number, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.SpikeTrain * ...
        aka.PulseParams & ...
        datasets_struct(d),'*');
    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
    tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
    total_samples = pre_samples + stim_samples + tail_samples;

    all_currents = round([epochs_in_dataset.pulse_amplitude]);
    currents  = sort(unique(all_currents));
    N_currents = length(currents);

    N_epochs_per_current = zeros(N_currents,1);
    vrest_vector = zeros(N_currents,1);
    ahp_amplitude = zeros(N_currents,1);
    ahp_time = zeros(N_currents,1);
    spike_count_mean = zeros(N_currents,1);
    spike_count_sem = zeros(N_currents,1);
    ahp_decay_tau1 = zeros(N_currents,1);
    ahp_decay_tau2 = zeros(N_currents,1);
    ahp_tau1_coeff = zeros(N_currents,1);
    mean_traces = zeros(N_currents, total_samples);
    example_traces = zeros(N_currents, total_samples);
    spike_count_all = cell(N_currents,1);
    vrest_by_epoch = cell(N_currents,1);
    vrest_mean = zeros(N_currents,1);

    for s=1:N_currents
        ind = find(all_currents == currents(s));
        N_epochs_per_current(s) = length(ind);
        example_traces(s,:) = epochs_in_dataset(ind(1)).raw_data;
        if N_epochs_per_current(s) > 1
            trace = mean(reshape([epochs_in_dataset(ind).raw_data], [], length(ind)), 2)';
            mean_traces(s,:) = trace;
        else
            trace = example_traces(s,:);
            mean_traces(s,:) = example_traces(s,:);
        end
       
        vrest_vector(s) = mean(trace(1:pre_samples));

        post_trace_mean = mean_traces(s,pre_samples+stim_samples+1:end);
        [minAmp, minTime] = min(post_trace_mean);
        ahp_amplitude(s) = minAmp - vrest_vector(s);
        ahp_time(s) = minTime / sample_rate;
        %do exponential fit here
        trace = post_trace_mean - vrest_vector(s);
        trace = trace / ahp_amplitude(s);
        trace = trace(minTime:end);
        x = (0:length(trace)-1) ./ sample_rate;
        beta_fit = nlinfit(x,trace,@double_exp_decay,[.2, 2, .5]);
        ahp_decay_tau1(s) = beta_fit(1);
        ahp_decay_tau2(s) = beta_fit(2);
        ahp_tau1_coeff(s) = beta_fit(3);
%         figure(1);
%         plot(x,trace,'k')
%         hold('on');
%         plot(x, double_exp_decay(beta_fit, x), 'r','LineWidth',2);
%         hold('off');
%         pause;

        spike_count_vec = zeros(N_epochs_per_current(s),1);
        vrest_by_epoch_vec = zeros(N_epochs_per_current(s),1);
        for i=1:N_epochs_per_current(s)
            sp = epochs_in_dataset(ind(i)).spike_indices;
            cur_trace = epochs_in_dataset(ind(i)).raw_data;
            spike_count_vec(i) = length(find(sp>pre_samples & sp<pre_samples+stim_samples));
            vrest_by_epoch_vec(i) = mean(cur_trace(1:pre_samples));
        end
        spike_count_all{s} = spike_count_vec;
        spike_count_mean(s) = mean(spike_count_vec);
        spike_count_sem(s) = std(spike_count_vec) ./ sqrt(N_epochs_per_current(s)-1);
        vrest_mean(s) = mean(vrest_by_epoch_vec);
        vrest_by_epoch{s} = vrest_by_epoch_vec;
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
    R.ahp_amplitude{d} = ahp_amplitude';
    R.ahp_time{d} = ahp_time';
    R.ahp_decay_tau1{d} = ahp_decay_tau1';
    R.ahp_decay_tau2{d} = ahp_decay_tau2';
    R.ahp_tau1_coeff{d} = ahp_tau1_coeff';
    R.spike_count_all{d} = spike_count_all;
    R.spike_count_mean{d} = spike_count_mean;
    R.spike_count_sem{d} = spike_count_sem;
    R.vrest_by_epoch{d} = vrest_by_epoch;
    R.vrest_mean{d} = vrest_mean';
    R.mean_traces{d} = mean_traces;
    R.example_traces{d} = example_traces;
    R.sample_rate(d) = sample_rate;

    fprintf('Elapsed time = %d seconds\n', round(toc));

end
