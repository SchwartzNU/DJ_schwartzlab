classdef CustomTable < dj.internal.GeneralRelvar
    %A MATLAB class that assembles tables using raw SQL to do things that
    %datajoint cannot

    properties(SetAccess=private)
        tableHeader
        fullTableName
        schema = sln_custom.getSchema()
    end

    methods
        function self = CustomTable(t1)
            self.tableHeader = dj.internal.Header.initFromAttributes(t1.header.attributes, 'CustomTable', 'CustomTable');
            self.fullTableName = sprintf('%s', t1.sql);
            self.init('table', {self});
        end

    end
end