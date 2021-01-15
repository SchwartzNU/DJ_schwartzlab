function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_mutable', 'sl_mutable');
end
obj = schemaObject;
end
