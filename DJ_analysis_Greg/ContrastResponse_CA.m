function R = ContrastResponse_CA(data_group, params)
if nargin < 2
    binSize = 10;
else
    binSize = params.binSize;
end

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
N_datasets = datasets.count;

R = sln_results.table_definition_from_template('ContrastResponse_CA',N_datasets);

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);

    epochs_in_dataset_table = sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentEpoch & ...
        datasets_struct(d);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        aka.ContrastResponseParams & ...
        datasets_struct(d),'*');

    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    %parameters to save for the whole dataset
    %rstar_mean = epochs_in_dataset(1).rstar_mean;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);
    total_ms = pre_stim_tail.pre_time + pre_stim_tail.stim_time + pre_stim_tail.tail_time;
    psth_length = ceil(total_ms/binSize);

    all_spot_sizes = round([epochs_in_dataset.cur_spot_size]);
    spot_sizes = sort(unique(all_spot_sizes));
    N_spot_sizes = length(spot_sizes);

    N_epochs_per_size = zeros(N_spot_sizes,1);
    spikes_pre_mean = zeros(N_spot_sizes,1);
    spikes_stim_mean = zeros(N_spot_sizes,1);
    spikes_tail_mean = zeros(N_spot_sizes,1);
    spikes_stim_sem = zeros(N_spot_sizes,1);
    spikes_tail_sem = zeros(N_spot_sizes,1);
    sms_psth = zeros(N_spot_sizes,psth_length);

    for s=1:N_spot_sizes
        ind = find(all_spot_sizes == spot_sizes(s));
        N_epochs_per_size(s) = length(ind);
        pre_spikes = zeros(N_epochs_per_size(s),1);
        stim_spikes = zeros(N_epochs_per_size(s),1);
        tail_spikes = zeros(N_epochs_per_size(s),1);
        for i=1:N_epochs_per_size(s)
            pre_spikes(i) = spikes_in_interval(epochs_in_dataset(ind(i)),pre_stim_tail,'pre');
            stim_spikes(i) = spikes_in_interval(epochs_in_dataset(ind(i)),pre_stim_tail,'stim');
            tail_spikes(i) = spikes_in_interval(epochs_in_dataset(ind(i)),pre_stim_tail,'tail');
        end
        if s==1
            [psth_x, sms_psth(s,:)] = psth_for_epochs(epochs_in_dataset_table & epochs_in_dataset(ind), binSize);
        else
            [~, sms_psth(s,:)] = psth_for_epochs(epochs_in_dataset_table & epochs_in_dataset(ind), binSize);
        end
        spikes_pre_mean(s) = mean(pre_spikes);
        spikes_stim_mean(s) = mean(stim_spikes);
        spikes_tail_mean(s) = mean(tail_spikes);
        spikes_stim_sem(s) = std(stim_spikes)./sqrt(N_epochs_per_size(s)-1);
        spikes_tail_sem(s) = std(tail_spikes)./sqrt(N_epochs_per_size(s)-1);
    end

    baseline_rate = mean(spikes_pre_mean) / (pre_stim_tail.pre_time / 1E3); %baseline rate in Hz

    %set table variables
    R.file_name{d} = datasets_struct(d).file_name;
    R.dataset_name(d) = datasets_struct(d).dataset_name;
    R.source_id(d) = datasets_struct(d).source_id;
    R.spot_sizes{d} = spot_sizes';
    R.pre_time_ms(d) = pre_stim_tail.pre_time;
    R.stim_time_ms(d) = pre_stim_tail.stim_time;
    R.tail_time_ms(d) = pre_stim_tail.tail_time;
    R.n_epochs_per_size{d} = N_epochs_per_size;
    R.spikes_pre_mean{d} = spikes_pre_mean;
    R.spikes_stim_mean{d} = spikes_stim_mean;
    R.spikes_tail_mean{d} = spikes_tail_mean;
    R.spikes_stim_sem{d} = spikes_stim_sem;
    R.spikes_tail_sem{d} = spikes_tail_sem;
    R.sms_psth{d} = sms_psth;
    R.psth_x{d} = psth_x;
    R.baseline_rate_hz(d) = baseline_rate;
    fprintf('Elapsed time = %d seconds\n', round(toc));
end


