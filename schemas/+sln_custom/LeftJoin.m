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

            joinSql = sprintf('%s AS t1 LEFT JOIN %s AS t2 USING (%s)', ...
                table1.sql, table2.sql, ...
                matchColumn)
            self.fullTableName = joinSql;
            self.schema = sln_custom.getSchema();
            %self.fullTableName = sprintf('(%s) AS %s', joinSql, 'LeftTable');
            self.init('table', {self});
        end
    end
end