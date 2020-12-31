function [analysisOutput, loaded_some, missed_some] = loadResult(pipeline, funcType, funcName, workingQuery)
switch funcType
    case 'Epoch'
        disp('Loading epoch results from database');
        [ep_count, ep_in_datasets] = getEpochsInQuery(workingQuery);
        all_ep_struct = ep_in_datasets.fetch();
        fprintf('Loading results of %s from %d epochs...\n', funcName, ep_count);
        
        loaded_some = false;
        missed_some = false;
        
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, ep_count,1);
        for i=1:ep_count
            all_ep_struct(i).pipeline_name = pipeline;
            all_ep_struct(i).epoch_func_name = funcName;
            try
                analysisOutput(i).input = all_ep_struct(i);
                thisResult = sl.EpochResult & all_ep_struct(i);
                analysisOutput(i).result = fetch1(thisResult, 'result');
                loaded_some = true;
            catch
                missed_some = true;
                analysisOutput(i).input = [];
                analysisOutput(i).result = [];
                fprintf('Did not load result of %s for epoch %d\n', funcName, i);
            end
        end
        
    case 'Dataset'
        disp('Loading dataset results from database');
        
        datasets = sl.Dataset & workingQuery.proj;
        all_datasets_struct = datasets.fetch();
        fprintf('Loading results of %s from %d datasets...\n', funcName, datasets.count);
        
        loaded_some = false;
        missed_some = false;
        
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, datasets.count,1);
        
        for i=1:datasets.count
            all_datasets_struct(i).pipeline_name = pipeline;
            all_datasets_struct(i).dataset_func_name = funcName;
            try
                analysisOutput(i).input = all_datasets_struct(i);
                thisResult = sl.DatasetResult & all_datasets_struct(i);
                analysisOutput(i).result = fetch1(thisResult, 'result');
                loaded_some = true;
            catch
                missed_some = true;
                analysisOutput(i).input = [];
                analysisOutput(i).result = [];
                fprintf('Did not load result of %s for dataset %s\n', funcName, all_datasets_struct(i).dataset_name);
            end
        end
        
    case 'Cell'
        disp('Loading cell results from database');
        
        allcells = sl.MeasuredCell & workingQuery.proj;
        allcells_struct = allcells.fetch();
        fprintf('Loading results of %s from %d cells...\n', funcName, allcells.count);
        
        loaded_some = false;
        missed_some = false;
        
        s = struct('input', [], 'result', []);
        analysisOutput = repmat(s, allcells.count,1);
        
        for i=1:allcells.count
            allcells_struct(i).pipeline_name = pipeline;
            allcells_struct(i).cell_func_name = funcName;
            %analysisOutput(i).input = []; %initialize to empty
            %analysisOutput(i).result = []; %initialize to empty
            try
                analysisOutput(i).input = allcells_struct(i);
                thisResult = sl.CellResult & allcells_struct(i);
                analysisOutput(i).result = fetch1(thisResult, 'result');
                loaded_some = true;
            catch
                missed_some = true;
                analysisOutput(i).input = [];
                analysisOutput(i).result = [];
                fprintf('Did not load result of %s for cell %s\n', funcName, allcells_struct(i).cell_id);
            end
        end        
        
    case 'Multi-cell'
        disp('Loading multi-cell results from database');
        loaded_some = false;
        missed_some = false;
        
        analysisOutput = struct('input', [], 'result', []);
        key.pipeline_name = pipeline;
        key.epoch_func_name = funcName;
        try
            thisResult = sl.Result & key;
            analysisOutput.result = fetch1(thisResult, 'result');
            loaded_some = true;
        catch
            missed_some = true;
            analysisOutput.result = [];
            fprintf('Did not load result of %s\n', funcName);
        end
        
end
disp('done');