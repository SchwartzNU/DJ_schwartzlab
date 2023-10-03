%% bulk load symphony2 experiments
D = dir([getenv('SERVER_ROOT') filesep 'RawDataMaster' filesep 'error_files']);

%% 
all_names = {D.name};
sy2_ind = find(endsWith(all_names,'A.h5') | endsWith(all_names,'B.h5'));
sy2_names = all_names(sy2_ind);

N = length(sy2_names)
status_table = table('Size',[N,2],'VariableTypes',{'string','string'},'VariableNames',{'experiment', 'status'});

for i=1:N
    i
    fprintf('Experiment %s:\n', sy2_names{i});
    status_table.experiment(i) = sy2_names{i};
    q = sln_symphony.Experiment & sprintf('file_name="%s"', sy2_names{i}(1:end-3));
    if q.exists
        disp('Found in database');
        status_table.status(i) = 'Found';
    else
       disp('Trying insert');
       try
            sln_symphony.insert_experiment(sy2_names{i}(1:end-3));
            status_table.status(i) = 'Inserted';
            q = sln_symphony.ExperimentCell & sprintf('file_name = "%s"',sy2_names{i}(1:end-3));
            if q.exists
                disp('moving inserted file out of error_files');
                movefile([getenv('SERVER_ROOT') filesep 'RawDataMaster' filesep 'error_files' filesep sy2_names{i}], ...
                    [getenv('SERVER_ROOT') filesep 'RawDataMaster' filesep]);
            end
       catch ME
            disp(ME.message);
            status_table.status(i) = sprintf('Error: %s', ME.message);
       end
    end

end