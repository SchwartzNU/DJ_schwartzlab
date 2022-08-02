function add_task(keys, task_type) 
task_name = cell(length(keys),1);
for i=1:length(keys)
    key = keys(i);    
    key_t.tissue_id = key.tissue_id;
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
            task_name{i} = fetch1(sln_tissue.Task, 'task_name', 'ORDER BY task_entry_time DESC LIMIT 1');
            key.task_name = task_name{i};
            insert(feval(sprintf('sln_tissue.%s',task_type)), key);
            C.commitTransaction;
        catch ME            
            C.cancelTransaction;
            rethrow(ME)
        end
    end
end