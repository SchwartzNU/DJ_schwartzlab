function R = get(func_name,data_group,result_level,do_insert)
if nargin < 4
    do_insert = true;
end

R = table; %start empty

switch result_level
    case 'Experiment'
        items = sln_symphony.Experiment & data_group;
    case 'Animal'
        items = proj(sln_animal.Animal,'source_id->animal_source_id') & data_group;
    case 'Eye' %TODO;
        items = sln_animal.Eye & data_group;
    case 'Cell pair' %TODO, cell pair and eye levels
    case 'Cell'
        items = sln_symphony.ExperimentCell & proj(data_group);
    case 'Dataset'
        items = aka.Dataset & data_group;
    case 'Epoch'
        items = sln_symphony.DatasetEpoch & data_group;
end

items_struct = fetch(items);
N_items = length(items_struct);
fprintf('%d items at level %s\n', N_items, result_level);

table_name = sprintf('%s%s',result_level,strrep(func_name,'_',''));
existing_results = eval(sprintf('sln_results.%s & items_struct', table_name));
fprintf('%d results found in %s\n', existing_results.count, table_name);
if existing_results.exists
    R = sln_results.toMatlabTable(existing_results);
end

missing_results = items - existing_results;
if missing_results.exists
    fprintf('Running %s for %d remaining items of type %s\n', func_name, missing_results.count, result_level);
    Rnew = eval(sprintf('%s(missing_results);', func_name));
    inserted = false;
    if do_insert
        while ~inserted
            try
                for i = 1:height(Rnew)
                    sln_results.insert(Rnew(i,:),result_level);
                    fprintf('Inserted %s %s source id: %d successful \n', Rnew.file_name(i), Rnew.dataset_name(i), Rnew.source_id(i))
                end
                R = eval(sprintf('sln_results.%s & items_struct', table_name));
                inserted = true;
            catch ME
                disp('insert failed');
                disp(ME.message);
                keyboard;
                if regexp(ME.message,  'You have locally modified files in')
                    disp('!!!! COMMIT YOUR GIT !!!!');
                    prompt = 'Try again? Make sure all Git changes were commited! Y/N [Y]: ';
                    txt = input(prompt,"s");
                    if isempty(txt) || strcmpi(txt, 'y')
                        inserted = false;
                        continue
                    else
                        break
                    end
                else
                    break
                end
            end
        end
    end
    if ~inserted %WUT IS DIS FOR?
        N_rows = height(Rnew);
        C = dj.conn;
        for i=1:N_rows
            R_extra = table('Size',[N_rows, 3],'VariableTypes',...
                {'string','string','string'},...
                'VariableNames',{'user_name','entry_time', 'git_tag'});
            R_extra.user_name(i) = C.user;
            R_extra.entry_time(i) = 'not inserted';
            R_extra.git_tag(i) = 'none';
        end
        Rnew = [Rnew, R_extra];
        R = [R; Rnew];
    end
end

