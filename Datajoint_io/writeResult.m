function [] = writeResult(pipeline, funcType, funcName, P, analysisOutput, overwrite)
C = dj.conn;
user_db = sprintf('sl_%s', lower(C.user));
switch funcType
    case 'Epoch'
        disp('Writing epoch results to database');
        for i=1:length(analysisOutput)
            if ~isempty(analysisOutput(i).input)
                key = analysisOutput(i).input;
                key.epoch_func_name = funcName;
                key.param_struct = P;
                key.result = analysisOutput(i).result;
                key.pipeline_name = pipeline;
                if overwrite
                    eval(sprintf('insert(%s.EpochResult, key, ''REPLACE'');', user_db));
                else
                    try
                        eval(sprintf('insert(%s.EpochResult, key);', user_db));
                    catch
                        disp([funcName ': duplicate result: did not overwrite']);
                    end
                end
            end
        end
    case 'Dataset'
        disp('Writing dataset results to database');
        for i=1:length(analysisOutput)
            if ~isempty(analysisOutput(i).input)
                C.startTransaction;
                key = analysisOutput(i).input;
                key.pipeline_name = pipeline;
                key_for_analyzed = key;
                if isfield(key_for_analyzed, 'dataset_func_name')
                    key_for_analyzed = rmfield(key_for_analyzed, 'dataset_func_name');
                end
                insert(sl_mutable.DatasetAnalyzed, key_for_analyzed, 'REPLACE');
                
                key.dataset_func_name = funcName;
                key.param_struct = P;
                key.result = analysisOutput(i).result;
                if overwrite
                    eval(sprintf('insert(%s.DatasetResult, key, ''REPLACE'');', user_db));
                else
                    try
                        eval(sprintf('insert(%s.DatasetResult, key);', user_db));
                    catch
                        disp([funcName ': duplicate result: did not overwrite']);
                    end
                end
                C.commitTransaction;
            end
        end
    case 'Cell'
        disp('Writing cell results to database');
        for i=1:length(analysisOutput)
            if ~isempty(analysisOutput(i).input)
                C.startTransaction;
                key = analysisOutput(i).input;
                key.pipeline_name = pipeline;
                insert(sl_mutable.CellAnalyzed, key, 'REPLACE');
                
                key.cell_func_name = funcName;
                key.param_struct = P;
                key.result = analysisOutput(i).result;
                if overwrite
                    eval(sprintf('insert(%s.CellResult, key, ''REPLACE'');', user_db));
                else
                    try
                        eval(sprintf('insert(%s.CellResult, key);', user_db));
                    catch
                        disp([funcName ': duplicate result: did not overwrite']);
                    end
                end
                C.commitTransaction;
            end
        end
        
        
    case 'Multi-cell'
        disp('Writing multi-cell results to database');
        key.func_name = funcName;
        key.param_struct = P;
        key.result = analysisOutput.result;
        key.pipeline_name = pipeline;
        if overwrite
            eval(sprintf('insert(%s.Result, key, ''REPLACE'');', user_db));
        else
            try
                eval(sprintf('insert(%s.Result, key);', user_db));
            catch
                disp([funcName ': duplicate result: did not overwrite']);
            end
        end

end
disp('done writing results');