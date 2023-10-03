function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sln_symphony', 'sln_symphony');
end
obj = schemaObject;
end
