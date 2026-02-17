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
    end
end