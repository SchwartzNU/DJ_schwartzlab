function migrate_table(oldTable, newTable)
    newFields = newTable.header.names;

    keys = fetch(oldTable);           % PK-only, lightweight
    fprintf('Total rows to be migrated %d in table %s\n', numel(keys), class(oldTable));
    n = numel(keys);
    if n == 0
        fprintf('%s is empty.\n', class(oldTable));
        return
    end

    for i = 1:n
        src = fetch(oldTable & keys(i), '*');   % one full row (blob included)

        f = fieldnames(src);
        row = struct();
        for k = 1:numel(f)
            if ismember(f{k}, newFields)
                row.(f{k}) = src.(f{k});
            end
        end
        row.seg_id = 1;
        %skip the ids that already in there
        pk = fieldnames(fetch(newTable));
        for j = 1:numel(pk)
            query.(pk{j}) = row.(pk{j});
        end
        query.seg_id = row.seg_id;
        checkinsert = fetch(newTable & query);
        if (isempty(checkinsert))
            insert(newTable, row);
            fprintf('%s: %d/%d\n', class(newTable), i, n);
        else
            disp(row);
            fprintf('Already in the table %s\n', class(newTable));
        end 


    end
end