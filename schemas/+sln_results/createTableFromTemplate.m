function [] = createTableFromTemplate(template_name,resultLevel)
R = sln_results.table_definition_from_template(template_name, 1);
sln_results.createTable(R,resultLevel);  