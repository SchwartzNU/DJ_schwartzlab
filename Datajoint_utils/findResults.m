function missingEntries = findResults(pipeline, funcType, funcName, workingQuery)
%this will only look in your own db;
C = dj.conn;
if strcmp(C.user,'OfficeDesktop')
    user_db = 'sl_shared';
else
    user_db = sprintf('sl_%s', lower(C.user));
end

key.pipeline_name = pipeline;
key.epoch_func_name = funcName;
missingEntries = [];
fprintf('Finding epoch results in database %s\n', user_db);
switch funcType
    case 'Epoch'
        [~, ep_in_datasets] = getEpochsInQuery(workingQuery);
        eval(sprintf('thisResult = %s.EpochResult & ep_in_datasets & key;', user_db));
        %thisResult = sl.EpochResult & ep_in_datasets & key;
        missingEntries = ep_in_datasets - thisResult;        
    case 'Dataset'
        datasets = sl.Dataset & workingQuery.proj;
        eval(sprintf('thisResult = %s.DatasetResult & datasets & key;', user_db));
        %thisResult = sl.DatasetResult & datasets & key;
        missingEntries = datasets - thisResult;
    case 'Cell'
        allcells = sl.MeasuredCell & workingQuery.proj;
        eval(sprintf('thisResult = %s.CellResult & allcells & key;', user_db));
        %thisResult = sl.CellResult & allcells & key;
        missingEntries = allcells - thisResult;
%     case 'Multi-cell'
        %no multi-cell case becuase we can just load it. It's only one entry
end

%if not found, then try other DBs
%get all user dbs
if ~isEmpty(missingEntries) && missingEntries.exists
    user_dbs = fetchn(sl.UserDB,'db_name');
    N = length(user_dbs);
    %put this user's db first
    my_db_ind = find(strcmp(user_dbs, user_db));
    user_dbs = user_dbs(setdiff(1:N, my_db_ind));
    N = length(user_dbs);
    for i=1:N
        fprintf('Finding epoch results in database %s\n', user_dbs{i});
        switch funcType
            case 'Epoch'
                [~, ep_in_datasets] = getEpochsInQuery(workingQuery);
                eval(sprintf('thisResult = %s.EpochResult & ep_in_datasets & key;', user_dbs{i}));
                %thisResult = sl.EpochResult & ep_in_datasets & key;
                missingEntries = missingEntries - thisResult;
            case 'Dataset'
                datasets = sl.Dataset & workingQuery.proj;
                eval(sprintf('thisResult = %s.DatasetResult & datasets & key;', user_dbs{i}));
                %thisResult = sl.DatasetResult & datasets & key;
                missingEntries = missingEntries - thisResult;
            case 'Cell'
                allcells = sl.MeasuredCell & workingQuery.proj;
                eval(sprintf('thisResult = %s.CellResult & allcells & key;', user_dbs{i}));
                %thisResult = sl.CellResult & allcells & key;
                missingEntries = missingEntries - thisResult;
                %     case 'Multi-cell'
                %no multi-cell case becuase we can just load it. It's only one entry
        end
        if ~missingEntries.exists
            return;
        end
    end
end
disp('done finding results');