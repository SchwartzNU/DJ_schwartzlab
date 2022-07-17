function insert(R,resultLevel,replace)
if nargin < 3
    replace = false;
end

%check git status
cur_dir = pwd;
cd(getenv('DJ_ROOT'));


cd(cur_dir);

table_name = sprintf('%s%s',resultLevel,strrep(R.Properties.UserData,'_',''));
tableStruct = table2struct(R);
N = length(tableStruct);
C = dj.conn;
cur_user = C.user;
for i=1:N
    tableStruct(i).user_name = cur_user;
end

if replace
    insert(eval(sprintf('sln_results.%s',table_name)), tableStruct,'REPLACE');
else
    insert(eval(sprintf('sln_results.%s',table_name)), tableStruct);
end
