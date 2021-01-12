function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_greg', 'sl_greg');
end
obj = schemaObject;
end
