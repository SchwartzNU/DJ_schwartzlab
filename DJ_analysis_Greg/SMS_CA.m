function R = SMS_CA(data_group, params)

datasets = aka.Dataset & data_group;
datasets_struct = fetch(datasets);
%all_epochs = aka.Epoch & data_group;
N_datasets = datasets.count;

R = table('Size',[N_datasets, 13], 'VariableNames', ...
    {'file_name', ...
    'dataset_name', ...
    'spot_sizes', ...
    'pre_time_ms', ...
    'stim_time_ms', ...
    'tail_time_ms', ...
    'N_epochs_per_size', ...
    'spikes_pre_mean', ...
    'spikes_stim_mean', ...
    'spikes_tail_mean', ...
    'spikes_stim_sem', ...
    'spikes_tail_sem', ...
    'baseline_rate_hz'...
    }, ...
    'VariableTypes', ...
    {'string', ...
    'string', ...
    'cell', ...
    'uint16', ...
    'uint16', ...
    'uint16', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'cell', ...
    'double'...
    });

for d=1:N_datasets
    tic;
    fprintf('Processing %d of %d, %s:%s\n', d, N_datasets, datasets_struct(d).file_name, datasets_struct(d).dataset_name);

    epochs_in_dataset = fetch(sln_symphony.DatasetEpoch * ...
        sln_symphony.ExperimentProtocolSpotsMultiSizeV1BlockParameters * ...
        sln_symphony.ExperimentProtocolSpotsMultiSizeV1EpochParameters & ...
        datasets_struct(d),'*');
    N_epochs = length(epochs_in_dataset);

    if N_epochs == 0
        error(sprintf('No epochs in dataset: %s', datasets_struct(d).dataset_name));
    end

    %parameters to save for the whole dataset
    %rstar_mean = epochs_in_dataset(1).rstar_mean;
    pre_stim_tail = struct('pre_time', epochs_in_dataset(1).pre_time, ...
        'stim_time', epochs_in_dataset(1).stim_time, ...
        'tail_time', epochs_in_dataset(1).tail_time);

    all_spot_sizes = round([epochs_in_dataset.cur_spot_size]);
    spot_sizes = sort(unique(all_spot_sizes));
    N_spot_sizes = length(spot_sizes);

    N_epochs_per_size = zeros(N_spot_sizes,1);
    spikes_pre_mean = zeros(N_spot_sizes,1);
    spikes_stim_mean = zeros(N_spot_sizes,1);
    spikes_tail_mean = zeros(N_spot_sizes,1);
    spikes_stim_sem = zeros(N_spot_sizes,1);
    spikes_tail_sem = zeros(N_spot_sizes,1);

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
        spikes_pre_mean(s) = mean(pre_spikes);
        spikes_stim_mean(s) = mean(stim_spikes);
        spikes_tail_mean(s) = mean(tail_spikes);
        spikes_stim_sem(s) = std(stim_spikes)./sqrt(N_epochs_per_size(s)-1);
        spikes_tail_sem(s) = std(tail_spikes)./sqrt(N_epochs_per_size(s)-1);
    end

    baseline_rate = mean(spikes_pre_mean) / (pre_stim_tail.pre_time / 1E3); %baseline rate in Hz

    %set table variables
    R.file_name(d) = datasets_struct(d).file_name;
    R.dataset_name(d) = datasets_struct(d).dataset_name;
    R.spot_sizes(d) = {spot_sizes};
    R.pre_time_ms(d) = pre_stim_tail.pre_time;
    R.stim_time_ms(d) = pre_stim_tail.stim_time;
    R.tail_time_ms(d) = pre_stim_tail.tail_time;
    R.N_epochs_per_size(d) = {N_epochs_per_size};
    R.spikes_pre_mean(d) = {spikes_pre_mean};
    R.spikes_stim_mean(d) = {spikes_stim_mean};
    R.spikes_tail_mean(d) = {spikes_tail_mean};
    R.spikes_stim_sem(d) = {spikes_stim_sem};
    R.spikes_tail_sem(d) = {spikes_tail_sem};
    R.baseline_rate_hz(d) = baseline_rate;
    fprintf('Elapsed time = %d seconds\n', toc);
end


%
% for i=1:length(paramsToSave)
%     if ~ismember(changing_fields, paramsToSave{i})
%         if isfield(protocol_params, paramsToSave{i})
%             R.(paramsToSave{i}) = protocol_params.(paramsToSave{i});
%         end
%     end
% end
%
% epoch_ids = dataset_struct.epoch_ids;
% N_epochs = length(epoch_ids);
%
% spotSize = zeros(N_epochs, 1);
%
% %setup key for finding results
% result_key.pipeline_name = pipeline;
% result_key.epoch_func_name = 'spikesInPreStimPost';
%
% %get all neccessary results and epoch parameters
% computedVals = struct;
% computedVals.spikeRatePre = zeros(N_epochs,1);
% computedVals.spikeRateStim = zeros(N_epochs,1);
% computedVals.spikeRatePost = zeros(N_epochs,1);
%
% for i=1:N_epochs
%     ep = sl.Epoch & dataset & sprintf('epoch_number=%d',epoch_ids(i));
%     if ~ep.exists
%         fprintf('Missing epoch %d', epoch_ids(i));
%         R = [];
%         return;
%     end
%
%     ep_struct = ep.fetch('*');
%     spotSize(i) = round(ep_struct.protocol_params.curSpotSize);
%
%     key = mergeStruct(ep_struct, result_key);
%     ep_result = getStoredResult('Epoch', key);
%
%     ep_result_R = ep_result.fetch1('result');
%     computedVals.spikeRatePre(i) = ep_result_R.preCount / ep_result_R.preDur;
%     computedVals.spikeRateStim(i) = ep_result_R.stimCount / ep_result_R.stimDur;
%     computedVals.spikeRatePost(i) = ep_result_R.tailCount / ep_result_R.tailDur;
% end
%
% computedVals.spikeRateStim_baselineSubtraced = computedVals.spikeRateStim - mean(computedVals.spikeRatePre);
% computedVals.spikeRatePost_baselineSubtraced = computedVals.spikeRatePost - mean(computedVals.spikeRatePre);
% outputStruct = distributeAndOrder(spotSize, computedVals);
% outputStruct = renameStructField(outputStruct, 'keyVals', 'spotSize');
% outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');
%
% %get SMS_PSTH
% Nsizes = length(outputStruct.spotSize);
% binSize = 10; %ms
%
% for j=1:Nsizes
%     [psth_x, psth_y] = psth(dataset_struct.cell_data, dataset_struct.epoch_ids(logical(outputStruct.key_ind(j,:))), binSize, [], [], [], dataset_struct.channel);
%     if j==1
%         Nbins = length(psth_x);
%         sms_psth = zeros(Nsizes, Nbins);
%         R.psth_x = psth_x;
%     end
%     sms_psth(j,:) = psth_y;
% end
% R.sms_psth = sms_psth;
%
% max_ON = abs(max(outputStruct.spikeRateStim_baselineSubtraced_mean));
% min_ON = abs(min(outputStruct.spikeRateStim_baselineSubtraced_mean));
% max_OFF = abs(max(outputStruct.spikeRatePost_baselineSubtraced_mean));
% min_OFF = abs(min(outputStruct.spikeRatePost_baselineSubtraced_mean));
%
% if max_ON > min_ON
%     %spike rate increase
%     outputStruct.response_norm_ON = outputStruct.spikeRateStim_baselineSubtraced_mean ./ max_ON;
%     [~, maxInd_ON] = max(outputStruct.response_norm_ON);
%     outputStruct.bestSize_ON = outputStruct.spotSize(maxInd_ON);
%     outputStruct.SI_ON = 1-outputStruct.response_norm_ON(end);
% else
%     %spike rate decrease
%    outputStruct.response_norm_ON = outputStruct.spikeRateStim_baselineSubtraced_mean ./ min_ON;
%    [~, minInd_ON] = min(outputStruct.response_norm_ON);
%    outputStruct.bestSize_ON = outputStruct.spotSize(minInd_ON);
%    outputStruct.SI_ON = 1-(-outputStruct.response_norm_ON(end));
% end
%
% if max_OFF > min_OFF
%    %spike rate increase
%     outputStruct.response_norm_OFF = outputStruct.spikeRatePost_baselineSubtraced_mean ./ max_OFF;
%     [~, maxInd_OFF] = max(outputStruct.response_norm_OFF);
%     outputStruct.bestSize_OFF = outputStruct.spotSize(maxInd_OFF);
%     outputStruct.SI_OFF = 1-outputStruct.response_norm_OFF(end);
% else
%    %spike rate decrease
%    outputStruct.response_norm_OFF = outputStruct.spikeRatePost_baselineSubtraced_mean ./ min_OFF;
%    [~, minInd_OFF] = min(outputStruct.response_norm_OFF);
%    outputStruct.bestSize_OFF = outputStruct.spotSize(minInd_OFF);
%    outputStruct.SI_OFF = 1-(-outputStruct.response_norm_OFF(end));
% end
%
% R = mergeStruct(R, outputStruct);
