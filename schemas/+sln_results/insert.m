function insert(R,resultLevel,replace)
if nargin < 3
    replace = false;
end

C = dj.conn;
cur_user = C.user;

%check git status
cur_dir = pwd;
cd(getenv('DJ_ROOT'));
try
    [~, msg] = system('git status --porcelain');
    if ~isempty(msg)
        error('You have locally modified files in %s. Please commit them first.', getenv('DJ_ROOT'));
    end
    tag_name = sprintf('%s_%s', cur_user, datestr(datetime('now'), 'yyyy-mmmm-dd-HH-MM-SS'));
    sprintf('git tag %s', tag_name)
    system(sprintf('git tag %s', tag_name));
catch ME
    cd(cur_dir);
    rethrow(ME);
end

cd(cur_dir);

table_name = sprintf('%s%s',resultLevel,strrep(R.Properties.UserData,'_',''));
tableStruct = table2struct(R);
N = length(tableStruct)
for i=1:N
    tableStruct(i).user_name = cur_user;
    tableStruct(i).git_tag = tag_name;
end

if replace
    insert(eval(sprintf('sln_results.%s',table_name)), tableStruct,'REPLACE');
else
    insert(eval(sprintf('sln_results.%s',table_name)), tableStruct);
end
