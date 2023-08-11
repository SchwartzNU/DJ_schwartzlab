function R = IV_LightStep(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;
timeslices = params.timeslices;
N_timeslices = size(timeslices,1);

R = sln_results.table_definition_from_template('IV_LightStep',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.EpochParams('IvcUrve') * ...
        aka.BlockParams('IvcUrve') & ...
        datasets_struct(d),'*');
    N_epochs = length(epochs_in_dataset);

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

    all_vhold = round([epochs_in_dataset.hold_signal]);
    vholds = sort(unique(all_vhold));
    N_holds = length(vholds);

    N_epochs_per_hold = zeros(N_holds,1);
    peak_current_by_timeslice_mean = cell(N_timeslices,1);
    mean_current_by_timeslice_mean = cell(N_timeslices,1);
    peak_current_by_timeslice_sem = cell(N_timeslices,1);
    mean_current_by_timeslice_sem = cell(N_timeslices,1);
    
    holding_current_vector = zeros(N_holds,1);
    mean_traces = zeros(N_holds, total_samples);

    for h=1:N_holds
        ind = find(all_vhold == vholds(h));
        N_epochs_per_hold(h) = length(ind);
        mean_traces(h,:) = mean(reshape([epochs_in_dataset(ind).raw_data], [], length(ind)), 2)';
        holding_current_vector(h) = mean(mean_traces(h,1:pre_samples));
        %baseline subtraction
        mean_traces(h,:) = mean_traces(h,:) - holding_current_vector(h);

        for t=1:N_timeslices
            peak_current = zeros(N_epochs_per_hold(h),1);
            mean_current = zeros(N_epochs_per_hold(h),1);
            time_points = pre_samples + timeslices(t,1)*1E-3*sample_rate:pre_samples + timeslices(t,2)*1E-3*sample_rate; 
            for i=1:N_epochs_per_hold(h)
                peak_current(i) = max(mean_traces(h,time_points));
                mean_current(i) = mean(mean_traces(h,time_points));
            end
            peak_current_by_timeslice_mean{t}(h) = mean(peak_current);
            peak_current_by_timeslice_sem{t}(h) = std(peak_current) / sqrt(N_epochs_per_hold(h)-1);            
            mean_current_by_timeslice_mean{t}(h) = mean(mean_current);
            mean_current_by_timeslice_sem{t}(h) = std(mean_current) / sqrt(N_epochs_per_hold(h)-1);
        end
    end

    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.hold_voltages{d} = vholds';
    R.sample_rate(d) = sample_rate;
    R.pre_time_ms(d) = pre_stim_tail.pre_time;
    R.stim_time_ms(d) = pre_stim_tail.stim_time;
    R.tail_time_ms(d) = pre_stim_tail.tail_time;
    R.N_epochs_per_hold{d} = N_epochs_per_hold;
    R.timeslices{d} = timeslices;
    R.peak_current_by_timeslice_mean{d} = peak_current_by_timeslice_mean;
    R.mean_current_by_timeslice_mean{d} = mean_current_by_timeslice_mean;
    R.peak_current_by_timeslice_sem{d} = peak_current_by_timeslice_sem;
    R.mean_current_by_timeslice_sem{d} = mean_current_by_timeslice_sem;    
    R.mean_traces{d} = mean_traces;
    R.holding_current{d} = holding_current_vector;

    fprintf('Elapsed time = %d seconds\n', round(toc));
end


