function [] = createTableFromTemplate(template_name,resultLevel)
%the tamplate the is file name of the result table without extension?
R = sln_results.table_definition_from_template(template_name, 1);
sln_results.createTable(R,resultLevel);  