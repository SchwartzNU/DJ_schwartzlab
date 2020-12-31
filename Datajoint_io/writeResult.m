function [] = writeResult(pipeline, funcType, funcName, P, analysisOutput, overwrite)
switch funcType
    case 'Epoch'
        disp('Writing epoch results to database');
        for i=1:length(analysisOutput)
            key = analysisOutput(i).input;
            key.epoch_func_name = funcName;
            key.param_struct = P;
            key.result = analysisOutput(i).result;
            key.pipeline_name = pipeline;
            if overwrite
                insert(sl.EpochResult, key, 'REPLACE');
            else
                try
                    insert(sl.EpochResult, key);
                catch
                    disp([funcName ': duplicate result: did not overwrite']);
                end
            end
        end
    case 'Dataset'
        disp('Writing dataset results to database');
        for i=1:length(analysisOutput)
            key = analysisOutput(i).input;
            key.dataset_func_name = funcName;
            key.param_struct = P;
            key.result = analysisOutput(i).result;
            key.pipeline_name = pipeline;
            if overwrite
                insert(sl.DatasetResult, key, 'REPLACE');
            else
                try
                    insert(sl.DatasetResult, key);
                catch
                    disp([funcName ': duplicate result: did not overwrite']);
                end
            end
        end
    case 'Cell'
        disp('Writing cell results to database');
        for i=1:length(analysisOutput)
            key = analysisOutput(i).input;
            key.cell_func_name = funcName;
            key.param_struct = P;
            key.result = analysisOutput(i).result;
            key.pipeline_name = pipeline;
            if overwrite
                insert(sl.CellResult, key, 'REPLACE');
            else
                try
                    insert(sl.CellResult, key);
                catch
                    disp([funcName ': duplicate result: did not overwrite']);
                end
            end
        end
        
        
    case 'Multi-cell'
        disp('Writing multi-cell results to database');
        key.func_name = funcName;
        key.param_struct = P;
        key.result = analysisOutput.result;
        key.pipeline_name = pipeline;
        if overwrite
            insert(sl.Result, key, 'REPLACE');
        else
            try
                insert(sl.Result, key);
            catch
                disp([funcName ': duplicate result: did not overwrite']);
            end
        end

end
disp('done');