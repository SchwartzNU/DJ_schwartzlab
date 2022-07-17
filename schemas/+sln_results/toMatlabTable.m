function T = toMatlabTable(resultTable)
var_names = resultTable.header.names();

N_vars = length(var_names);
var_comments = cell(N_vars,1);
for i=1:N_vars
    var_comments{i} = resultTable.header.attributes(i).sqlComment;
end
S = fetch(resultTable,'*');
T = struct2table(S);
T.Properties.VariableDescriptions = var_comments;