function analysisOutput = runAnalysis(pipeline, funcType, funcName, P, workingQuery, previousLoad, fid)
if nargin < 7
    fid = 0;
end
if nargin < 6
    previousLoad = [];
end
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
        
        if fid
            fprintf(fid, 'Running %s on %d epochs...\n', funcName, ep_count);
        else
            fprintf('Running %s on %d epochs...\n', funcName, ep_count);
        end
        
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, ep_count,1);
        for i=1:ep_count
            if fid
                fprintf(fid, 'Cell %s, epoch_num %d...\n', all_ep_struct(i).cell_id, all_ep_struct(i).epoch_number);
            else
                fprintf('Cell %s, epoch_num %d...\n', all_ep_struct(i).cell_id, all_ep_struct(i).epoch_number);
            end
            ep = sl.Epoch & all_ep_struct(i);    
            try
                eval(sprintf('R=%s(ep,pipeline,P);', funcName));
                analysisOutput(i).input = all_ep_struct(i);
                analysisOutput(i).result = R;
            catch
                if fid
                    fprintf(fid, 'Error in analysis %s for cell %s, epoch_num %d\n', funcName, all_ep_struct(i).cell_id, all_ep_struct(i).epoch_number);
                else
                    fprintf('Error in analysis %s for cell %s, epoch_num %d\n', funcName, all_ep_struct(i).cell_id, all_ep_struct(i).epoch_number);
                end
            end
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
        if fid
            fprintf(fid, 'Running %s on %d datasets...\n', funcName, datasets.count);
        else
            fprintf('Running %s on %d datasets...\n', funcName, datasets.count);
        end
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, datasets.count,1);
        
        for i=1:datasets.count
            if fid
                fprintf(fid, 'Cell %s, dataset %s...\n', all_ds_struct(i).cell_id, all_ds_struct(i).dataset_name);
            else
                fprintf('Cell %s, dataset %s...\n', all_ds_struct(i).cell_id, all_ds_struct(i).dataset_name);
            end
            curDataSet = sl.Dataset & all_ds_struct(i);
            try
                eval(sprintf('R=%s(curDataSet,pipeline,P);', funcName));
                analysisOutput(i).input = all_ds_struct(i);
                analysisOutput(i).result = R;
            catch
                if fid
                    fprintf(fid, 'Error in analysis %s for cell %s, dataset %s\n', funcName, all_ds_struct(i).cell_id,  all_ds_struct(i).dataset_name);
                else
                    fprintf('Error in analysis %s for cell %s, dataset %s\n', funcName, all_ds_struct(i).cell_id,  all_ds_struct(i).dataset_name);
                end
            end
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
        if fid
            fprintf(fid, 'Running %s on %d cells...\n', funcName, allcells.count);
        else
            fprintf('Running %s on %d cells...\n', funcName, allcells.count);
        end
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, allcells.count,1);
        
        for i=1:allcells.count
             if fid
                fprintf(fid, 'Cell %s...\n', allcells_struct(i).cell_id);
            else
                fprintf('Cell %s...\n', allcells_struct(i).cell_id);
            end
            curCell = sl.MeasuredCell & allcells_struct(i);
            try
                eval(sprintf('R=%s(curCell,pipeline,P);', funcName));
                analysisOutput(i).input = allcells_struct(i);
                analysisOutput(i).result = R;
            catch
                if fid
                    fprintf(fid, 'Error in analysis %s for cell %s\n', funcName, allcells_struct(i).cell_id);
                else
                    fprintf('Error in analysis %s for cell %s\n', funcName, allcells_struct(i).cell_id);
                end
            end
            
        end
        
    case 'Multi-cell'
        if fid
            fprintf(fid, 'Running %s ...\n', funcName);
        else
            fprintf('Running %s ...\n', funcName);
        end
        curInput = workingQuery;
        analysisOutput = struct('input', [], 'result', []);
        try
            eval(sprintf('R=%s(curInput,pipeline,P);', funcName));
            analysisOutput.result = R;
        catch
            if fid
                fprintf(fid, 'Error in analysis %s\n', funcName);
            else
                fprintf('Error in analysis %s\n', funcName);
            end
        end
end
if fid
    fprintf(fid,'runAnalysis done\n');
else
    fprintf('runAnalysis done\n');
end