function [allTraces, epochParamVals] = getAllTracesForDatasetWithROIs(ds,ROIs,baseline_ms,epoch_param)
epochs = sln_symphony.DatasetEpoch * sln_symphony.ExperimentEpoch * sln_symphony.ExperimentEpochBlock * sln_cell.CellName & proj(ds);

epoch_ids = fetchn(epochs,'epoch_id');
N_epochs = length(epoch_ids);
epochParamVals = zeros(N_epochs,1);

for i=1:N_epochs
    ep = epochs & sprintf('epoch_id=%d',epoch_ids(i));    
    allTraces{i} = getImageTracesForEpochWithROIs(ep, ROIs, baseline_ms);
    if i==1
        protocol_name = fetch1(ep, 'protocol_name');
        epochs = epochs * aka.EpochParams(sqlProtName2ProtName(protocol_name)) * aka.BlockParams(sqlProtName2ProtName(protocol_name));
    end
    ep = epochs & sprintf('epoch_id=%d',epoch_ids(i));
    epochParamVals(i) = fetch1(ep,epoch_param);
end

