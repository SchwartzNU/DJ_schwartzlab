function R = SMS_spike_analysis(dataset, pipeline, P)

R = []; %will be struct. error if isempty
dataset_struct = dataset.fetch('*');

if ~strcmp(dataset_struct.dataset_protocol_name, 'Spots Multi Size') && ~strcmp(dataset_struct.dataset_protocol_name,'Spots Multiple Sizes')
    disp('Error: SMS_spike_analysis designed for datasets of type: Spots Multi Size');
    return;
end

paramsToSave = {'RstarMean', ...
    'RstarIntensity1'};

[protocol_params, changing_fields] = getExampleProtocolParametersForEpochInDataset(dataset_struct.cell_id, dataset_struct.dataset_name);
for i=1:length(paramsToSave)
    if ~ismember(changing_fields, paramsToSave{i})
        if isfield(protocol_params, paramsToSave{i})
            R.(paramsToSave{i}) = protocol_params.(paramsToSave{i});
        end
    end
end

epoch_ids = dataset_struct.epoch_ids;
N_epochs = length(epoch_ids);

spotSize = zeros(N_epochs, 1);

%setup key for finding results
result_key.pipeline_name = pipeline;
result_key.epoch_func_name = 'spikesInPreStimPost';

%get all neccessary results and epoch parameters
computedVals = struct;
computedVals.spikeRatePre = zeros(N_epochs,1);
computedVals.spikeRateStim = zeros(N_epochs,1);
computedVals.spikeRatePost = zeros(N_epochs,1);

for i=1:N_epochs
    ep = sl.Epoch & dataset & sprintf('epoch_number=%d',epoch_ids(i));
    if ~ep.exists
        fprintf('Missing epoch %d', epoch_ids(i)); 
        R = [];
        return;
    end
    
    ep_struct = ep.fetch('*');
    spotSize(i) = round(ep_struct.protocol_params.curSpotSize);
    
    key = mergeStruct(ep_struct, result_key);
    ep_result = getStoredResult('Epoch', key);
 
    ep_result_R = ep_result.fetch1('result');
    computedVals.spikeRatePre(i) = ep_result_R.preCount / ep_result_R.preDur;
    computedVals.spikeRateStim(i) = ep_result_R.stimCount / ep_result_R.stimDur;
    computedVals.spikeRatePost(i) = ep_result_R.tailCount / ep_result_R.tailDur;    
end

computedVals.spikeRateStim_baselineSubtraced = computedVals.spikeRateStim - mean(computedVals.spikeRatePre);
computedVals.spikeRatePost_baselineSubtraced = computedVals.spikeRatePost - mean(computedVals.spikeRatePre);
outputStruct = distributeAndOrder(spotSize, computedVals);
outputStruct = renameStructField(outputStruct, 'keyVals', 'spotSize');
outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');

max_ON = abs(max(outputStruct.spikeRateStim_baselineSubtraced_mean));
min_ON = abs(min(outputStruct.spikeRateStim_baselineSubtraced_mean));
max_OFF = abs(max(outputStruct.spikeRatePost_baselineSubtraced_mean));
min_OFF = abs(min(outputStruct.spikeRatePost_baselineSubtraced_mean));

if max_ON > min_ON
    %spike rate increase
    outputStruct.response_norm_ON = outputStruct.spikeRateStim_baselineSubtraced_mean ./ max_ON;
    [~, maxInd_ON] = max(outputStruct.response_norm_ON);
    outputStruct.bestSize_ON = outputStruct.spotSize(maxInd_ON);
    outputStruct.SI_ON = 1-outputStruct.response_norm_ON(end);
else
    %spike rate deccrease
   outputStruct.response_norm_ON = outputStruct.spikeRateStim_baselineSubtraced_mean ./ min_ON;
   [~, minInd_ON] = min(outputStruct.response_norm_ON);
   outputStruct.bestSize_ON = outputStruct.spotSize(minInd_ON);
   outputStruct.SI_ON = 1-(-outputStruct.response_norm_ON(end));
end

if max_OFF > min_OFF
   %spike rate increase
    outputStruct.response_norm_OFF = outputStruct.spikeRatePost_baselineSubtraced_mean ./ max_OFF;
    [~, maxInd_OFF] = max(outputStruct.response_norm_OFF);
    outputStruct.bestSize_OFF = outputStruct.spotSize(maxInd_OFF);
    outputStruct.SI_OFF = 1-outputStruct.response_norm_OFF(end);
else
   %spike rate deccrease
   outputStruct.response_norm_OFF = outputStruct.spikeRatePost_baselineSubtraced_mean ./ min_OFF;
   [~, minInd_OFF] = min(outputStruct.response_norm_OFF);
   outputStruct.bestSize_OFF = outputStruct.spotSize(minInd_OFF);
   outputStruct.SI_OFF = 1-(-outputStruct.response_norm_OFF(end));
end

R = mergeStruct(R, outputStruct);
