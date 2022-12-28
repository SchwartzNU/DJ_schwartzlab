function R = MultiPulse_FIcurve(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('MultiPulse_FIcurve',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.SpikeTrain * ...
        sln_symphony.ExperimentEpochChannel * ...
        aka.MPparams & ...
        datasets_struct(d),'*');
    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    %parameters to save for the whole dataset
    sample_rate = epochs_in_dataset(1).sample_rate;
    all_currents = round([epochs_in_dataset.pulse_1_curr]);
    currents  = sort(unique(all_currents));
    N_currents = length(currents);

    N_epochs_per_current = zeros(N_currents,1);
    FR_per_current_mean = zeros(N_currents,1);  
    FR_per_current_sem = zeros(N_currents,1);   
    
    %assume consistent pre and stim time
    pre_time = epochs_in_dataset(1).pre_time / 1E3; %s
    stim_time = epochs_in_dataset(1).stim_1_time / 1E3; %s
            
    for s=1:N_currents
        ind = find(all_currents == currents(s));
        N_epochs_per_current(s) = length(ind);
        
        Nspikes = zeros(1,N_epochs_per_current(s));
        FR = zeros(1,N_epochs_per_current(s));

        for i=1:N_epochs_per_current(s)
            sp = double(epochs_in_dataset(ind(i)).spike_indices) ./ sample_rate; %s
            Nspikes(i) = length(find(sp>pre_time & sp <= pre_time + stim_time));
            FR(i) = Nspikes(i) / stim_time;
        end
        FR_per_current_mean(s) = mean(FR);
        FR_per_current_sem(s) = std(FR) / sqrt(N_epochs_per_current(s) -1);
    end

    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name{d} = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.inj_current{d} = currents';
    R.stim_time_s(d) = stim_time;
    R.n_epochs_per_current{d} = N_epochs_per_current;
    R.FR_per_current_mean{d} = FR_per_current_mean;
    R.FR_per_current_sem{d} = FR_per_current_sem;

    fprintf('Elapsed time = %d seconds\n', round(toc));
end
