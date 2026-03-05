function R = Ramp_analysis(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);



epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
    sln_symphony.ExperimentChannel * sln_symphony.SpikeTrain * ...
    sln_symphony.ExperimentEpochChannel * ...
    aka.BlockParams('Ramp') * aka.EpochParams('Ramp') ...
    & datasets_struct(2), '*');

sample_rate = epochs_in_dataset(1).sample_rate;
raw_data = vertcat(epochs_in_dataset.raw_data);
slope = epochs_in_dataset(1).ramp_slope;
increase_per_datapoint = slope / sample_rate;

pre_time = epochs_in_dataset(1).pre_time / 1000;
stim_time = epochs_in_dataset(1).stim_time / 1000;
tail_time = epochs_in_dataset(1).tail_time / 1000;


stimulus = zeros(size(raw_data,2), 1);
stim_temp = [0 : (stim_time * sample_rate) - 1] * increase_per_datapoint;
stimulus(pre_time * sample_rate : (pre_time + stim_time) * sample_rate - 1) = stim_temp;

resting_vm = mean(raw_data(:, 1:pre_time * sample_rate), 2);

figure;
subplot(2,1,1);
plot(raw_data');
subplot(2,1,2);
plot(stimulus);




end