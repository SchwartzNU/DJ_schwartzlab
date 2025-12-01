function [] = populate_computed_tables(skip_errors, parallel)
if nargin<2
    parallel = false;
end
if nargin<1
    skip_errors = false;
end

run_first = {'sln_results.SpikeDetectCC','sln_results.SpikeDetectBrainCC','sln_funcimage.Alignment'};

%schemas we want to check for computed tables
schemas = {'sln_results','sln_funcimage'}; 
%schemas = {'sln_results'};

current_time = datetime;
time_str = datestr(current_time,'yyyy-mm-dd_HH-MM-SS');
log_fname = sprintf('%scompute_log_%s.txt', ...
    [getenv('SERVER_ROOT'), filesep, 'DJ_computed_logs', filesep],time_str);

C = dj.conn;
fid = fopen(log_fname,'w');
fprintf(fid,'Beginning computation. Logged in user is %s.\n\n',C.user);

%delete old error files
delete([getenv('SERVER_ROOT'), filesep, ...
    'DJ_computed_logs', filesep, ...
    'error_keys', filesep, ...
    '*.mat']);

delete([getenv('SERVER_ROOT'), filesep, ...
    'DJ_computed_logs', filesep, ...
    'exceptions', filesep, ...
    '*.mat']);

delete([getenv('SERVER_ROOT'), filesep, ...
    'DJ_computed_logs', filesep, ...
    'error_tables', filesep, ...
    '*.xls']);

N_schemas = length(schemas);
for s=1:N_schemas
    sc_name = schemas{s};    
    eval(sprintf('s=%s.getSchema;',sc_name))
    class_names = s.classNames;
    computed_ind = cellfun(@(c)any(ismember(superclasses(c),'dj.Computed')),class_names);
    computed_classes = class_names(computed_ind)';
    N_classes = length(computed_classes);
    for i=1:length(run_first)
        ind = find(strcmp(run_first{i},computed_classes));
        if ~isempty(ind)
            computed_classes = computed_classes([ind, setdiff(1:N_classes,ind)]);
        end
    end
    fprintf(fid,'Schema %s:\n',sc_name);
    fprintf(fid,'Computed classes (in order):\n');
    for i=1:N_classes
        fprintf(fid,'%s\n',computed_classes{i});
    end
    fprintf(fid,'\n');
    for i=1:N_classes
        fprintf(fid,'----------------------------------------.\n');
        fprintf(fid,'Working on %s.\n',computed_classes{i});
        eval(sprintf('obj=%s;',computed_classes{i}));
        unpopulated = obj.keySource - obj;
        unpop_count = unpopulated.count;
        fprintf(fid,'Found %d unpopulated keys.\n',unpop_count);       
        restriction = '';
        N_fail_keys = 0;
        if skip_errors
            fail_keys_name = [getenv('SERVER_ROOT'), filesep, ...
                    'DJ_computed_logs', filesep, ...
                    'error_keys', filesep, ...
                    computed_classes{i}, '.mat'];
            fail_keys = [];
            if isfile(fail_keys_name)
                load(fail_keys_name);
            end
            if ~isempty(fail_keys)
                N_fail_keys = length(fail_keys);
                fprintf(fid,'Skipping %d error entries.\n',N_fail_keys);                
                restriction = ',obj.keySource-fail_keys';
            end
        end
        if unpop_count > 0
            if parallel
                fprintf(fid,'Running parpopulate so no error tracking.\n');
                eval(sprintf('parpopulate(%s%s);',computed_classes{i},restriction));
                %error tracking does not work with parpopulate
                %but it does not stop on exceptions
            else
                tstart = tic;
                eval(sprintf('[fail_keys, errs] = populate(%s%s);',computed_classes{i},restriction));
                elapsed = toc(tstart);                
                N_err = length(fail_keys);
                if N_err > 0
                    save([getenv('SERVER_ROOT'), filesep, ...
                        'DJ_computed_logs', filesep, ...
                        'error_keys', filesep, ...
                        computed_classes{i}, '.mat'], 'fail_keys');
                    save([getenv('SERVER_ROOT'), filesep, ...
                        'DJ_computed_logs', filesep, ...
                        'exceptions', filesep, ...
                        computed_classes{i}, '.mat'], 'errs');
                    error_table = table('Size',[N_err,4],...
                        'VariableTypes',{'string','string','uint32','string'}, ...
                        'VariableNames',{'cell_name','dataset','DJID','experimenter'});
                    for f=1:length(fail_keys)
                        error_exp = sln_symphony.ExperimentSource * ...
                            proj(sln_symphony.ExperimentRetina,'source_id->retina_id','*') * ...
                            sln_symphony.ExperimentCell & fail_keys(f);
                        if error_exp.exists
                            sln_symphony.Experiment * sln_symphony.ExperimentSource * sln_symphony.ExperimentRetina & rmfield(fail_keys(f),'source_id');
                            error_table.DJID(f) = fetch1(error_exp,'animal_id');
                            error_table.experimenter(f) = fetch1(error_exp,'experimenter');
                        end
                        if isfield(fail_keys(f),'dataset_name')
                            error_table.dataset(f) = fail_keys(f).dataset_name;
                        elseif isfield(fail_keys(f),'epoch_id')
                            error_table.dataset(f) = sprintf('epoch_%d',fail_keys(f).epoch_id);
                        end
                        error_table.cell_name(f) = fetch1(sln_cell.CellName & fail_keys(f),'cell_name');
                    end

                    error_table_dir = [getenv('SERVER_ROOT'), filesep, ...
                        'DJ_computed_logs', filesep, ...
                        'error_tables', filesep];
                    error_table_name = sprintf('%s%s.xls',error_table_dir,strrep(computed_classes{i},'.','_'));
                    writetable(error_table,error_table_name);
                end
                fprintf(fid,'%d entries added. %d errors logged.\n',unpop_count-N_err-N_fail_keys,N_err);
                fprintf(fid,'Elapsed time = %f seconds (%f seconds per entry).\n',...
                    elapsed,elapsed./unpop_count);
            end

            fprintf(fid,'\n');
        end
    end

    fprintf(fid,'\n');
    
end

fclose(fid);