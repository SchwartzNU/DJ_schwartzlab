function R = Uncaging(data_group, params)
datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

post_time_ms = 100;
pre_time_ms = 50;

R = sln_results.table_definition_from_template('Uncaging',N_datasets);

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
        
    N_epochs = length(epochs_in_dataset);
    
    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;

    post_samples = round(post_time_ms*1E-3*sample_rate);
    pre_samples = round(pre_time_ms*1E-3*sample_rate);
   
    resting_vector = zeros(N_epochs,1);

    mean_traces = cell(N_stim_groups,1);
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
            error('Trigger upstrokes and downstrokes do not match');
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
                
                if set_id==1
                    mean_traces{z} = trace;
                    L = length(mean_traces{z});
                    time_axis{z} = ((1:L) - pre_samples) ./ sample_rate;
                else
                    L = min([length(mean_traces{z}), length(trace)]);
                    trace = trace(1:L);
                    mean_traces{z} = mean_traces{z}(1:L)+trace;
                    time_axis{z} = time_axis{z}(1:L);
                end                
                all_traces{z,set_id,i} = trace;

                %set_id
                % z                
                % plot(time_axis{z}, trace);
                % pause;


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

    % figure(2);
    % for z=1:N_stim_groups
    %     disp('mean');
    %     mean_traces{z} = mean_traces{z}./N_sets./N_epochs;
    %     hold('on');
    %     plot(time_axis{z}, mean_traces{z},'k');
    % end
    % hold('off');

    resting_potential_mean = mean(resting_vector);

    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;    
    R.n_epochs(d) = N_epochs;
    R.time_axis{d} = time_axis;
    R.traces_mean{d} = mean_traces;
    R.traces_all{d} = all_traces;
    R.resting_potential_mean(d) = resting_potential_mean;
    R.laser_power(d) = epochs_in_dataset(1).laser_power;
    R.laser_wavelength(d) = epochs_in_dataset(1).laser_wavelength;
    R.number_of_sequences(d) = epochs_in_dataset(1).number_of_sequences;
    R.number_of_stim_groups(d) = epochs_in_dataset(1).number_of_stim_groups;
    R.group_names{d} = epochs_in_dataset(1).group_names;
    R.drug_condition{d} = epochs_in_dataset(1).drug_condition;

    fprintf('Elapsed time = %d seconds\n', round(toc));
end


