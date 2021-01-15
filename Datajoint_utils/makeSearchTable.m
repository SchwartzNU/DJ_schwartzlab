function searchTable = makeSearchTable(currentTables, user_db)
if nargin<2
    user_db = [];
end

commandStr = 'searchTable=';
N = length(currentTables);
for i=1:N
    if strcmp(currentTables{i}, 'CurrentCellType')
        commandStr = [commandStr, 'sl_mutable.' currentTables{i} '*'];
    elseif ~isempty(user_db) && contains(currentTables{i}, 'Result')
        commandStr = [commandStr, 'sl_' user_db '.' currentTables{i} '*'];
    else
        commandStr = [commandStr, 'sl.' currentTables{i} '*'];
    end
end
%remove trailing *
commandStr = [commandStr(1:end-1) ,';'];
eval(commandStr);