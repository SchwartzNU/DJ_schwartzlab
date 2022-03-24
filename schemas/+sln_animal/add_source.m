function source_id = add_source(keys, source_type)
for i=1:length(keys)
    key = keys(i);
    key_s = struct('source_info','');
    if isfield(key, 'source_info')
        key_s.source_info = key.source_info;
        key = rmfield(key, 'source_info');
    end    
    insert(sln_animal.Source,key_s);
    source_id(i) = max(fetchn(sln_animal.Source, 'source_id'));
    key.source_id = source_id(i);
    insert(feval(sprintf('sln_animal.%s',source_type)), key);
end
