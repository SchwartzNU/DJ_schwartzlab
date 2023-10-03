function R = MovingBar_current_analysis(dataset, pipeline, P)

R = []; %will be struct. error if isempty
dataset_struct = dataset.fetch('*');

if ~strcmp(dataset_struct.dataset_protocol_name, 'Moving Bar')
    disp('Error: MovingBar_current_analysis designed for datasets of type: Moving Bar');
    return;
end

paramsToSave = {'barLength', ...
    'barSpeed',...
    'barWidth', ...
    'distance', ...
    'RstarMean', ...
    'RstarIntensity1', ...
    'ampHoldSignal'};

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

%get all neccessary results and epoch parameters
computedVals = struct;

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
        
end

%rates are baseline subtracted

outputStruct = distributeAndOrder(barAngle, computedVals);
outputStruct = renameStructField(outputStruct, 'keyVals', 'barAngle');
outputStruct = renameStructField(outputStruct, 'key_N', 'Nepochs');

L = length(outputStruct.barAngle);
maxFR = zeros(1,L);
for i=1:L
    ind = outputStruct.key_ind(i,:);
    [timeAxis, data, data_mean] = epochRawData(dataset_struct.cell_data, epoch_ids(ind));
    if R.ampHoldSignal < 0
        maxCurrent(i) = min(data_mean(timeAxis>0));
    else
        maxCurrent(i) = max(data_mean(timeAxis>0));
    end
    
end

outputStruct.maxCurrent_mean = mean(maxCurrent);
outputStruct.maxCurrent_sem = std(maxCurrent) ./ sqrt(L-1);

R = mergeStruct(R,outputStruct);


