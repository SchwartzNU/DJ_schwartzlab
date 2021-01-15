function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_david', 'sl_david');
end
obj = schemaObject;
end
