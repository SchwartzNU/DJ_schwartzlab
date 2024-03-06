function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_funcimage', 'sln_funcimage');
end
obj = schemaObject;
end
