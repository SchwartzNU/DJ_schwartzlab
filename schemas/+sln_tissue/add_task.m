function add_task(keys, task_type) 
for i=1:length(keys)
    key = keys(i);    
    key_t.task_name = key.task_name;
    key_t.task_type = task_type;
    
    key = rmfield(key, 'task_type');

    %first check if this task already exists
    q = feval(sprintf('sln_tissue.%s',task_type)) & key;
    if q.exists
        %do nothing
    else %add it
        C = dj.conn;
        C.startTransaction;
        try
            insert(sln_tissue.Task,key_t);
            insert(feval(sprintf('sln_tissue.%s',task_type)), key);
            C.commitTransaction;
        catch ME            
            C.cancelTransaction;
            rethrow(ME)
        end
    end
end