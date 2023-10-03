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
            current_source_ids = fetchn(sln_animal.Source,'source_id');
            switch source_type
                case 'Vendor' %Sources 1-89
                    last_id = max(current_source_ids(current_source_ids<=89));
                    if last_id == 89
                       error('Error, ran out of Vendor IDs');
                    end

                case 'GenotypeSource' %Sources 90-99
                    last_id = max(current_source_ids(current_source_ids>=90 & current_source_ids<=99));
                    if last_id == 99
                       error('Error, ran out of Genotype IDs');
                    end

                case 'Collaborator' %Sources 100-999
                    last_id = max(current_source_ids(current_source_ids>=100 & current_source_ids<=999));
                    if last_id == 999
                       error('Error, ran out of Collaborator IDs');
                    end

                case 'BreedingPair' %Sources 1000+
                    last_id = max(current_source_ids(current_source_ids>=1000));

            end
            key_source.source_id = last_id + 1;
            insert(sln_animal.Source, key_source);
            key.source_id = key_source.source_id;
            insert(feval(sprintf('sln_animal.%s',source_type)), key);
            C.commitTransaction;
        catch ME            
            C.cancelTransaction;
            rethrow(ME)
        end
    end
end
