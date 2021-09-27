function R = MovingBar_AverageAllDirections(dataset, pipeline, P)

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

barAngle = zeros(N_epochs, 1);

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
    
end

outputStruct = struct();
outputStruct = renameStructField(outputStruct, 'keyVals', 'barAngle');
outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');
outputStruct.spikeCount_allDirections_avg = nanmean(computedVals.spikeCountFull);
outputStruct.spikeCount_allDirections_sem = nanstd(computedVals.spikeCountFull)/sqrt(N_epochs);

R = mergeStruct(R,outputStruct);


