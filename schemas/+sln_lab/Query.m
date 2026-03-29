%{
#Queries for particular projects / users
query_name                   : varchar(128)   # unique name
-> sln_lab.User
---
-> [nullable] sln_lab.Project
sql_query : varchar(60000)
%}

classdef Query < dj.Manual
    methods
        function result = runAndFetch(query)
            q_str = fetch1(query, 'sql_query');
            q_str = sprintf('SELECT * from %s', q_str);
            C = dj.conn;
            tmp = C.query(q_str);  
            result = struct('file_name', tmp.file_name, ...
                     'source_id', num2cell(tmp.source_id), ...
                     'dataset_name', tmp.dataset_name);
        end

        function result = add_metadata(query, base_result)
            if nargin < 2
                base_result = query.runAndFetch();
            end
            if isempty(base_result)
                result = base_result;
                return
            end

            base_rows = normalizeRows(base_result);
            dataset_keys = extractDatasetKeys(base_rows);
            metadata_rows = fetchMetadataRows(dataset_keys);
            result = mergeMetadataRows(base_rows, metadata_rows);

            function fetched = singleFetch(rel, label)
                fetched = fetch(rel, '*');
                assert(numel(fetched) == 1, 'Expected exactly 1 %s row, got %d', label, numel(fetched));
            end

            function target = mergeStruct(target, source, skipFields)
                if nargin < 3
                    skipFields = {};
                end
                fn = fieldnames(source);
                for j = 1:numel(fn)
                    if ~ismember(fn{j}, skipFields)
                        target.(fn{j}) = source.(fn{j});
                    end
                end
            end

            function rows = normalizeRows(raw_rows)
                key_fields = {'file_name', 'source_id', 'dataset_name'};
                missing_fields = setdiff(key_fields, fieldnames(raw_rows));
                if ~isempty(missing_fields)
                    error('Saved query is missing dataset key fields: %s', strjoin(missing_fields, ', '));
                end

                if isscalar(raw_rows) && numel(raw_rows.source_id) > 1
                    N = numel(raw_rows.source_id);
                    template = struct();
                    fields = fieldnames(raw_rows);
                    row_cells = cell(N, 1);
                    for i = 1:N
                        row = template;
                        for f = 1:numel(fields)
                            row.(fields{f}) = indexedScalar(raw_rows.(fields{f}), i);
                        end
                        row_cells{i} = row;
                    end
                    rows = vertcat(row_cells{:});
                else
                    rows = raw_rows;
                end

                for i = 1:numel(rows)
                    rows(i).file_name = char(string(unwrapScalar(rows(i).file_name)));
                    rows(i).source_id = double(normalizeNumericScalar(rows(i).source_id));
                    rows(i).dataset_name = char(string(unwrapScalar(rows(i).dataset_name)));
                end
            end

            function dataset_keys = extractDatasetKeys(rows)
                row_cells = cell(numel(rows), 1);
                seen = containers.Map('KeyType', 'char', 'ValueType', 'logical');
                keep_count = 0;
                for i = 1:numel(rows)
                    key = struct( ...
                        'file_name', rows(i).file_name, ...
                        'source_id', rows(i).source_id, ...
                        'dataset_name', rows(i).dataset_name);
                    key_text = datasetKey(key);
                    if ~isKey(seen, key_text)
                        seen(key_text) = true;
                        keep_count = keep_count + 1;
                        row_cells{keep_count} = key;
                    end
                end
                dataset_keys = vertcat(row_cells{1:keep_count});
            end

            function metadata_rows = fetchMetadataRows(dataset_keys)
                metadata_rows = addDependentMetadata(dataset_keys);
            end

            function result_rows = mergeMetadataRows(rows, metadata_rows)
                meta_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
                for i = 1:numel(metadata_rows)
                    meta_map(datasetKey(metadata_rows(i))) = i;
                end

                row_cells = cell(numel(rows), 1);
                for i = 1:numel(rows)
                    key_text = datasetKey(rows(i));
                    assert(isKey(meta_map, key_text), 'Metadata row missing for dataset %s', key_text);
                    metadata_row = metadata_rows(meta_map(key_text));
                    row_cells{i} = mergeStruct(rows(i), metadata_row, {'file_name', 'source_id', 'dataset_name'});
                end
                result_rows = vertcat(row_cells{:});
            end

            function enriched_rows = addDependentMetadata(rows)
                row_cells = cell(numel(rows), 1);
                for k = 1:numel(rows)
                    row = rows(k);
                    key_row = struct( ...
                        'file_name', row.file_name, ...
                        'source_id', row.source_id, ...
                        'dataset_name', row.dataset_name);

                    exp_cell = singleFetch(sln_symphony.ExperimentCell & ...
                        struct('file_name', row.file_name, 'source_id', row.source_id), ...
                        sprintf('experiment cell for dataset %s', row.dataset_name));
                    row = mergeStruct(row, exp_cell, {'file_name', 'source_id'});

                    cell_row = singleFetch(sln_cell.Cell & ...
                        struct('file_name', row.file_name, 'source_id', row.source_id), ...
                        sprintf('cell metadata for dataset %s', row.dataset_name));
                    row = mergeStruct(row, cell_row, {'file_name', 'source_id'});

                    type_rel = sln_cell.AssignType.current() & struct('cell_unid', row.cell_unid);
                    if exists(type_rel)
                        type_row = singleFetch(type_rel, ...
                            sprintf('cell type for dataset %s', row.dataset_name));
                        row = mergeStruct(row, type_row, {'cell_unid'});
                    else
                        row.cell_type = '';
                        row.cell_class = '';
                        row.user_name = '';
                        row.entry_time = [];
                        row.notes = '';
                    end

                    name_rel = sln_cell.CellName & struct('file_name', row.file_name, 'source_id', row.source_id);
                    if exists(name_rel)
                        row.cell_name = fetch1(name_rel, 'cell_name');
                    else
                        row.cell_name = '';
                    end

                    if isfield(row, 'retina_id') && ~isempty(row.retina_id) && ~isnan(row.retina_id)
                        retina_row = singleFetch((sln_symphony.ExperimentRetina * sln_animal.Eye) & ...
                            struct('file_name', row.file_name, 'source_id', row.retina_id), ...
                            sprintf('retina metadata for dataset %s', row.dataset_name));
                        row.side = retina_row.side;
                        row.orientation = normalizeFetchedField(retina_row, 'orientation', '');
                        row.experimenter = normalizeFetchedField(retina_row, 'experimenter', ...
                            normalizeFetchedField(retina_row, 'user_name', ''));
                        row.source_id_retina = retina_row.source_id;
                        row.retina_quadrant = computeRetinaQuadrant(row.x, row.y, row.side);
                        animal_id = retina_row.animal_id;
                    else
                        row.side = '';
                        row.experimenter = '';
                        row.orientation = '';
                        row.source_id_retina = [];
                        row.retina_quadrant = [];
                        animal_id = row.animal_id;
                    end

                    animal_row = singleFetch(sln_animal.Animal & struct('animal_id', animal_id), ...
                        sprintf('animal metadata for dataset %s', row.dataset_name));
                    row = mergeStruct(row, animal_row, {'source_id'});
                    row.animal_source = normalizeFetchedField(animal_row, 'source_id', []);
                    row.file_name = key_row.file_name;
                    row.source_id = key_row.source_id;
                    row.dataset_name = key_row.dataset_name;

                    row_cells{k} = row;
                end
                enriched_rows = vertcat(row_cells{:});
            end

            function key_text = datasetKey(row)
                key_text = sprintf('%s|%d|%s', row.file_name, row.source_id, row.dataset_name);
            end

            function value = unwrapScalar(value)
                if iscell(value)
                    value = value{1};
                end
            end

            function value = normalizeNumericScalar(value)
                value = unwrapScalar(value);
                if ischar(value) || isstring(value)
                    value = str2double(string(value));
                end
            end

            function value = normalizeFetchedField(struct_row, field_name, default_value)
                if isfield(struct_row, field_name)
                    value = struct_row.(field_name);
                else
                    value = default_value;
                end
            end

            function value = indexedScalar(value, idx)
                if iscell(value)
                    value = value{idx};
                elseif isstring(value) && numel(value) > 1
                    value = value(idx);
                elseif isnumeric(value) || islogical(value)
                    if numel(value) > 1
                        value = value(idx);
                    end
                elseif ischar(value)
                    if size(value, 1) > 1
                        value = value(idx, :);
                    end
                end
            end

            function quadrant = computeRetinaQuadrant(x, y, side)
                if isempty(x) || isempty(y) || isnan(x) || isnan(y) || ...
                        (x == 0 && y == 0) || startsWith(side, 'Unknown')
                    quadrant = [];
                elseif (strcmp(side, 'Left') && x < 0) || (strcmp(side, 'Right') && x > 0)
                    if y < 0
                        quadrant = 'VT';
                    else
                        quadrant = 'DT';
                    end
                else
                    if y < 0
                        quadrant = 'VN';
                    else
                        quadrant = 'DN';
                    end
                end
            end
        end

        function result = runAndFetchAnalysisResult(query, resultName)
            if nargin < 2
                resultName = [];
            end
            q_str = fetch1(query, 'sql_query');
%            q_str = strrep(q_str,',`user_name`',''); %conflicts with result fields
%            q_str = strrep(q_str,',`entry_time`',''); %conflicts with result fields 
             if isempty(resultName)
                q_str = sprintf('SELECT * from %s', q_str);
            else
                result_table = eval(sprintf('sln_results.%s',resultName));
                result_table_name = result_table.sql;
                q_str = sprintf('SELECT * from %s NATURAL JOIN %s', result_table_name, q_str);
            end

            C = dj.conn;
            result = query.add_metadata(C.query(q_str));
        end

    end
end
