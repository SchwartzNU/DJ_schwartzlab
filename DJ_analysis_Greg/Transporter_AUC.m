function R = Transporter_AUC(data_group, params)
    %load(data);
    example = 1;
    %% Load Data 
    
    datasets = aka.Dataset * sln_symphony.ExperimentCell & proj(data_group);
    datasets_struct = fetch(datasets,'cell_number');
    N_datasets = datasets.count;
    
    %R = sln_results.table_definition_from_template('PulseLong',N_datasets);
    
    for d=1:N_datasets
        %% 
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
        stim_end_time = (pre_samples+stim_samples) / sample_rate;
        stim_end_idx = round(stim_end_time * sample_rate);
    
        %initialize variables as 0
        N_epochs_per_current = zeros(N_currents,1);
        ahp_amplitude = zeros(N_currents,1);
        ahp_time = zeros(N_currents,1);
        spike_count_mean = zeros(N_currents,1);
        spike_count_sem = zeros(N_currents,1);
        ahp_decay_tau1 = zeros(N_currents,1);
        ahp_decay_tau2 = zeros(N_currents,1);
        ahp_tau1_coeff = zeros(N_currents,1);
        mean_traces = zeros(N_currents, total_samples);
        %example_traces = zeros(N_currents, total_samples);
        spike_count_all = cell(N_currents,1);
        vrest_by_epoch = cell(N_currents,1);
        vrest_mean = zeros(N_currents,1);
        ahp_areas =  cell(N_currents,1); %This has a different value for each epoch
        spike_counts = cell(N_currents,1);
        auc_sp_ratios = cell(N_currents,1);
     %% Loop over currents 
        for s=1:N_currents
            %example_traces = zeros(s, total_samples);
            %s=1
            %s=2; %For now!
            ind = find(all_currents == currents(s));
            N_epochs_per_current(s) = length(ind);
            %example_traces(s,:) = epochs_in_dataset(ind(1)).raw_data;
            ahp_areas{s} = zeros(1, length(ind));
            spike_counts{s} = zeros(1, length(ind));
            auc_sp_ratios{s} = zeros(1, length(ind));
            ahp_amplitudes{s} = zeros(1, length(ind));

            %Setup example variables
            data_length = length(epochs_in_dataset(ind(1)).raw_data);
            example_traces(s,1:data_length) = epochs_in_dataset(ind(example)).raw_data;
            vrest_example(s,:) = mean(example_traces(1:pre_samples));
            example_sp(s,1:length(epochs_in_dataset(ind(example)).spike_indices)) = epochs_in_dataset(ind(example)).spike_indices;
            example_spike_count(s,:) = length(find(example_sp>pre_samples & example_sp<pre_samples+stim_samples));
            example_segment(s,1:length(example_traces(s,stim_end_idx:end))) = example_traces(s,stim_end_idx:end);
            size(example_segment)
            %size(vrest_example)
            example_diff(s,1:length(example_segment)) = example_segment(s,:) - vrest_example(s,:);
            example_diff(example_diff > 0) = 0;
            example_ahp(s) = sum(example_diff(s,:))/sample_rate;
            for i = 1:N_epochs_per_current(s)
                %i=1
            %if N_epochs_per_current(s) > 1
                %trace data
             
                %trace = mean(reshape([epochs_in_dataset(ind(i)).raw_data], [], length(ind(1))), 2)';
                %mean_traces(s,:) = trace;
                trace = epochs_in_dataset(ind(i)).raw_data;
                vrest = mean(trace(1:pre_samples));
                
                %stim_end_idx = round(stim_end_time * sample_rate);
                %segment_length = length(trace(stim_end_idx:end));
                %vrest_line = vrest * ones(1,segment_length);
                %x = (0:length(trace)-1) ./ sample_rate; %Transform indices to actual time
                
                %spikes data
                sp = epochs_in_dataset(ind(i)).spike_indices;
                spike_count = length(find(sp>pre_samples & sp<pre_samples+stim_samples));
                
                %ahp calculations
                trace_segment = trace(stim_end_idx:end);
                %differences = -1*(vrest_line - trace_segment); %Just cause Vm is negative
                differences = trace_segment - vrest;
                differences(differences > 0) = 0;
                ahp_area = sum(differences) / sample_rate;
                auc_sp_ratio = ahp_area/spike_count;
                [minAmp, minTime] = min(trace_segment);
                %ahp_amplitude(s) = minAmp - vrest_line;
                ahp_amplitude = minAmp;
                ahp_time(s) = stim_end_time + (minTime / sample_rate);
                
                %Results to save
                ahp_areas{s}(i) = ahp_area;
                spike_counts{s}(i) = spike_count;
                auc_sp_ratios{s}(i)= auc_sp_ratio;
                ahp_amplitudes{s}(i) = ahp_amplitude;
               
    
            end
    
    
        end
        %example_traces = epochs_in_dataset(ind(end)).raw_data;
     %set table variables
        R.file_name{d} = datasets_struct(d).file_name;
        R.dataset_name{d} = datasets_struct(d).dataset_name;
        R.source_id(d) = datasets_struct(d).source_id;
        R.inj_current{d} = currents';
        R.pre_time_ms(d) = pre_stim_tail.pre_time;
        R.stim_time_ms(d) = pre_stim_tail.stim_time;
        R.n_epochs_per_current{d} = N_epochs_per_current;
        R.ahp_areas{d} = ahp_areas;
        R.spike_counts{d} = spike_counts;
        R.auc_sp_ratios{d} = auc_sp_ratios;
        R.ahp_amplitude{d} = ahp_amplitudes';
        R.stim_end_idx{d} = stim_end_idx;
    
        R.sample_rate(d) = sample_rate;
        R.example_traces = example_traces;
        R.vrest_example = vrest_example; 
        R.example_sp = example_sp; 
        R.example_spike_count = example_spike_count;
        R.example_segment = example_segment; 
        R.example_diff = example_diff; 
        R.example_ahp = example_ahp;
        R.stim_end_time = stim_end_time;
    
        %R.vrest(d) = vrest; %will set up for the example trace for the plotter
        
        %R.ahp_time{d} = ahp_time';
        %R.ahp_decay_tau1{d} = ahp_decay_tau1';
        %R.ahp_decay_tau2{d} = ahp_decay_tau2';
        %R.ahp_tau1_coeff{d} = ahp_tau1_coeff';
        
        %R.vrest_by_epoch{d} = vrest_by_epoch;
        %R.vrest_mean{d} = vrest_mean';
        %R.mean_traces{d} = mean_traces;
        %R.example_traces{d} = example_traces;
    
        fprintf('Elapsed time = %d seconds\n', round(toc));
    
    
    end
