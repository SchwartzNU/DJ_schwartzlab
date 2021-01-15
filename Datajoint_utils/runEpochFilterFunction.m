function query = runEpochFilterFunction(commandName, query)
C = dj.conn;
user_db = sprintf('sl_%s', lower(C.user));
commandName = strtok(commandName, '.'); %remove .m
if ~isempty(query)
    [~, ep_query] = getEpochsInQuery(query);
    q_struct = ep_query.fetch('protocol_params');
    fprintf('running filter function on %d epochs\n', length(q_struct));
    tic;
    for i=1:length(q_struct) %check each epoch
        epochForTest = q_struct(i);
        epochForQuery = rmfield(q_struct(i), 'protocol_params');
        passed = eval([commandName '(epochForTest);']);
        eval(sprintf('thisTempEntry = %s.TempFilter & epochForQuery;', user_db));
        while thisTempEntry.exists
            disp('waiting for another user working on this epoch')
            pause(1);
            eval(sprintf('thisTempEntry = %s.TempFilter & epochForTest;', user_db));
        end
        epochForInsert = epochForQuery;
        epochForInsert.passed = passed;
        eval(sprintf('insert(%s.TempFilter,epochForInsert);', user_db));
    end
    fprintf('Time elapsed: %f seconds\n', toc);
    %now run the filter by using restriction with temp table
    passed_epochs = eval(sprintf('%s.TempFilter', user_db)) & 'passed=1';
    fprintf('%d epochs passed.\n', passed_epochs.count);
    %app.loadedQuery = app.loadedQuery & passed_epochs;
    %drop empty datasets
    datasets = sl.Dataset & query.proj & passed_epochs;
    d_struct = fetch(datasets);
    %d_struct_clean = rmfield(d_struct, 'passed');
    d_struct_withEpochNums = fetch(datasets,'epoch_ids');
    for i=1:length(d_struct)
        theseEpochNums = fetchn(passed_epochs & d_struct(i), 'epoch_number');
        if isempty(intersect(d_struct_withEpochNums(i).epoch_ids, theseEpochNums))
            query = query - d_struct(i);
        end
    end
    %and delete the temp filter entries
    q_struct = ep_query.fetch();
    eval(sprintf('delQuick(%s.TempFilter & q_struct);',user_db));
    disp('deleted TempFilter')
end