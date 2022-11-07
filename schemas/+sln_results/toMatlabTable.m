function T = toMatlabTable(resultTable)
var_names = resultTable.header.names();

N_vars = length(var_names);
var_comments = cell(N_vars,1);
for i=1:N_vars
    var_comments{i} = resultTable.header.attributes(i).sqlComment;
end
S = fetch(resultTable,'*');
if length(S)==1
    T = struct2table(S,'AsArray',true);
else
    T = struct2table(S);
end
T.Properties.VariableDescriptions = var_comments;