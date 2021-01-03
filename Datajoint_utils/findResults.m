function missingEntries = findResults(pipeline, funcType, funcName, workingQuery)
key.pipeline_name = pipeline;
key.epoch_func_name = funcName;
switch funcType
    case 'Epoch'
        disp('Finding epoch results in database');
        [~, ep_in_datasets] = getEpochsInQuery(workingQuery);
        thisResult = sl.EpochResult & ep_in_datasets & key;
        missingEntries = ep_in_datasets - thisResult;
        
    case 'Dataset'
        disp('Finding dataset results in database');
        datasets = sl.Dataset & workingQuery.proj;
        thisResult = sl.DatasetResult & datasets & key;
        missingEntries = datasets - thisResult;
        
    case 'Cell'
        disp('Finding cell results in database');
        allcells = sl.MeasuredCell & workingQuery.proj;
        thisResult = sl.CellResult & allcells & key;
        missingEntries = allcells - thisResult;
        %no multi-cell case becuase we can just load it. It's only one entry
end
disp('done');