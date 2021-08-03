function [] = writeResult(pipeline, funcType, funcName, P, analysisOutput, overwrite, user, fid)
C = dj.conn;
if nargin < 8
    fid = 0;
end
if nargin < 7 || isempty(user)
    %if strcmp(C.user,'OfficeDesktop')
        user_db = 'sl_shared';
    %else
    %    user_db = sprintf('sl_%s', lower(C.user));
    %end
else
     if strcmp(C.user,'OfficeDesktop')
        user_db = 'sl_shared';
     else
        user_db = sprintf('sl_%s', user);
     end
end
if fid
    fprintf(fid, 'Writing to schema: %s\n', user_db);
else
    fprintf('Writing to schema: %s\n', user_db);
end
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
                
                if isempty(key.result)
                    if fid
                        fprintf(fid, 'Empty result for function %s, cell %s, epoch number %d. Did not write.\n', funcName, key.cell_id, key.epoch_number);
                    else
                        fprintf('Empty result for function %s, cell %s, epoch number %d. Did not write.\n', funcName, key.cell_id, key.epoch_number);
                    end
                else
                    if overwrite
                        eval(sprintf('insert(%s.EpochResult, key, ''REPLACE'');', user_db));
                    else
                        try
                            eval(sprintf('insert(%s.EpochResult, key);', user_db));
                        catch
                            if fid
                                fprintf(fid, 'Duplicate result for function %s, cell %s, epoch number %d. Did not overwrite.\n', funcName, key.cell_id, key.epoch_number);
                            else
                                fprintf('Duplicate result for function %s, cell %s, epoch number %d. Did not overwrite.\n', funcName, key.cell_id, key.epoch_number);
                            end
                        end
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
                
                if isempty(analysisOutput(i).result)
                    if fid
                        fprintf(fid, 'Empty result for function %s, cell %s, dataset %s. Did not write.\n', funcName, key.cell_id, key.dataset_name);
                        
                    else
                        fprintf(fid, 'Empty result for function %s, cell %s, dataset %s. Did not write.\n', funcName, key.cell_id, key.dataset_name);
                    end
                      
                    C.cancelTransaction;
                else
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
                            if fid
                                fprintf(fid, 'Duplicate result for function %s, cell %s, dataset %s. Did not overwrite.\n', funcName, key.cell_id, key.dataset_name);
                            else
                                fprintf('Duplicate result for function %s, cell %s, dataset %s. Did not overwrite.\n', funcName, key.cell_id, key.dataset_name);
                            end
                        end
                    end
                    C.commitTransaction;
                end
            end
        end
    case 'Cell'
        disp('Writing cell results to database');
        for i=1:length(analysisOutput)
            if ~isempty(analysisOutput(i).input)
                key = analysisOutput(i).input;
                key.pipeline_name = pipeline;                
                key.cell_func_name = funcName;
                key.param_struct = P;
                key.result = analysisOutput(i).result;
                
                if isempty(key.result)
                    if fid
                        fprintf(fid, 'Empty result for function %s, cell %s. Did not write.\n', funcName, key.cell_id);
                    else
                        fprintf('Empty result for function %s, cell %s. Did not write.\n', funcName, key.cell_id);
                    end
                else
                    if overwrite                        
                        eval(sprintf('insert(%s.CellResult, key, ''REPLACE'');', user_db));
                    else
                        try
                            eval(sprintf('insert(%s.CellResult, key);', user_db));
                        catch
                            if fid
                                fprintf(fid, 'Duplicate result for function %s, cell %s. Did not overwrite.\n', funcName, key.cell_id);
                            else
                                fprintf('Duplicate result for function %s, cell %s. Did not overwrite.\n', funcName, key.cell_id);
                            end
                        end
                    end
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
            eval(sprintf('insert(%s.Result, key, ''REPLACE'');', user_db));
        else
            try
                eval(sprintf('insert(%s.Result, key);', user_db));
            catch
                if fid
                    fprintf(fid, 'Duplicate result for function %s. Did not overwrite.\n', funcName);
                else
                    fprintf('Duplicate result for function %s. Did not overwrite.\n', funcName);
                end
            end
        end

end
disp('done writing results');