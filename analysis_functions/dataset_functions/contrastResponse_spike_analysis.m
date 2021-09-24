function R = contrastResponse_spike_analysis(dataset, pipeline, P)

R = []; %will be struct. error if isempty
dataset_struct = dataset.fetch('*');

if ~strcmp(dataset_struct.dataset_protocol_name, 'Contrast Response')
    disp('Error: contrastResponse_spike_analysis designed for datasets of type: Contrast Response');
    return;
end

%save static parameters that are important
paramsToSave = {'spotDiameter',...
    'RstarMean' ...
    };

[protocol_params, changing_fields] = getExampleProtocolParametersForEpochInDataset(dataset_struct.cell_id, dataset_struct.dataset_name);
for i=1:length(paramsToSave)    
    if ~ismember(changing_fields, paramsToSave{i})
        if isfield(R, paramsToSave{i})
            R.(paramsToSave{i}) = protocol_params.(paramsToSave{i});
        end
    end
end

epoch_ids = dataset_struct.epoch_ids;
N_epochs = length(epoch_ids);

contrast = zeros(N_epochs, 1);

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
    contrast(i) = ep_struct.protocol_params.contrast;
    
    key = mergeStruct(ep_struct, result_key);
    ep_result = getStoredResult('Epoch', key);
    
    ep_result_R = ep_result.fetch1('result');
    computedVals.spikeRatePre(i) = ep_result_R.preCount / ep_result_R.preDur;
    computedVals.spikeRateStim(i) = ep_result_R.stimCount / ep_result_R.stimDur;
end

computedVals.spikeRateStim_baselineSubtraced = computedVals.spikeRateStim - mean(computedVals.spikeRatePre);
outputStruct = distributeAndOrder(contrast, computedVals);
outputStruct = renameStructField(outputStruct, 'keyVals', 'contrast');
outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');

maxResp = max(abs(outputStruct.spikeRateStim_baselineSubtraced_mean));
outputStruct.response_norm = outputStruct.spikeRateStim_baselineSubtraced_mean ./ maxResp;

%get half max response by linear interpolation for now - could fit something fancier 
ON_ind = outputStruct.contrast>0;
OFF_ind = outputStruct.contrast<0;

CR_ON = outputStruct.response_norm(ON_ind);
CR_OFF = outputStruct.response_norm(OFF_ind);
[maxVal_ON, maxInd_ON] = max(CR_ON);
[minVal_ON, mindInd_ON] = min(CR_ON);
[maxVal_OFF, maxInd_OFF] = max(CR_OFF);
[minVal_OFF, mindInd_OFF] = min(CR_OFF);

% if abs(maxVal_ON) > abs(minVal_ON)
%    R.C_half_ON = interp1([0; CR_ON]/abs(maxVal_ON), [0; contrast(ON_ind)], 0.5);
% else
%    R.C_half_ON = interp1([0; CR_ON]/abs(minVal_ON), [0; contrast(ON_ind)], -0.5);
% end
%     
% if abs(maxVal_OFF) > abs(minVal_OFF)
%    R.C_half_OFF = interp1([0; CR_OFF]/abs(maxVal_OFF), [0; contrast(OFF_ind)], 0.5);
% else
%    R.C_half_OFF = interp1([0; CR_OFF]/abs(minVal_OFF), [0; contrast(OFF_ind)], -0.5);
% end

R = mergeStruct(R, outputStruct);