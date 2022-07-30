function tissue_id = add_tissue(keys, tissue_type) 
tissue_id = zeros(length(keys),1);
for i=1:length(keys)
    key = keys(i);
    
    key_t = struct('tissue_info','');
    if isfield(key, 'tissue_info')
        key_t.tissue_info = key.tissue_info;
        key = rmfield(key, 'tissue_info');
    end

    %first check if this tissue already exists
    q = feval(sprintf('sln_tissue.%s',tissue_type)) & key;
    if q.exists
        tissue_id(i) = fetch1(q,'tissue_id');
    else %add it
        C = dj.conn;
        C.startTransaction;
        try
            insert(sln_tissue.Tissue,key_t);
            tissue_id(i) = fetch1(sln_tissue.Tissue, 'tissue_id', 'ORDER BY tissue_id DESC LIMIT 1');
            key.tissue_id = tissue_id(i);
            insert(feval(sprintf('sln_tissue.%s',tissue_type)), key);
            C.commitTransaction;
        catch ME            
            C.cancelTransaction;
            rethrow(ME)
        end
    end
end