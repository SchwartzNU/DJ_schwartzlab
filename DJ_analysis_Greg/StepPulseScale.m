function R = StepPulseScale(datagroup, params)

datasets = aka.Dataset & datagroup;

datasets_struct = fetch(datasets);
N_dataset = datasets.count;

R = sln_results.table_definition_from_template('StepPulseScale', N_dataset);

for d = 1: N_dataset
    tic;
    fprintf('Processing %d of %d, %s_sourceid%d:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).source_id, datasets_struct(d).dataset_name);
    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentChannel * ...
        sln_symphony.ExperimentEpochChannel * ...        
        sln_symphony.SpikeTrain * ...
        aka.EpochParams('StepPulseScale') * aka.BlockParams('StepPulseScale') & ...
        'channel_name="Amp1"' & ...
        datasets_struct(d),'*');

    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error('No epochs in dataset: %s', datasets_struct(d).dataset_name);
    end

    sample_rate = epochs_in_dataset(1).sample_rate;
    tail_time = epochs_in_dataset.adjusted_tail_time;
    pre_time = epochs_in_dataset(1).pre_time;
    stim_time = epochs_in_dataset.scale_stim_time;
    amplitude = epochs_in_dataset.scaled_amplitude;



end
end