function [protocol_params, changing_fields, protocol_params_all] = getExampleProtocolParametersForEpochInDataset(cell_id, dataset_name)
thisDataset = sl.Dataset & sprintf('cell_id="%s"', cell_id) & sprintf('dataset_name="%s"',dataset_name);
[ep_count, epochs] = getEpochsInQuery(thisDataset);
protocol_params_all = epochs.fetchn('protocol_params');
protocol_params = protocol_params_all{1};


fields = fieldnames(protocol_params);
Nfields = length(fields);

changing_fields = {};
for i=1:Nfields
    vals = cell(ep_count,1);
    firstVal = cell(ep_count,1);
    for n=1:ep_count
        vals{n} = protocol_params_all{n}.(fields{i});    
        firstVal{n} = protocol_params_all{1}.(fields{i}); 
        
    end
    if ~all(arrayfun(@(x,y)isequal(x,y),vals,firstVal))
        changing_fields = [changing_fields; fields{i}];
    end
end