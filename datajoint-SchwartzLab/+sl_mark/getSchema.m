function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn, 'sl_mark', 'sl_mark');
end
obj = schemaObject;
end
