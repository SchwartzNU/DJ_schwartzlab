function R = PostsynapticCurrent(data_group, params)
%POSTSYNAPTICCURRENT This function detect the EPSC (or IPSC for future) event of a voltage-clamp recording
% Detected synaptic current events can be saved in table sln_results.EpochPostsynapticCurrent, including their timing, peak amplitude, 
%and  parameters. 

%whether this analysis is for EPSC or IPSC and what is the detection threshold of amplitude
%unit: pA
if (isempty(params))
    psc_amp_threshold = -20;
    if_epsc = true;
else
    psc_amp_threshold = params.psc_amp_threshold;
    if_epsc = params.if_epsc;
end


epoch = aka.Epoch & data_group;
epoch_struct = fetch(epoch);
%note this works for channel 1 only. In the case of channel 2/left electrode, change here to be Amp2
epoch_struct.channel_name = 'Amp1';
R = sln_results.table_definition_from_template('PostsynapticCurrent', 1);

%only extract the trace data, does not deal with stimulus protocol 
epoch_data = fetch(sln_symphony.DatasetEpoch * sln_symphony.ExperimentChannel...
    *sln_symphony.ExperimentEpochChannel...
    & epoch_struct, '*');
%N_epoch = length(epochs_in_dataset);
fprintf('Processing epoch number %d..\n', epoch_data.epoch_id);

trace = epoch_data.raw_data;
trace = trace - mean(trace); %subtract the baseline
detection_success = 0; %a flag to suggest whether PSC detection algorithm succeds
if (if_epsc)
    %IMPORTANT: the detection parameters are here
    %change if the detection quality not good enough
    try
        [psc_params, decays] = detectPSPs(trace, 1, 'dataFilterLength', 50, 'derFilterLength', 5);
        detection_success = 1;
        %filtering out mini EPSC events by the amplitude threshold
        filter_index = psc_params(:, 1)<psc_amp_threshold;
    catch ME
        fprintf('Failed to detect any PSC in epoch %d\n', epoch_data.epoch_id);
    end

else
    try
        [psc_params, decays] = detectPSC(trace, 0,  'dataFilterLength', 50, 'derFilterLength', 5);
        detection_success = 1;
        %filtering for IPSC
        filter_index = psc_params(:, 1)>psc_amp_threshold;
    catch ME
        fprintf('Failed to detect any PSC in epoch %d\n', epoch_data.epoch_id);
    end

end

if (detection_success)
    filtered_pscs = psc_params(filter_index, :);
    [psc_N, ~] = size(filtered_pscs);

    fprintf('%d PSC detected in epoch %d\n', psc_N, epoch_data.epoch_id);
    R.file_name = epoch_struct.file_name;
    R.source_id = epoch_struct.source_id;
    R.epoch_id = epoch_data.epoch_id;
    R.psc_total = psc_N;
    R.sample_rate  = epoch_data.sample_rate;
    
    if (psc_N>0)
        R.psc_amplitude = zeros([1, psc_N]);
        R.psc_amplitude = transpose(filtered_pscs(:, 1));

        R.psc_start_ms = zeros( [1, psc_N]);
        start_times = filtered_pscs(:, 3)/epoch_data.sample_rate;
        R.psc_start_ms = transpose(start_times);

        R.psc_decay_ms = zeros([1, psc_N]);
        R.psc_decay_ms = transpose(filtered_pscs(:, 4)/epoch_data.sample_rate);

        R.psc_risetime_ms = zeros([1, psc_N]);
        R.psc_risetime_ms = transpose(filtered_pscs(:, 2));
    else
        R.psc_amplitude = nan;
        R.psc_start_ms = nan;
        R.psc_decay_ms = nan;
        R.psc_risetime_ms = nan;
    end
    
else
    fprintf('Skipping uploading PSC. \n');
end

end

