function [] = write_table_template(R, template_name)

N_vars = length(R.Properties.VariableNames);
keep_rows = true(N_vars,1);
T = table('size',[N_vars 3],...
    'VariableTypes', ...
    {'string', 'string', 'string'}, ...
    'VariableNames',...
    {'Field','Type','Description'});
T.Field = R.Properties.VariableNames';
T.Description = R.Properties.VariableDescriptions';
for i=1:length(R.Properties.VariableNames)
    cur_var = R.Properties.VariableNames{i};
    cur_class = class(R.(cur_var));
    if strcmp(cur_class,'char')
        T.Type(i) = 'string';
    else
         T.Type(i) = cur_class;
    end
    if strcmp(cur_var, 'git_tag') || strcmp(cur_var, 'user_name') || strcmp(cur_var, 'entry_time')
        keep_rows(i) = false;
    end
end
T = T(keep_rows,:);
writetable(T,[getenv('DJ_ROOT') filesep 'result_table_templates' filesep template_name '.xlsx']);


