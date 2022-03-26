function source_id = add_source(keys, source_type) %assign_soucre
source_id = zeros(length(keys),1);
for i=1:length(keys)
    key = keys(i);
    key_s = struct('source_info','');
    if isfield(key, 'source_info')
        key_s.source_info = key.source_info;
        key = rmfield(key, 'source_info');
    end
    %first check if this source already exists
    q = feval(sprintf('sln_animal.%s',source_type)) & key;
    if q.exists
        source_id(i) = fetch1(q,'source_id');
    else %add it

        C = dj.conn;
        C.startTransaction;
        try
            %source_id = add_source_if_missing(...)
            insert(sln_animal.Source,key_s);
            source_id(i) = fetch1(sln_animal.Source, 'source_id', 'ORDER BY source_id DESC LIMIT 1');
            key.source_id = source_id(i);
            insert(feval(sprintf('sln_animal.%s',source_type)), key);
            C.commitTransaction;
        catch ME            
            C.cancelTransaction;
            rethrow(ME)
        end
    end
end
