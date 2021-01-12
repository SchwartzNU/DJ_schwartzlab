function [] = getStoredResult(level, key, my_db_only)

if my_db_only
    C = dj.conn;
    user_dbs = {sprintf('sl_%s', lower(C.user))};
else
    user_dbs = fetchn(sl.UserDB,'db_name');
end
N = length(user_dbs);

switch level
    case 'Epoch'
        
        
    case 'Dataset'
    case 'Cell'
    case 'Multi-cell'
end