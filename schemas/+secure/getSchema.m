function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'secure', 'secure');
end
obj = schemaObject;
end
