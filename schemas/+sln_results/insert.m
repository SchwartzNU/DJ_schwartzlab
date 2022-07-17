function insert(R,resultLevel,replace)
if nargin < 3
    replace = false;
end

table_name = sprintf('%s%s',resultLevel,strrep(R.Properties.UserData,'_',''));
tableStruct = table2struct(R);
if replace
    insert(eval(sprintf('sln_results.%s',table_name)), tableStruct,'REPLACE');
else
    insert(eval(sprintf('sln_results.%s',table_name)), tableStruct);
end
