function analysisOutput = runAnalysis(pipeline, funcType, funcName, P, workingQuery, previousLoad)
if isempty(previousLoad)
    preload = false;
else
    preload = true;
end

switch funcType
    case 'Epoch'
        if ismember('epoch_number',workingQuery.header.primaryKey) %fed actual epochs
            ep_count = workingQuery.count;
            all_ep_struct = workingQuery.fetch();
        else %fed datasets
            if preload
                [~, ep_in_datasets] = getEpochsInQuery(workingQuery);
                [~, ep_in_datasets_prev] = getEpochsInQuery(workingQuery & [previousLoad.input]);
                ep_in_datasets = ep_in_datasets - ep_in_datasets_prev.proj;
                ep_count = ep_in_datasets.count;
            else
                [ep_count, ep_in_datasets] = getEpochsInQuery(workingQuery);
            end
            
            all_ep_struct = ep_in_datasets.fetch();
        end
        
        fprintf('Running %s on %d epochs...\n', funcName, ep_count);
        
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, ep_count,1);
        for i=1:ep_count
            ep = sl.Epoch & all_ep_struct(i);
            eval(sprintf('R=%s(ep,pipeline,P);', funcName));
            analysisOutput(i).input = all_ep_struct(i);
            analysisOutput(i).result = R;
        end
        
    case 'Dataset'
        if preload
            datasets = sl.Dataset & workingQuery.proj;
            datasets_prev = workingQuery & [previousLoad.input];
            datasets = datasets - datasets_prev.proj;
        else
            datasets = sl.Dataset & workingQuery.proj;
        end
        
        all_ds_struct = datasets.fetch();
        fprintf('Running %s on %d datasets...\n', funcName, datasets.count);
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, datasets.count,1);
        
        for i=1:datasets.count
            curDataSet = sl.Dataset & all_ds_struct(i);
            eval(sprintf('R=%s(curDataSet,pipeline,P);', funcName));
            analysisOutput(i).input = all_ds_struct(i);
            analysisOutput(i).result = R;
        end
    case 'Cell'
        if preload
            allcells = sl.MeasuredCell & workingQuery.proj;
            allcells_prev = workingQuery & [previousLoad.input];
            allcells = allcells - allcells_prev.proj;
        else
            allcells = sl.MeasuredCell & workingQuery.proj;
        end
        
        allcells_struct = allcells.fetch();
        fprintf('Running %s on %d datasets...\n', funcName, allcells.count);
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, allcells.count,1);
        
        for i=1:allcells.count
            curCell = sl.MeasuredCell & allcells_struct(i);
            eval(sprintf('R=%s(curCell,pipeline,P);', funcName));
            analysisOutput(i).input = allcells_struct(i);
            analysisOutput(i).result = R;
        end
        
    case 'Mulit-cell'
        fprintf('Running %s ...\n', funcName);
        curInput = workingQuery;
        analysisOutput = struct('input', [], 'result', []);
        eval(sprintf('R=%s(curInput,pipeline,P);', funcName));
        analysisOutput.result = R;
        
end
fprintf('done\n');