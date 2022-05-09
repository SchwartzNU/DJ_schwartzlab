function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_jacob', 'sl_jacob');
end
obj = schemaObject;
end
