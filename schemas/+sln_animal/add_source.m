function source_id = add_source(keys, source_type) %assign_soucre
source_id = zeros(length(keys),1);
for i=1:length(keys)
    key = keys(i);
    
    %first check if this source already exists
    q = feval(sprintf('sln_animal.%s',source_type)) & key;
    if q.exists
        source_id(i) = fetch1(q,'source_id');
    else %add it
        C = dj.conn;
        C.startTransaction;
        try
            %source_id = add_source_if_missing(...)
            %need to do this the hack way
            %TODO: change this so that source numbers go according to
            %Zach's scheme
            query = 'INSERT INTO `sln_animal`.`source` (source_id) VALUES (null)';
            C.query(query);
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
