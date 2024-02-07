function R = SMS_CC(data_group, params)

%could be a param
response_std_thres = 3;

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('SMSCC',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...        
        aka.SMSparams & ...
        'channel_name="Amp1"' & ...
        datasets_struct(d),'*');

    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0 %try SpotsMultiSizeClassify instead... weird insert error
        epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
            sln_symphony.ExperimentChannel * ...
            sln_symphony.ExperimentEpochChannel * ...
            sln_symphony.ExperimentProtSpotsMultiSizeClassifyV1ep * sln_symphony.ExperimentProtSpotsMultiSizeClassifyV1bp & ...
        datasets_struct(d),'*');

        N_epochs = length(epochs_in_dataset);
    end
    
    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;

    %rstar_mean = epochs_in_dataset(1).rstar_mean;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    pre_samples = sample_rate * (pre_stim_tail.pre_time / 1E3);
    stim_samples = sample_rate * (pre_stim_tail.stim_time / 1E3);
    tail_samples = sample_rate * (pre_stim_tail.tail_time / 1E3);
    total_samples = pre_samples + stim_samples + tail_samples;

    all_spot_sizes = round([epochs_in_dataset.cur_spot_size]);
    spot_sizes = sort(unique(all_spot_sizes));
    N_spot_sizes = length(spot_sizes);

    N_epochs_per_size = zeros(N_spot_sizes,1);
    peak_stim_mean = zeros(N_spot_sizes,1);
    peak_tail_mean = zeros(N_spot_sizes,1);
    peak_stim_sem = zeros(N_spot_sizes,1);
    peak_tail_sem = zeros(N_spot_sizes,1);
    spikes_pre_mean = zeros(N_spot_sizes,1);
    spikes_stim_mean = zeros(N_spot_sizes,1);
    spikes_tail_mean = zeros(N_spot_sizes,1);
    spikes_stim_sem = zeros(N_spot_sizes,1);
    spikes_tail_sem = zeros(N_spot_sizes,1);
    response_duration_stim = zeros(N_spot_sizes,1);
    response_duration_tail = zeros(N_spot_sizes,1);
    peak_resp_stim = zeros(N_spot_sizes,1);
    peak_time_stim = zeros(N_spot_sizes,1);
    peak_resp_tail = zeros(N_spot_sizes,1);
    peak_time_tail = zeros(N_spot_sizes,1);

    resting_vector = zeros(N_spot_sizes,1);
    mean_traces = zeros(N_spot_sizes, total_samples);
    example_traces = zeros(N_spot_sizes, total_samples);

    for s=1:N_spot_sizes
        ind = find(all_spot_sizes == spot_sizes(s));
        N_epochs_per_size(s) = length(ind);
        mean_traces(s,:) = mean(reshape([epochs_in_dataset(ind).raw_data], [], length(ind)), 2)';
        example_traces(s,:) = epochs_in_dataset(ind(1)).raw_data;

        resting_vector(s) = mean(mean_traces(s,1:pre_samples));

        pre_spikes = zeros(N_epochs_per_size(s),1);
        stim_spikes = zeros(N_epochs_per_size(s),1);
        tail_spikes = zeros(N_epochs_per_size(s),1);
        
        peak_stim = zeros(N_epochs_per_size(s),2);
        peak_tail = zeros(N_epochs_per_size(s),2);
        for i=1:N_epochs_per_size(s)
            trace = epochs_in_dataset(ind(i)).raw_data;
            baseline = mean(trace(1:pre_samples));
            trace_baseline_subtraced = trace - baseline;
            
            peak_stim(i,1) = min(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples));
            peak_stim(i,2) = max(trace_baseline_subtraced(pre_samples+1:pre_samples+stim_samples));
            peak_tail(i,1) = min(trace_baseline_subtraced(pre_samples+stim_samples+1:total_samples));
            peak_tail(i,2) = max(trace_baseline_subtraced(pre_samples+stim_samples+1:total_samples));            
       end
        if abs(mean(peak_stim(:,1))) > abs(mean(peak_stim(:,2)))
            peak_stim_mean(s) = mean(peak_stim(:,1));
            peak_stim_sem(s) = std(peak_stim(:,1)) ./ sqrt(N_epochs_per_size(s)-1);
        else
            peak_stim_mean(s) = mean(peak_stim(:,2));
            peak_stim_sem(s) = std(peak_stim(:,2)) ./ sqrt(N_epochs_per_size(s)-1);
        end
        if abs(mean(peak_tail(:,1))) > abs(mean(peak_tail(:,2)))
            peak_tail_mean(s) = mean(peak_tail(:,1));
            peak_tail_sem(s) = std(peak_tail(:,1)) ./ sqrt(N_epochs_per_size(s)-1);
        else
            peak_tail_mean(s) = mean(peak_tail(:,2));
            peak_tail_sem(s) = std(peak_tail(:,2)) ./ sqrt(N_epochs_per_size(s)-1);
        end

        %get durations
        baseline_std = std(mean_traces(s,1:pre_samples));
        stim_trace = mean_traces(s,pre_samples+1:pre_samples+stim_samples);
        tail_trace = mean_traces(s,pre_samples+stim_samples+1:end);
        %baseline subtraction
        stim_trace = stim_trace - mean(mean_traces(s,1:pre_samples)); 
        tail_trace = tail_trace - mean(mean_traces(s,1:pre_samples));

        %stim trace
        if abs(max(stim_trace)) > abs(min(stim_trace)) %positive peak
            %flip_trace = false;
        else %flip it and add negative at the end
            %flip_trace = true;
            stim_trace = -stim_trace;
        end
        
        [peak_resp_stim(s), peak_time_stim_samples] = max(stim_trace);
        if peak_resp_stim(s) > response_std_thres * baseline_std %crosses threshold
            peak_time_stim(s) = peak_time_stim_samples / sample_rate;                
            peak_to_end_trace = stim_trace(peak_time_stim_samples:end);
            drop_time = getThresCross(peak_to_end_trace, peak_resp_stim(s) / 2, -1);
            if isempty(drop_time)
                response_duration_stim(s) = stim_samples / sample_rate;
            else
                drop_time = drop_time(1); %get first one
                response_duration_stim(s) = drop_time / sample_rate;
            end
        else
            peak_resp_stim(s) = nan;
            peak_time_stim(s) = nan;
            response_duration_stim(s) = nan;
        end

        %tail trace
        if abs(max(tail_trace)) > abs(min(tail_trace)) %positive peak
            %flip_trace = false;
        else %flip it and add negative at the end
            %flip_trace = true;
            tail_trace = -tail_trace;
        end
        
        [peak_resp_tail(s), peak_time_tail_samples] = max(tail_trace);
        if peak_resp_tail(s) > response_std_thres * baseline_std %crosses threshold
            peak_time_tail(s) = peak_time_tail_samples / sample_rate;                
            peak_to_end_trace = tail_trace(peak_time_tail_samples:end);
            drop_time = getThresCross(peak_to_end_trace, peak_time_tail(s) / 2, -1);
            if isempty(drop_time)
                response_duration_tail(s) = tail_samples / sample_rate;
            else
                drop_time = drop_time(1); %get first one
                response_duration_tail(s) = drop_time / sample_rate;
            end
        else
            peak_resp_tail(s) = nan;
            peak_time_tail(s) = nan;
            response_duration_tail(s) = nan;
        end

        %get spikes
        spike_query = sln_symphony.SpikeTrain & epochs_in_dataset(ind);
        if spike_query.exists
            for i=1:N_epochs_per_size(s)
                pre_spikes(i) = spikes_in_interval(epochs_in_dataset(ind(i)),pre_stim_tail,'pre');
                stim_spikes(i) = spikes_in_interval(epochs_in_dataset(ind(i)),pre_stim_tail,'stim');
                tail_spikes(i) = spikes_in_interval(epochs_in_dataset(ind(i)),pre_stim_tail,'tail');
            end
            spikes_pre_mean(s) = mean(pre_spikes);
            spikes_stim_mean(s) = mean(stim_spikes);
            spikes_tail_mean(s) = mean(tail_spikes);
            spikes_stim_sem(s) = std(stim_spikes)./sqrt(N_epochs_per_size(s)-1);
            spikes_tail_sem(s) = std(tail_spikes)./sqrt(N_epochs_per_size(s)-1);
        end                
    end

    baseline_rate = mean(spikes_pre_mean) / (pre_stim_tail.pre_time / 1E3); %baseline rate in Hz

    resting_potential_mean = mean(resting_vector);

    %set table variables
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
    R.spikes_stim_mean{d} = spikes_stim_mean;
    R.spikes_tail_mean{d} = spikes_tail_mean;
    R.spikes_stim_sem{d} = spikes_stim_sem;
    R.spikes_tail_sem{d} = spikes_tail_sem;
    R.response_duration_stim{d} = response_duration_stim;
    R.response_duration_tail{d} = response_duration_tail;
    R.response_peak_time_stim{d} = peak_time_stim;
    R.response_peak_time_tail{d} = peak_time_tail;
    R.mean_traces{d} = mean_traces;
    R.example_traces{d} = example_traces;
    R.resting_potential_mean(d) = resting_potential_mean;
    R.baseline_rate_hz(d) = baseline_rate;

    fprintf('Elapsed time = %d seconds\n', round(toc));
end


