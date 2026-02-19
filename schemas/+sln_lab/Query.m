%{
#Queries for particular projects / users
query_name                   : varchar(128)   # unique name
-> sln_lab.User
---
-> [nullable] sln_lab.Project
sql_query : varchar(60000)
%}

classdef Query < dj.Manual
    methods
        function result = runAndFetch(query)
            q_str = fetch1(query, 'sql_query');
            q_str = sprintf('SELECT * from %s', q_str);
            C = dj.conn;
            result = C.query(q_str);            
        end

        function result = runAndFetchAnalysisResult(query, resultName)
            q_str = fetch1(query, 'sql_query');
            q_str = strrep(q_str,',`user_name`',''); %conflicts with result fields
            q_str = strrep(q_str,',`entry_time`',''); %conflicts with result fields    
            result_table = eval(sprintf('sln_results.%s',resultName));
            result_table_name = result_table.sql;
            q_str = sprintf('SELECT * from %s NATURAL JOIN %s', result_table_name, q_str);
            C = dj.conn;
            result = C.query(q_str);    
        end

    end
end