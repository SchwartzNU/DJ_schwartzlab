function [data_levels, param_table_names] = get_all_user_param_in_db


c = dj.conn;
user_params = c.query('SELECT TABLE_NAME FROM information_schema.tables WHERE TABLE_SCHEMA = "sln_symphony" AND TABLE_NAME LIKE "user%"' );

exp = 'user_param_([a-zA-Z]+)_(\w+)';


data_levels_table_names = arrayfun(@(x) regexp(x, exp, 'tokens'), user_params.TABLE_NAME);
data_levels = arrayfun(@(x) [upper(x{1}{1}{1}(1)), x{1}{1}{1}(2:end)], data_levels_table_names, 'UniformOutput', false);


param_table_names = cell(length(data_levels), 1);
for i = 1:length(data_levels)
    tbl_name = data_levels_table_names{i}{1}{2};
    expression = '(_|^)+[a-z]';
    replace = '${upper($0)}';
    newStr = regexprep(tbl_name,expression,replace);
    param_table_names{i} = strrep(newStr, '_', '');
end

end