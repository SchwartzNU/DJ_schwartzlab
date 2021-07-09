function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_behavior', 'sl_behavior');
end
obj = schemaObject;
end
