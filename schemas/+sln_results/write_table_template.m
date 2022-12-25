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
    T.Type(i) = class(R.(R.Properties.VariableNames{i}));
    if strcmp(R.Properties.VariableNames{i}, 'git_tag') || strcmp(R.Properties.VariableNames{i}, 'user_name')
        keep_rows(i) = false;
    end
end
T = T(keep_rows,:);
writetable(T,[getenv('DJ_ROOT') filesep 'result_table_templates' filesep template_name '.xlsx']);


