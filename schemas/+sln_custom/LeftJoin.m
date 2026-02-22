classdef LeftJoin < dj.internal.GeneralRelvar
    %A MATLAB class that assembles tables using raw SQL to do things that
    %datajoint cannot

    properties(SetAccess=private)
        tableHeader
        fullTableName
        schema = sln_custom.getSchema()
    end

    methods
        function self = LeftJoin(table1, table2, columnName, matchColumn)
            attr1 = table1.header.attributes;
            ind = find(strcmp({table2.header.attributes.name}, columnName));
            attr = vertcat(attr1,table2.header.attributes(ind));
            self.tableHeader = dj.internal.Header.initFromAttributes(attr, 'LeftJoin', 'LeftJoin');

            if length(matchColumn)==1
                joinSql = sprintf('%s LEFT JOIN %s USING (%s)', ...
                    table1.sql, table2.sql, ...
                    matchColumn{1});
            else
                joinSql = sprintf('%s LEFT JOIN %s USING (%s)', ...
                    table1.sql, table2.sql, ...
                    strjoin(matchColumn,','));
            end
            self.fullTableName = joinSql;
            self.schema = sln_custom.getSchema();
            self.init('table', {self});
        end
    end
end