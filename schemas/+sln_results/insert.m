function insert(R,resultLevel)
table_name = sprintf('%s%s',resultLevel,strrep(R.Properties.UserData,'_',''))
insert(eval(sprintf('sln_results.%s',table_name)), table2struct(R))
