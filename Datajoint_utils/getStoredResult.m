function queryResult = getStoredResult(level, key, my_db_only)
if nargin<3
    my_db_only = false;
end
C = dj.conn;

if my_db_only    
    %get only this user's db
    user_dbs = {sprintf('sl_%s', lower(C.user))};
    N = length(user_dbs);
else
    %get all user dbs
    user_dbs = fetchn(sl.UserDB,'db_name');
    N = length(user_dbs);
    %put this user's db first
    my_db_ind = find(strcmp(user_dbs, sprintf('sl_%s', lower(C.user))));
    user_dbs = user_dbs([my_db_ind, setdiff(1:N, my_db_ind)]);
end

switch level
    case 'Epoch'
        for i=1:N
            db = user_dbs{i};
            eval(sprintf('q=%s.EpochResult & key;', db))
            if q.exists %grab first matching result                
                queryResult = q; 
                return;
            end
        end        
        
    case 'Dataset'
         for i=1:N
            db = user_dbs{i};
            eval(sprintf('q=%s.DatasetResult & key;', db))
            if q.exists %grab first matching result                
                queryResult = q; 
                return;
            end
        end
        
    case 'Cell'
         for i=1:N
            db = user_dbs{i};
            eval(sprintf('q=%s.CellResult & key;', db))
            if q.exists %grab first matching result                
                queryResult = q; 
                return;
            end
        end
        
    case 'Multi-cell'
         for i=1:N
            db = user_dbs{i};
            eval(sprintf('q=%s.Result & key;', db))
            if q.exists %grab first matching result                
                queryResult = q; 
                return;
            end
        end
        
end

%TODO - match epoch params

disp('Stored result not found');
queryResult = q; %will be an empty one
