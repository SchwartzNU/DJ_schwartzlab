function R = MovingBar_spike_analysis(dataset, pipeline, P)

R = []; %will be struct. error if isempty
dataset_struct = dataset.fetch('*');

if ~strcmp(dataset_struct.dataset_protocol_name, 'Moving Bar')
    disp('Error: MovingBar_spike_analysis designed for datasets of type: Moving Bar');
    return;
end

paramsToSave = {'barLength', ...
    'barSpeed',...
    'barWidth', ...
    'distance', ...
    'RstarMean', ...
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

%setup key for finding results
result_key.pipeline_name = pipeline;
result_key.epoch_func_name = 'spikesInMovingBarEpoch';

%get all neccessary results and epoch parameters
computedVals = struct;
computedVals.spikeCountFull = zeros(N_epochs,1);
computedVals.spikeCountON = zeros(N_epochs,1);
computedVals.spikeCountOFF = zeros(N_epochs,1);
computedVals.spikeRateFull = zeros(N_epochs,1);
computedVals.spikeRateON = zeros(N_epochs,1);
computedVals.spikeRateOFF = zeros(N_epochs,1);
computedVals.ON_OFF_index = zeros(N_epochs, 1);

spikeRatePre = zeros(N_epochs,1);
barAngle = zeros(N_epochs, 1);

%TODO: make angles absolute (D,V,N,T) based on eye and rig, if possible
for i=1:N_epochs
    ep = sl.Epoch & dataset & sprintf('epoch_number=%d',epoch_ids(i));
    if ~ep.exists
        fprintf('Missing epoch %d', epoch_ids(i)); 
        R = [];
        return;
    end
    
    ep_struct = ep.fetch('*');
    barAngle(i) = round(ep_struct.protocol_params.barAngle);
        
    key = mergeStruct(ep_struct, result_key);
    ep_result = getStoredResult('Epoch', key);    
    ep_result_R = ep_result.fetch1('result');
        
    computedVals.spikeCountFull(i) = ep_result_R.stimCount;
    computedVals.spikeCountON(i) = ep_result_R.stimCount_ON;
    computedVals.spikeCountOFF(i) = ep_result_R.stimCount_OFF;
    computedVals.spikeRateFull(i) = ep_result_R.stimCount / ep_result_R.stimDur;
    computedVals.spikeRateON(i) = ep_result_R.stimCount_ON / ep_result_R.ON_dur;
    computedVals.spikeRateOFF(i) = ep_result_R.stimCount_OFF / ep_result_R.OFF_dur;
    computedVals.ON_OFF_index(i) = ep_result_R.ON_OFF_index;
    spikeRatePre(i) = ep_result_R.preCount / ep_result_R.preDur;    
end

%rates are baseline subtracted
computedVals.spikeRateFull = computedVals.spikeRateFull - mean(spikeRatePre);
computedVals.spikeRateON = computedVals.spikeRateON - mean(spikeRatePre);
computedVals.spikeRateOFF = computedVals.spikeRateOFF - mean(spikeRatePre);

outputStruct = distributeAndOrder(barAngle, computedVals);
outputStruct = renameStructField(outputStruct, 'keyVals', 'barAngle');
outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');
outputStruct.ON_OFF_index_max = max(outputStruct.ON_OFF_index_mean);
outputStruct.ON_OFF_index_min = min(outputStruct.ON_OFF_index_mean);
outputStruct.ON_OFF_index_meanAcrossAngles = mean(outputStruct.ON_OFF_index_mean);
outputStruct.ON_OFF_index_CVAcrossAngles =  std(outputStruct.ON_OFF_index_mean) ./ outputStruct.ON_OFF_index_meanAcrossAngles;

responseTypes = {'spikeCountFull',...
    'spikeRateFull',...
    'spikeCountON',...
    'spikeRateON',...
    'spikeCountOFF',...
    'spikeRateOFF'...
    };

for i=1:length(responseTypes)
    %this function uses absolute values for comparisons, which may not be correct for spike rates that go below 0 (baseline subtracted)
    %the issue is when the rate is below zero for some angles and above zero for others
    DSI_OSI = computeDSIandOSI(outputStruct.barAngle, outputStruct.([responseTypes{i} '_mean']));
    fields = fieldnames(DSI_OSI);
    for f=1:length(fields)
        outputStruct.([responseTypes{i} '_' fields{f}]) = DSI_OSI.(fields{f});
    end    
end

R = mergeStruct(R,outputStruct);


