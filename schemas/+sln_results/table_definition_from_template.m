function T = table_definition_from_template(template_name, Nrows)
excel_table = readtable([getenv('DJ_ROOT') filesep 'result_table_templates' filesep template_name]);

T = table('size', [Nrows, height(excel_table)],...
    'VariableTypes',excel_table.Type,...
    'VariableNames',excel_table.Field);

T.Properties.VariableDescriptions = excel_table.Description;
T.Properties.UserData = template_name;

