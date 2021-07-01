function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_shared', 'sl_shared');
end
obj = schemaObject;
end
