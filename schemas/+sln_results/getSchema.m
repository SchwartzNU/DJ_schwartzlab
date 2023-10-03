function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_results', 'sln_results');
end
obj = schemaObject;
end
