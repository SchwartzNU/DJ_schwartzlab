function R = Uncaging(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

post_time_ms = 100;
pre_time_ms = 50;

R = sln_results.table_definition_from_template('Uncaging',N_datasets);

if nargin<2 || isempty(params)
    integration_time = 60; %ms
end

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.EpochParams('Uncaging') * ...
        aka.BlockParams('Uncaging') & ...
        'channel_name="Amp1"' & ...
        datasets_struct(d),'*');

    N_sets = epochs_in_dataset(1).number_of_sequences;
    N_stim_groups = epochs_in_dataset(1).number_of_stim_groups;
    if epochs_in_dataset(1).shutter_open
        shutter_open = 'T';
    else
        shutter_open = 'F';
    end
        
    N_epochs = length(epochs_in_dataset);
    
    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;

    post_samples = round(post_time_ms*1E-3*sample_rate);
    pre_samples = round(pre_time_ms*1E-3*sample_rate);
   
    resting_vector = zeros(N_epochs,1);

    all_traces = cell(N_stim_groups,N_sets,N_epochs);

    for i=1:N_epochs
        fprintf('Epoch: %d\n', i);
        s.file_name = epochs_in_dataset(i).file_name;
        s.source_id = epochs_in_dataset(i).source_id;
        s.epoch_id = epochs_in_dataset(i).epoch_id;
        
        s_amp = s;
        s_amp.channel_name = 'Amp1';

        s_trig = s;
        s_trig.channel_name = 'PstimTrigger';

        amp_data = fetch1(sln_symphony.ExperimentEpochChannel & s_amp, 'raw_data');
        trig_data = fetch1(sln_symphony.ExperimentEpochChannel & s_trig, 'raw_data');
        
        trig_UP = getThresCross(trig_data,2.5,1);
        trig_DOWN = getThresCross(trig_data,2.5,-1);

        if length(trig_UP) ~= length(trig_DOWN)
            disp('Trigger upstrokes and downstrokes do not match');
            disp('This may be a stupid ScanImage bug');
            disp('So implementing a crappy hack to fix it for now');
            first_diff = trig_DOWN(1) - trig_UP(1);
            trig_DOWN(end+1) = trig_UP(end)+first_diff;
        end

        if isempty(trig_UP)
            disp('Skipping epochs with no trigger pulses');
        else
            N_trig = length(trig_UP);
            %N_sets = floor(N_trig/N_stim_groups);

            t=1;
            z=1;
            set_id = 1;
            resting_vector(i) = mean(amp_data(trig_UP(t)-pre_samples-sample_rate/2:trig_UP(t)-pre_samples));

            while t <= N_trig
                interval = trig_UP(t)-pre_samples:trig_DOWN(t)+post_samples;
                trace = amp_data(interval);              
                baseline = mean(trace(1:pre_samples-1));
                trace = trace - baseline;
               
                all_traces{z,set_id,i} = trace;

                t=t+1;
                if z==N_stim_groups
                    z=1;
                    set_id = set_id+1;
                else
                    z=z+1;
                end
            end
        end
    end
    N_trials = N_sets*N_epochs;
    all_traces_flattened = reshape(all_traces,[N_stim_groups,N_trials]);
    %fix tiny size mismatches
    
    for i=1:N_stim_groups
        for j=1:N_trials
            if length(all_traces_flattened{i,j}) == 0;
                L_mat(i,j) = nan;
            else
                L_mat(i,j) = length(all_traces_flattened{i,j});
            end
        end
    end
    
    L = min(L_mat,[],2);
    for i=1:N_stim_groups
        for j=1:N_trials
            if ~isempty(all_traces_flattened{i,j})
                all_traces_flattened{i,j} = all_traces_flattened{i,j}(1:L(i));
            end
        end
    end
    for i=1:N_stim_groups
        time_axis{i} = ((1:L(i)) - pre_samples) ./ sample_rate;
        time_ind = time_axis{i} >=0 & time_axis{i} <= integration_time/1E3;
        response_matrix = cell2mat(all_traces_flattened(i,:)');
        traces_mean{i} = mean(response_matrix,1);
        peak_by_trial = max(response_matrix(:,time_ind),[],2);
        integral_by_trial = sum(response_matrix(:,time_ind),2) / sample_rate / (integration_time/1E3);        
        trial_integrated_resp_mean(i) = mean(integral_by_trial);
        trial_integrated_resp_sem(i) = std(integral_by_trial) ./ sqrt(N_trials-1);
        trial_peak_resp_mean(i) = mean(peak_by_trial);
        trial_peak_resp_sem(i) = std(peak_by_trial) ./ sqrt(N_trials-1);
        peak_resp(i) = max(traces_mean{i}(time_ind));
        integrated_resp(i) = sum(traces_mean{i}(time_ind)) / sample_rate / (integration_time/1E3);        
    end

    resting_potential_mean = mean(resting_vector);

    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;    
    R.n_epochs(d) = N_epochs;
    R.time_axis{d} = time_axis;
    R.traces_mean{d} = traces_mean;
    R.traces_all{d} = all_traces;
    R.resting_potential_mean(d) = resting_potential_mean;
    R.laser_power(d) = epochs_in_dataset(1).laser_power;
    R.laser_wavelength(d) = epochs_in_dataset(1).laser_wavelength;
    R.shutter_open{d} = shutter_open;
    R.number_of_sequences(d) = epochs_in_dataset(1).number_of_sequences;
    R.number_of_stim_groups(d) = epochs_in_dataset(1).number_of_stim_groups;
    R.group_names{d} = epochs_in_dataset(1).group_names;
    R.drug_condition{d} = epochs_in_dataset(1).drug_condition;
    R.trial_peak_resp_mean{d} = trial_peak_resp_mean;
    R.trial_peak_resp_sem{d} = trial_peak_resp_sem;
    R.peak_resp{d} = peak_resp;
    R.trial_integrated_resp_mean{d} = trial_integrated_resp_mean;
    R.trial_integrated_resp_sem{d} = trial_integrated_resp_sem;
    R.integrated_resp{d} = integrated_resp;

    fprintf('Elapsed time = %d seconds\n', round(toc));
end


