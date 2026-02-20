function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_custom', 'sl');
end
obj = schemaObject;
end
