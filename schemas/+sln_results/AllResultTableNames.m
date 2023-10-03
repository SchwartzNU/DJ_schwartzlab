function list = AllResultTableNames()
schema = sln_results.getSchema; 
classNames = schema.classNames;

N = length(classNames);
list = {};
for i=1:N
    cur_name = extractAfter(classNames{i},'sln_results.');
    if startsWith(cur_name,'Dataset') || startsWith(cur_name,'Epoch') || startsWith(cur_name,'Cell') || startsWith(cur_name,'Animal') || startsWith(cur_name,'Experiment')
        list = [list; cur_name];
    end

end