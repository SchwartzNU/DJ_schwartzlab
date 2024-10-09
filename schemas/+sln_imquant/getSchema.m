function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_imquant', 'sln_imquant');
end
obj = schemaObject;
end
