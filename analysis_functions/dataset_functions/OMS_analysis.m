function R = OMS_analysis(dataset, pipeline, P)

R = []; %will be struct. error if isempty
dataset_struct = dataset.fetch('*');

if ~strcmp(dataset_struct.dataset_protocol_name, 'Object Motion Sensitivity')
    disp('Error: OMS_analysis designed for datasets of type: Object Motion Sensitivity');
    return;
end

%save static parameters that are important
paramsToSave = {'patternSpatialScale', ...
    'centerDiameter',...
    'figureBackgroundMode', ...
    'patternMode', ...
    'contrast',...
    'RstarMean', ...
    'RstarIntensity1'};

[protocol_params, changing_fields] = getExampleProtocolParametersForEpochInDataset(dataset_struct.cell_id, dataset_struct.dataset_name);
for i=1:length(paramsToSave)
    if ~ismember(changing_fields, paramsToSave{i})
        R.(paramsToSave{i}) = protocol_params.(paramsToSave{i});
    end
end

epoch_ids = dataset_struct.epoch_ids;
N_epochs = length(epoch_ids);

motionMode = zeros(N_epochs, 1);

%setup key for finding results
result_key.pipeline_name = pipeline;
result_key.epoch_func_name = 'spikesInIntervals';

%get all neccessary results and epoch parameters
computedVals = struct;
computedVals.spikeRatePre = zeros(N_epochs,1);
computedVals.spikeRateOnset = zeros(N_epochs,1);
computedVals.spikeRateMotion = zeros(N_epochs,1);

for i=1:N_epochs
    ep = sl.Epoch & dataset & sprintf('epoch_number=%d',epoch_ids(i));
    if ~ep.exists
        fprintf('Missing epoch %d', epoch_ids(i)); 
        R = [];
        return;
    end
    
    ep_struct = ep.fetch('*');
    motionMode(i) = round(ep_struct.protocol_params.motionMode);
        
    ep_result = sl.EpochResult & ep & result_key;
    if ep_result.count ~= 1
        fprintf('OMS_analysis: error loading epoch results from %s for epoch %d \n', ...
            result_key.epoch_func_name, ep_struct.epoch_number);
    end
    ep_result_R = ep_result.fetch1('result');    
    computedVals.spikeRatePre(i) = ep_result_R.pre_0toInf / ep_result_R.pre_0toInf_dur;
    computedVals.spikeRateOnset(i) = ep_result_R.stim_0to1000;
    computedVals.spikeRateMotion(i) = ep_result_R.stim_1000toInf / ep_result_R.stim_1000toInf_dur;
end

computedVals.spikeRateMotion_baselineSubtraced = computedVals.spikeRateMotion - mean(computedVals.spikeRatePre);
computedVals.spikeRateOnset_baselineSubtraced = computedVals.spikeRateOnset - mean(computedVals.spikeRatePre);
outputStruct = distributeAndOrder(motionMode, computedVals);
%SI = (center - Global) / (center + Global);
%{'Center', 'Surround', 'Global', 'Differential', 'No movement'};
motionSpikes = outputStruct.spikeRateMotion_baselineSubtraced_mean;
onsetSpikes = outputStruct.spikeRateOnset_baselineSubtraced_mean;
outputStruct.SI = (motionSpikes(1) - motionSpikes(3)) / (motionSpikes(1) + motionSpikes(3));
outputStruct.OMSI = (motionSpikes(4) - motionSpikes(3)) / (motionSpikes(4) + motionSpikes(3));
outputStruct.SoverC = motionSpikes(2) / motionSpikes(1);
outputStruct.SI_onset = (onsetSpikes(1) - onsetSpikes(3)) / (onsetSpikes(1) + onsetSpikes(3));
outputStruct.OMSI_onset_control = (onsetSpikes(4) - onsetSpikes(3)) / (onsetSpikes(4) + onsetSpikes(3));
outputStruct.SoverC_onset = onsetSpikes(2) / onsetSpikes(1);
outputStruct = renameStructField(outputStruct, 'keyVals', 'motionMode');
outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');
R = mergeStruct(R,outputStruct);
