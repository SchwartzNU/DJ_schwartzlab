function meanTraces = getMeanTracesForDatasetWithROIs(ds,ROIs,baseline_ms)
epochs = sln_symphony.DatasetEpoch * sln_symphony.ExperimentEpoch * sln_cell.CellName & proj(ds);

epoch_ids = fetchn(epochs,'epoch_id');
N_epochs = length(epoch_ids);

for i=1:N_epochs
    ep = epochs & sprintf('epoch_id=%d',epoch_ids(i));
    traces = getImageTracesForEpochWithROIs(ep, ROIs, baseline_ms);
    if i==1
        meanTraces = traces;
    else
        meanTraces = meanTraces+traces;
    end
end

meanTraces = meanTraces ./ N_epochs;


