function R = DriftingGratings_spike_analysis(dataset, pipeline, P)
R = []; %will be struct. error if isempty
dataset_struct = dataset.fetch('*');
epoch_ids = dataset_struct.epoch_ids;

if ~strcmp(dataset_struct.dataset_protocol_name, 'Drifting Gratings')
    disp('Error: DriftingGratings_spike_analysis designed for datasets of type: Drifting Gratings');
    return;
end

paramsToSave = {'gratingProfile', ...
    'RstarMean', ...
    'RstarIntensity1', ...
    'cycleHalfWidth', ...
    'spatialFreq', ...
    'temporalFreq',...
    'gratingSpeed',...
    'contrast',...
    'gratingProfile'};

[protocol_params, changing_fields, protocol_params_all] = getExampleProtocolParametersForEpochInDataset(dataset_struct.cell_id, dataset_struct.dataset_name);
for i=1:length(paramsToSave)
    if ~ismember(changing_fields, paramsToSave{i})
        if isfield(protocol_params, paramsToSave{i})
            R.(paramsToSave{i}) = protocol_params.(paramsToSave{i});
        end
    end
end

excludeParams = {'epochStartTime', 'gratingAngle', 'originalAngle', 'numberOfAverages'};
parameter_sets = getUniqueEpochParametersSets(protocol_params_all, changing_fields, epoch_ids, excludeParams);

if isempty(parameter_sets) %single parameter set
    Rset = analyzeDriftingGratings_spikes_acrossAngle(pipeline, dataset_struct, epoch_ids);
    R = mergeStruct(Rset, R);
else
    L = length(parameter_sets);
    %R.paramSet = struct(L,1);
    for i=1:L
        curParamSet = parameter_sets(i);
        Nparams = length(curParamSet.fields);
        Pset = struct;
        for p=1:Nparams
            Pset.(curParamSet.fields{p}) = curParamSet.paramVals(p);
        end
        R.paramSet(i) = Pset;
        Rset = analyzeDriftingGratings_spikes_acrossAngle(pipeline, dataset_struct, curParamSet.epoch_ids);
        fields = fieldnames(Rset);
        for f=1:length(fields)
            R.([fields{f}]){i} = Rset.(fields{f});
        end
    end
end

